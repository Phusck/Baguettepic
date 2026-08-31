using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Baguettepic.Models;
using Microsoft.Data.Sqlite;

namespace Baguettepic.Services;

public sealed class CatalogCacheService
{
    public static CatalogCacheService Instance { get; } = new();

    static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    readonly SemaphoreSlim _dbLock = new(1, 1);
    readonly SemaphoreSlim _rulesSyncLock = new(1, 1);
    string? _dbPath;
    bool _initialized;
    Task? _rulesWarmup;

    string DbPath => _dbPath ??= Path.Combine(FileSystem.AppDataDirectory, "catalog-cache.db");

    string BaseImageDirectory =>
        Path.Combine(FileSystem.CacheDirectory, "catalog", "bases");

    public void StartWarmup() =>
        _rulesWarmup ??= Task.Run(() => RefreshRulesAsync(CancellationToken.None));

    public async Task<IReadOnlyList<RuleListItem>> SearchRulesByNameAsync(
        string? query,
        CancellationToken cancellationToken = default)
    {
        await EnsureInitializedAsync(cancellationToken);
        var term = (query ?? string.Empty).Trim();

        if (term.Length == 0)
            return await GetAllRuleNamesAsync(cancellationToken);

        var results = await SearchLocalRulesByNameAsync(term, cancellationToken);
        var allNames = await GetAllRuleNamesAsync(cancellationToken);
        AddParameterizedNameMatches(results, term, allNames);

        _ = RefreshRulesAsync(cancellationToken);
        return results;
    }

    public async Task<IReadOnlyList<RuleListItem>> SearchRulesByDescriptionAsync(
        string query,
        IReadOnlyList<RuleListItem> nameMatches,
        CancellationToken cancellationToken = default)
    {
        await EnsureInitializedAsync(cancellationToken);
        var term = query.Trim();
        if (term.Length == 0)
            return [];

        var exclude = new HashSet<(int Id, string Kind)>(
            nameMatches.Select(rule => (rule.Id, rule.Kind)));

        var results = await SearchLocalRulesByDescriptionAsync(term, cancellationToken);
        _ = RefreshRulesAsync(cancellationToken);
        return results.Where(rule => !exclude.Contains((rule.Id, rule.Kind))).ToList();
    }

    public async Task<RuleListItem?> GetRuleAsync(
        int id,
        string kind,
        Action<RuleListItem>? onUpdated = null,
        CancellationToken cancellationToken = default)
    {
        await EnsureInitializedAsync(cancellationToken);
        var cached = await TryGetLocalRuleAsync(id, kind, cancellationToken);
        if (cached is not null)
        {
            _ = RefreshRuleAsync(id, kind, cached, onUpdated, cancellationToken);
            return cached;
        }

        var remote = await DatabaseService.Instance.GetRuleAsync(id, kind, cancellationToken);
        if (remote is not null)
            await UpsertLocalRuleAsync(remote, cancellationToken);

        return remote;
    }

    public async Task<IReadOnlyList<RuleListItem>> GetAllRuleNamesAsync(
        CancellationToken cancellationToken = default)
    {
        await EnsureInitializedAsync(cancellationToken);
        var local = await ReadAllLocalRuleSummariesAsync(cancellationToken);
        if (local.Count > 0)
        {
            _ = RefreshRulesAsync(cancellationToken);
            return local;
        }

        await RefreshRulesAsync(cancellationToken);
        return await ReadAllLocalRuleSummariesAsync(cancellationToken);
    }

    public async Task<BaseProfile?> LoadBaseProfileAsync(
        int baseId,
        string? detachmentName,
        int armyId,
        int formationId,
        int? titanIndex,
        Action<BaseProfile>? onUpdated,
        CancellationToken cancellationToken = default)
    {
        await EnsureInitializedAsync(cancellationToken);

        var cachedCore = await TryGetCachedBaseCoreAsync(baseId, cancellationToken);
        BaseProfile? profile;
        if (cachedCore is not null)
        {
            var imageBytes = await TryReadBaseImageAsync(baseId, cancellationToken);
            profile = await MergeBaseProfileAsync(
                cachedCore,
                detachmentName,
                armyId,
                formationId,
                titanIndex,
                imageBytes,
                cancellationToken);
            _ = RefreshBaseProfileAsync(baseId, detachmentName, armyId, formationId, titanIndex, profile, onUpdated, cancellationToken);
            if (imageBytes is null)
                _ = LoadBaseImageInBackgroundAsync(baseId, detachmentName, armyId, formationId, titanIndex, profile, onUpdated, cancellationToken);
            return profile;
        }

        profile = await FetchAndCacheBaseProfileAsync(
            baseId,
            detachmentName,
            armyId,
            formationId,
            titanIndex,
            cancellationToken);
        return profile;
    }

    public async Task UpsertRuleAsync(RuleListItem rule, CancellationToken cancellationToken = default)
    {
        await EnsureInitializedAsync(cancellationToken);
        await UpsertLocalRuleAsync(rule, cancellationToken);
    }

    public async Task RefreshRulesAsync(CancellationToken cancellationToken = default)
    {
        if (!await _rulesSyncLock.WaitAsync(0, cancellationToken))
            return;

        try
        {
            var remoteRules = await DatabaseService.Instance.FetchAllRulesWithDescriptionsAsync(cancellationToken);
            await EnsureInitializedAsync(cancellationToken);

            await _dbLock.WaitAsync(cancellationToken);
            try
            {
                await using var conn = OpenConnection();
                await using var tx = await conn.BeginTransactionAsync(cancellationToken);
                foreach (var rule in remoteRules)
                {
                    var hash = HashText($"{rule.Kind}|{rule.Name}|{rule.Description}");
                    await using var cmd = conn.CreateCommand();
                    cmd.Transaction = (SqliteTransaction)tx;
                    cmd.CommandText = """
                        INSERT INTO RuleEntry (Id, Kind, Name, Description, ContentHash)
                        VALUES (@id, @kind, @name, @description, @hash)
                        ON CONFLICT(Id, Kind) DO UPDATE SET
                            Name = excluded.Name,
                            Description = excluded.Description,
                            ContentHash = excluded.ContentHash
                        WHERE excluded.ContentHash <> RuleEntry.ContentHash
                        """;
                    cmd.Parameters.AddWithValue("@id", rule.Id);
                    cmd.Parameters.AddWithValue("@kind", rule.Kind);
                    cmd.Parameters.AddWithValue("@name", rule.Name);
                    cmd.Parameters.AddWithValue("@description", rule.Description);
                    cmd.Parameters.AddWithValue("@hash", hash);
                    await cmd.ExecuteNonQueryAsync(cancellationToken);
                }

                await using (var meta = conn.CreateCommand())
                {
                    meta.Transaction = (SqliteTransaction)tx;
                    meta.CommandText = """
                        INSERT INTO CatalogMeta (Key, Value)
                        VALUES ('RulesSyncedAt', @value)
                        ON CONFLICT(Key) DO UPDATE SET Value = excluded.Value
                        """;
                    meta.Parameters.AddWithValue("@value", DateTimeOffset.UtcNow.ToString("O"));
                    await meta.ExecuteNonQueryAsync(cancellationToken);
                }

                await tx.CommitAsync(cancellationToken);
            }
            finally
            {
                _dbLock.Release();
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            _rulesSyncLock.Release();
        }
    }

    async Task EnsureInitializedAsync(CancellationToken cancellationToken)
    {
        if (_initialized)
            return;

        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            if (_initialized)
                return;

            Directory.CreateDirectory(BaseImageDirectory);
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                CREATE TABLE IF NOT EXISTS RuleEntry (
                    Id INTEGER NOT NULL,
                    Kind TEXT NOT NULL,
                    Name TEXT NOT NULL,
                    Description TEXT NOT NULL,
                    ContentHash TEXT NOT NULL,
                    PRIMARY KEY (Id, Kind)
                );

                CREATE TABLE IF NOT EXISTS CatalogMeta (
                    Key TEXT PRIMARY KEY,
                    Value TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS BaseProfileEntry (
                    BaseId INTEGER PRIMARY KEY,
                    ProfileJson TEXT NOT NULL,
                    ContentHash TEXT NOT NULL,
                    ImageHash TEXT
                );

                CREATE INDEX IF NOT EXISTS IX_RuleEntry_Name ON RuleEntry(Name);
                """;
            await cmd.ExecuteNonQueryAsync(cancellationToken);
            _initialized = true;
        }
        finally
        {
            _dbLock.Release();
        }
    }

    async Task RefreshRuleAsync(
        int id,
        string kind,
        RuleListItem cached,
        Action<RuleListItem>? onUpdated,
        CancellationToken cancellationToken)
    {
        try
        {
            var remote = await DatabaseService.Instance.GetRuleAsync(id, kind, cancellationToken);
            if (remote is null)
                return;

            var hash = HashText($"{remote.Kind}|{remote.Name}|{remote.Description}");
            var cachedHash = HashText($"{cached.Kind}|{cached.Name}|{cached.Description}");
            if (hash == cachedHash)
                return;

            await UpsertLocalRuleAsync(remote, cancellationToken);
            if (onUpdated is not null)
                await MainThread.InvokeOnMainThreadAsync(() => onUpdated(remote));
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task RefreshBaseProfileAsync(
        int baseId,
        string? detachmentName,
        int armyId,
        int formationId,
        int? titanIndex,
        BaseProfile current,
        Action<BaseProfile>? onUpdated,
        CancellationToken cancellationToken)
    {
        try
        {
            var remote = await FetchAndCacheBaseProfileAsync(
                baseId,
                detachmentName,
                armyId,
                formationId,
                titanIndex,
                cancellationToken);
            if (remote is null || ProfilesEquivalent(current, remote))
                return;

            if (onUpdated is not null)
                await MainThread.InvokeOnMainThreadAsync(() => onUpdated(remote));
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task<BaseProfile?> FetchAndCacheBaseProfileAsync(
        int baseId,
        string? detachmentName,
        int armyId,
        int formationId,
        int? titanIndex,
        CancellationToken cancellationToken)
    {
        var remote = await DatabaseService.Instance.GetBaseProfileAsync(
            baseId,
            detachmentName,
            armyId,
            formationId,
            titanIndex,
            includeImage: false,
            cancellationToken: cancellationToken);

        if (remote is null)
            return null;

        await CacheBaseCoreAsync(remote, cancellationToken);

        var imageBytes = await DatabaseService.Instance.GetBaseImageBytesAsync(baseId, cancellationToken);
        if (imageBytes is { Length: > 0 })
            await WriteBaseImageAsync(baseId, imageBytes, cancellationToken);

        return WithImage(remote, imageBytes);
    }

    static BaseProfile WithImage(BaseProfile profile, byte[]? imageBytes) => new()
    {
        Id = profile.Id,
        Name = profile.Name,
        ImageBytes = imageBytes,
        Movement = profile.Movement,
        Save = profile.Save,
        FA = profile.FA,
        Morale = profile.Morale,
        Class = profile.Class,
        DestructionPoints = profile.DestructionPoints,
        Abilities = profile.Abilities,
        PsychicPowers = profile.PsychicPowers,
        Weapons = profile.Weapons,
        ChosenTitanWeapons = profile.ChosenTitanWeapons,
        DetachmentName = profile.DetachmentName
    };

    async Task CacheBaseCoreAsync(BaseProfile profile, CancellationToken cancellationToken)
    {
        var dto = CachedBaseProfile.From(profile);
        var json = JsonSerializer.Serialize(dto, JsonOptions);
        var hash = HashText(json);

        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                INSERT INTO BaseProfileEntry (BaseId, ProfileJson, ContentHash, ImageHash)
                VALUES (@id, @json, @hash, COALESCE((SELECT ImageHash FROM BaseProfileEntry WHERE BaseId = @id), ''))
                ON CONFLICT(BaseId) DO UPDATE SET
                    ProfileJson = excluded.ProfileJson,
                    ContentHash = excluded.ContentHash
                WHERE excluded.ContentHash <> BaseProfileEntry.ContentHash
                """;
            cmd.Parameters.AddWithValue("@id", profile.Id);
            cmd.Parameters.AddWithValue("@json", json);
            cmd.Parameters.AddWithValue("@hash", hash);
            await cmd.ExecuteNonQueryAsync(cancellationToken);
        }
        finally
        {
            _dbLock.Release();
        }
    }

    async Task<CachedBaseProfile?> TryGetCachedBaseCoreAsync(int baseId, CancellationToken cancellationToken)
    {
        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = "SELECT ProfileJson FROM BaseProfileEntry WHERE BaseId = @id LIMIT 1";
            cmd.Parameters.AddWithValue("@id", baseId);
            var json = await cmd.ExecuteScalarAsync(cancellationToken) as string;
            return string.IsNullOrEmpty(json)
                ? null
                : JsonSerializer.Deserialize<CachedBaseProfile>(json, JsonOptions);
        }
        finally
        {
            _dbLock.Release();
        }
    }

    async Task<BaseProfile> MergeBaseProfileAsync(
        CachedBaseProfile core,
        string? detachmentName,
        int armyId,
        int formationId,
        int? titanIndex,
        byte[]? imageBytes,
        CancellationToken cancellationToken)
    {
        var chosen = Array.Empty<WeaponProfile>();
        if (armyId > 0 && formationId > 0)
        {
            chosen = (await DatabaseService.Instance.GetChosenTitanWeaponsForBaseAsync(
                core.Id,
                armyId,
                formationId,
                titanIndex,
                cancellationToken)).ToArray();
        }

        return core.ToProfile(imageBytes, chosen, detachmentName);
    }

    async Task<byte[]?> TryReadBaseImageAsync(int baseId, CancellationToken cancellationToken)
    {
        var path = BaseImagePath(baseId);
        if (!File.Exists(path))
            return null;

        return await File.ReadAllBytesAsync(path, cancellationToken);
    }

    async Task LoadBaseImageInBackgroundAsync(
        int baseId,
        string? detachmentName,
        int armyId,
        int formationId,
        int? titanIndex,
        BaseProfile current,
        Action<BaseProfile>? onUpdated,
        CancellationToken cancellationToken)
    {
        try
        {
            var imageBytes = await DatabaseService.Instance.GetBaseImageBytesAsync(baseId, cancellationToken);
            if (imageBytes is not { Length: > 0 })
                return;

            await WriteBaseImageAsync(baseId, imageBytes, cancellationToken);
            if (onUpdated is null || ImageBytesEqual(current.ImageBytes, imageBytes))
                return;

            var updated = WithImage(current, imageBytes);
            await MainThread.InvokeOnMainThreadAsync(() => onUpdated(updated));
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task WriteBaseImageAsync(int baseId, byte[] bytes, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(BaseImageDirectory);
        var path = BaseImagePath(baseId);
        await File.WriteAllBytesAsync(path, bytes, cancellationToken);
        var hash = HashBytes(bytes);

        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = "UPDATE BaseProfileEntry SET ImageHash = @hash WHERE BaseId = @id";
            cmd.Parameters.AddWithValue("@id", baseId);
            cmd.Parameters.AddWithValue("@hash", hash);
            await cmd.ExecuteNonQueryAsync(cancellationToken);
        }
        finally
        {
            _dbLock.Release();
        }
    }

    async Task<List<RuleListItem>> SearchLocalRulesByNameAsync(string term, CancellationToken cancellationToken)
    {
        var like = "%" + EscapeLike(term) + "%";
        var results = new List<RuleListItem>();

        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                SELECT Id, Name, Kind
                FROM RuleEntry
                WHERE Name LIKE @like ESCAPE '\'
                ORDER BY Name
                """;
            cmd.Parameters.AddWithValue("@like", like);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                results.Add(new RuleListItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1),
                    Description = string.Empty,
                    Kind = reader.GetString(2)
                });
            }
        }
        finally
        {
            _dbLock.Release();
        }

        return results;
    }

    async Task<List<RuleListItem>> SearchLocalRulesByDescriptionAsync(string term, CancellationToken cancellationToken)
    {
        var like = "%" + EscapeLike(term) + "%";
        var results = new List<RuleListItem>();

        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                SELECT Id, Name, Kind
                FROM RuleEntry
                WHERE Description LIKE @like ESCAPE '\'
                ORDER BY Name
                """;
            cmd.Parameters.AddWithValue("@like", like);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                results.Add(new RuleListItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1),
                    Description = string.Empty,
                    Kind = reader.GetString(2)
                });
            }
        }
        finally
        {
            _dbLock.Release();
        }

        return results;
    }

    async Task<IReadOnlyList<RuleListItem>> ReadAllLocalRuleSummariesAsync(CancellationToken cancellationToken)
    {
        var results = new List<RuleListItem>();
        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                SELECT Id, Name, Kind
                FROM RuleEntry
                ORDER BY LENGTH(Name) DESC, Name
                """;
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                results.Add(new RuleListItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1),
                    Description = string.Empty,
                    Kind = reader.GetString(2)
                });
            }
        }
        finally
        {
            _dbLock.Release();
        }

        return results;
    }

    async Task<RuleListItem?> TryGetLocalRuleAsync(int id, string kind, CancellationToken cancellationToken)
    {
        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                SELECT Id, Name, Description, Kind
                FROM RuleEntry
                WHERE Id = @id AND Kind = @kind
                LIMIT 1
                """;
            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@kind", kind);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
                return null;

            return new RuleListItem
            {
                Id = reader.GetInt32(0),
                Name = reader.GetString(1),
                Description = reader.GetString(2),
                Kind = reader.GetString(3)
            };
        }
        finally
        {
            _dbLock.Release();
        }
    }

    async Task UpsertLocalRuleAsync(RuleListItem rule, CancellationToken cancellationToken)
    {
        await _dbLock.WaitAsync(cancellationToken);
        try
        {
            await using var conn = OpenConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                INSERT INTO RuleEntry (Id, Kind, Name, Description, ContentHash)
                VALUES (@id, @kind, @name, @description, @hash)
                ON CONFLICT(Id, Kind) DO UPDATE SET
                    Name = excluded.Name,
                    Description = excluded.Description,
                    ContentHash = excluded.ContentHash
                """;
            cmd.Parameters.AddWithValue("@id", rule.Id);
            cmd.Parameters.AddWithValue("@kind", rule.Kind);
            cmd.Parameters.AddWithValue("@name", rule.Name);
            cmd.Parameters.AddWithValue("@description", rule.Description);
            cmd.Parameters.AddWithValue("@hash", HashText($"{rule.Kind}|{rule.Name}|{rule.Description}"));
            await cmd.ExecuteNonQueryAsync(cancellationToken);
        }
        finally
        {
            _dbLock.Release();
        }
    }

    SqliteConnection OpenConnection()
    {
        var conn = new SqliteConnection($"Data Source={DbPath}");
        conn.Open();
        return conn;
    }

    static string BaseImagePath(int baseId) =>
        Path.Combine(Instance.BaseImageDirectory, $"{baseId}.bin");

    static void AddParameterizedNameMatches(
        List<RuleListItem> results,
        string term,
        IReadOnlyList<RuleListItem> names)
    {
        foreach (var name in names)
        {
            if (!ParameterizedName.Matches(name.Name, term))
                continue;
            if (results.Any(rule => rule.Id == name.Id &&
                string.Equals(rule.Kind, name.Kind, StringComparison.OrdinalIgnoreCase)))
                continue;

            results.Insert(0, name);
        }
    }

    static bool ProfilesEquivalent(BaseProfile left, BaseProfile right) =>
        left.Id == right.Id &&
        left.Name == right.Name &&
        left.Movement == right.Movement &&
        left.Save == right.Save &&
        left.FA == right.FA &&
        left.Morale == right.Morale &&
        left.Class == right.Class &&
        left.DestructionPoints == right.DestructionPoints &&
        left.Weapons.Count == right.Weapons.Count &&
        left.Abilities.Count == right.Abilities.Count &&
        left.PsychicPowers.Count == right.PsychicPowers.Count &&
        left.ChosenTitanWeapons.Count == right.ChosenTitanWeapons.Count &&
        ImageBytesEqual(left.ImageBytes, right.ImageBytes);

    static bool ImageBytesEqual(byte[]? left, byte[]? right)
    {
        if (left is null || right is null)
            return left is null && right is null;
        return left.AsSpan().SequenceEqual(right);
    }

    static string EscapeLike(string value) =>
        value.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");

    static string HashText(string value)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(bytes);
    }

    static string HashBytes(byte[] value)
    {
        var bytes = SHA256.HashData(value);
        return Convert.ToHexString(bytes);
    }

    sealed class CachedBaseProfile
    {
        public int Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Movement { get; init; } = string.Empty;
        public string Save { get; init; } = string.Empty;
        public string FA { get; init; } = string.Empty;
        public string Morale { get; init; } = string.Empty;
        public int Class { get; init; }
        public int DestructionPoints { get; init; }
        public List<AbilityLink> Abilities { get; init; } = [];
        public List<AbilityLink> PsychicPowers { get; init; } = [];
        public List<WeaponProfile> Weapons { get; init; } = [];

        public static CachedBaseProfile From(BaseProfile profile) => new()
        {
            Id = profile.Id,
            Name = profile.Name,
            Movement = profile.Movement,
            Save = profile.Save,
            FA = profile.FA,
            Morale = profile.Morale,
            Class = profile.Class,
            DestructionPoints = profile.DestructionPoints,
            Abilities = profile.Abilities.ToList(),
            PsychicPowers = profile.PsychicPowers.ToList(),
            Weapons = profile.Weapons.ToList()
        };

        public BaseProfile ToProfile(
            byte[]? imageBytes,
            IReadOnlyList<WeaponProfile> chosenTitanWeapons,
            string? detachmentName) => new()
        {
            Id = Id,
            Name = Name,
            ImageBytes = imageBytes,
            Movement = Movement,
            Save = Save,
            FA = FA,
            Morale = Morale,
            Class = Class,
            DestructionPoints = DestructionPoints,
            Abilities = Abilities,
            PsychicPowers = PsychicPowers,
            Weapons = Weapons,
            ChosenTitanWeapons = chosenTitanWeapons,
            DetachmentName = string.IsNullOrWhiteSpace(detachmentName) ? null : detachmentName
        };
    }
}
