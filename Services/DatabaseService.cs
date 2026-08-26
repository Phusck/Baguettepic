using System.Text.Json;
using Baguettepic.Models;
using MySqlConnector;

namespace Baguettepic.Services;

public sealed class DatabaseService
{
    public static DatabaseService Instance { get; } = new();

    static readonly (string Host, uint Port)[] Endpoints =
    [
        ("10.0.0.22", 3306),
        ("87.57.158.180", 37202)
    ];

    static readonly JsonSerializerOptions TitanWeaponJson = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true
    };

    IReadOnlyList<RuleListItem>? _ruleNamesCache;

    public async Task<IReadOnlyList<RuleListItem>> SearchRulesAsync(string? query, CancellationToken cancellationToken = default)
    {
        var term = (query ?? string.Empty).Trim();
        var like = "%" + EscapeLike(term) + "%";

        var results = new List<RuleListItem>();
        await using (var conn = await OpenAsync(cancellationToken))
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT Id, Name, Description, Kind FROM (
                    SELECT SpecialAbilityId AS Id, SpecialAbilityName AS Name, Description, 'Ability' AS Kind
                    FROM SpecialAbility
                    UNION ALL
                    SELECT RuleId, RuleName, Description, 'Rule'
                    FROM Rule
                    UNION ALL
                    SELECT SpecialRuleId, SpecialRuleName, Description, 'Special Rule'
                    FROM SpecialRule
                ) AS Rules
                WHERE @empty = 1
                   OR Name LIKE @like ESCAPE '\\'
                   OR Description LIKE @like ESCAPE '\\'
                ORDER BY
                    CASE
                        WHEN @empty = 1 THEN 0
                        WHEN Name LIKE @like ESCAPE '\\' THEN 0
                        ELSE 1
                    END,
                    Name
                """;
            cmd.Parameters.AddWithValue("@empty", term.Length == 0 ? 1 : 0);
            cmd.Parameters.AddWithValue("@like", like);

            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
                results.Add(ReadRule(reader));
        }

        if (term.Length > 0)
            await AddParameterizedMatchesAsync(results, term, cancellationToken);

        return results;
    }

    public async Task<RuleListItem?> GetRuleAsync(int id, string kind, CancellationToken cancellationToken = default)
    {
        var (table, idColumn, nameColumn) = TableForKind(kind);
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = $"SELECT `{idColumn}` AS Id, `{nameColumn}` AS Name, Description FROM `{table}` WHERE `{idColumn}` = @id LIMIT 1";
        cmd.Parameters.AddWithValue("@id", id);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
            return null;

        return new RuleListItem
        {
            Id = reader.GetInt32("Id"),
            Name = reader.GetString("Name"),
            Description = reader.GetString("Description"),
            Kind = kind
        };
    }

    public async Task<IReadOnlyList<RuleListItem>> GetAllRuleNamesAsync(CancellationToken cancellationToken = default)
    {
        if (_ruleNamesCache is not null)
            return _ruleNamesCache;

        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT Id, Name, Kind FROM (
                SELECT SpecialAbilityId AS Id, SpecialAbilityName AS Name, 'Ability' AS Kind
                FROM SpecialAbility
                UNION ALL
                SELECT RuleId, RuleName, 'Rule'
                FROM Rule
                UNION ALL
                SELECT SpecialRuleId, SpecialRuleName, 'Special Rule'
                FROM SpecialRule
            ) AS Rules
            ORDER BY CHAR_LENGTH(Name) DESC, Name
            """;

        var results = new List<RuleListItem>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(new RuleListItem
            {
                Id = reader.GetInt32("Id"),
                Name = reader.GetString("Name"),
                Description = string.Empty,
                Kind = reader.GetString("Kind")
            });
        }

        _ruleNamesCache = results;
        return results;
    }

    public async Task UpdateRuleAsync(int id, string kind, string name, string description, CancellationToken cancellationToken = default)
    {
        var (table, idColumn, nameColumn) = TableForKind(kind);
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = $"UPDATE `{table}` SET `{nameColumn}` = @name, Description = @description WHERE `{idColumn}` = @id";
        cmd.Parameters.AddWithValue("@id", id);
        cmd.Parameters.AddWithValue("@name", name);
        cmd.Parameters.AddWithValue("@description", description);
        var updated = await cmd.ExecuteNonQueryAsync(cancellationToken);
        if (updated == 0)
            throw new InvalidOperationException("The rule could not be updated.");
        _ruleNamesCache = null;
    }

    public async Task<int> CreateRuleAsync(string name, string description, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = "INSERT INTO Rule (RuleName, Description) VALUES (@name, @description)";
        cmd.Parameters.AddWithValue("@name", name);
        cmd.Parameters.AddWithValue("@description", description);
        await cmd.ExecuteNonQueryAsync(cancellationToken);
        _ruleNamesCache = null;
        return (int)cmd.LastInsertedId;
    }

    public async Task<SessionUser?> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAdminAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT UserId, Username, PasswordHash, IsAdmin, MustChangePassword
            FROM AppUser
            WHERE Username = @username
            LIMIT 1
            """;
        cmd.Parameters.AddWithValue("@username", username);

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
            return null;
        if (!PasswordHasher.Verify(password, reader.GetString("PasswordHash")))
            return null;

        return new SessionUser
        {
            Id = reader.GetInt32("UserId"),
            Username = reader.GetString("Username"),
            IsAdmin = reader.GetBoolean("IsAdmin"),
            MustChangePassword = reader.GetBoolean("MustChangePassword")
        };
    }

    public async Task CreateUserAsync(string username, CancellationToken cancellationToken = default)
    {
        if (!SessionService.Instance.IsAdmin)
            throw new InvalidOperationException("Only an admin can add users.");

        await using var conn = await OpenAdminAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            INSERT INTO AppUser (Username, PasswordHash, IsAdmin, MustChangePassword)
            VALUES (@username, @hash, 0, 1)
            """;
        cmd.Parameters.AddWithValue("@username", username);
        cmd.Parameters.AddWithValue("@hash", PasswordHasher.Hash(SessionService.StandardPassword));
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task ChangePasswordAsync(string newPassword, CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        await using var conn = await OpenAdminAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            UPDATE AppUser
            SET PasswordHash = @hash, MustChangePassword = 0
            WHERE UserId = @id
            """;
        cmd.Parameters.AddWithValue("@id", userId);
        cmd.Parameters.AddWithValue("@hash", PasswordHasher.Hash(newPassword));
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<ArmyListItem>> GetArmiesAsync(CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT a.ArmyId, a.ArmyName, c.CodexName, a.PointsLimit,
                   COALESCE(SUM(af.Quantity * f.PointsCost), 0) AS PointsCost,
                   COALESCE(SUM(CAST(af.Quantity AS SIGNED) * f.CommandPoints), 0) AS CommandPoints,
                   COUNT(af.FormationId) AS EntryCount
            FROM Army a
            JOIN Codex c ON c.CodexId = a.CodexId
            LEFT JOIN ArmyFormation af ON af.ArmyId = a.ArmyId
            LEFT JOIN Formation f ON f.FormationId = af.FormationId
            WHERE a.UserId = @userId
            GROUP BY a.ArmyId, a.ArmyName, c.CodexName, a.PointsLimit
            ORDER BY a.ArmyName
            """;
        cmd.Parameters.AddWithValue("@userId", RequireUserId());

        var extraPoints = await SumTitanWeaponPointsByArmyAsync(conn, cancellationToken);
        var results = new List<ArmyListItem>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(new ArmyListItem
            {
                Id = reader.GetInt32("ArmyId"),
                Name = reader.GetString("ArmyName"),
                CodexName = reader.GetString("CodexName"),
                PointsLimit = reader.GetInt32("PointsLimit"),
                PointsCost = reader.GetInt32("PointsCost") + extraPoints.GetValueOrDefault(reader.GetInt32("ArmyId")),
                CommandPoints = reader.GetInt32("CommandPoints"),
                EntryCount = reader.GetInt32("EntryCount")
            });
        }

        return results;
    }

    public async Task<ArmyDetail?> GetArmyAsync(int armyId, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT a.ArmyId, a.CodexId, a.ArmyName, c.CodexName, a.PointsLimit,
                   f.FormationId, f.FormationName, f.Contents, af.Quantity, f.PointsCost, f.CommandPoints,
                   COALESCE((
                       SELECT MIN(d.Class)
                       FROM FormationDetachment fd
                       JOIN Detachment d ON d.DetachmentId = fd.DetachmentId
                       WHERE fd.FormationId = f.FormationId
                   ), 0) AS Class
            FROM Army a
            JOIN Codex c ON c.CodexId = a.CodexId
            LEFT JOIN ArmyFormation af ON af.ArmyId = a.ArmyId
            LEFT JOIN Formation f ON f.FormationId = af.FormationId
            WHERE a.ArmyId = @id AND a.UserId = @userId
            ORDER BY Class, f.FormationName
            """;
        cmd.Parameters.AddWithValue("@id", armyId);
        cmd.Parameters.AddWithValue("@userId", RequireUserId());

        ArmyDetail? army = null;
        var entries = new List<ArmyEntry>();
        await using (var reader = await cmd.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                army ??= new ArmyDetail
                {
                    Id = reader.GetInt32("ArmyId"),
                    CodexId = reader.GetInt32("CodexId"),
                    Name = reader.GetString("ArmyName"),
                    CodexName = reader.GetString("CodexName"),
                    PointsLimit = reader.GetInt32("PointsLimit"),
                    Entries = entries
                };

                if (reader.IsDBNull(reader.GetOrdinal("FormationName")))
                    continue;

                entries.Add(new ArmyEntry
                {
                    FormationId = reader.GetInt32("FormationId"),
                    FormationName = reader.GetString("FormationName"),
                    Contents = reader.GetString("Contents"),
                    Quantity = reader.GetInt32("Quantity"),
                    PointsCost = reader.GetInt32("PointsCost"),
                    CommandPoints = reader.GetInt32("CommandPoints"),
                    Class = reader.GetInt32("Class"),
                    Titans = []
                });
            }
        }

        if (army is not null)
        {
            if (entries.Count > 0)
                await AttachTitansAsync(conn, army.Id, entries, cancellationToken);
            var specialRules = await LoadCodexSpecialRulesAsync(conn, army.CodexId, cancellationToken);
            army = WithSpecialRules(army, specialRules);
        }

        return army;
    }

    static ArmyDetail WithSpecialRules(ArmyDetail army, IReadOnlyList<AbilityLink> specialRules) => new()
    {
        Id = army.Id,
        CodexId = army.CodexId,
        Name = army.Name,
        CodexName = army.CodexName,
        PointsLimit = army.PointsLimit,
        Entries = army.Entries,
        SpecialRules = specialRules
    };

    static async Task<IReadOnlyList<AbilityLink>> LoadCodexSpecialRulesAsync(
        MySqlConnection conn,
        int codexId,
        CancellationToken cancellationToken)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT SpecialRuleId, SpecialRuleName
            FROM SpecialRule
            WHERE CodexId = @codexId
            ORDER BY SpecialRuleName
            """;
        cmd.Parameters.AddWithValue("@codexId", codexId);

        var results = new List<AbilityLink>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(new AbilityLink
            {
                Id = reader.GetInt32("SpecialRuleId"),
                Name = reader.GetString("SpecialRuleName"),
                Kind = "Special Rule"
            });
        }

        return results;
    }

    public async Task<IReadOnlyList<CodexOption>> GetCodicesAsync(CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT CodexId, CodexName FROM Codex ORDER BY CodexName";

        var results = new List<CodexOption>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(new CodexOption
            {
                Id = reader.GetInt32("CodexId"),
                Name = reader.GetString("CodexName")
            });
        }

        return results;
    }

    public async Task<IReadOnlyList<FormationOption>> GetPurchasableFormationsAsync(int codexId, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT f.FormationId, f.FormationName, k.KindName, f.Contents,
                   f.PointsCost, f.CommandPoints,
                   COALESCE((
                       SELECT MIN(d.Class)
                       FROM FormationDetachment fd
                       JOIN Detachment d ON d.DetachmentId = fd.DetachmentId
                       WHERE fd.FormationId = f.FormationId
                   ), 0) AS Class
            FROM Formation f
            JOIN FormationKind k ON k.FormationKindId = f.FormationKindId
            WHERE f.CodexId = @codexId
              AND EXISTS (
                  SELECT 1 FROM FormationDetachment fd WHERE fd.FormationId = f.FormationId
              )
            ORDER BY CASE k.KindName
                         WHEN 'Synapse' THEN 1
                         WHEN 'Mandatory' THEN 1
                         WHEN 'Company' THEN 2
                         WHEN 'Special' THEN 3
                         WHEN 'Slave' THEN 4
                         WHEN 'Support' THEN 4
                         WHEN 'Option' THEN 5
                         WHEN 'Limited' THEN 6
                         ELSE 9
                     END,
                     Class, f.FormationName
            """;
        cmd.Parameters.AddWithValue("@codexId", codexId);

        var results = new List<FormationOption>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(new FormationOption
            {
                Id = reader.GetInt32("FormationId"),
                Name = reader.GetString("FormationName"),
                KindName = reader.GetString("KindName"),
                Contents = reader.GetString("Contents"),
                PointsCost = reader.GetInt32("PointsCost"),
                CommandPoints = reader.GetInt32("CommandPoints"),
                Class = reader.GetInt32("Class")
            });
        }

        return results;
    }

    public async Task<FormationRoster?> GetFormationRosterAsync(int formationId, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT f.FormationId, f.FormationName,
                   d.DetachmentId, d.DetachmentName, d.CommandPoints, d.Class,
                   b.BaseId, b.BaseName, dc.BaseCount, b.Class AS BaseClass
            FROM Formation f
            LEFT JOIN FormationDetachment fd ON fd.FormationId = f.FormationId
            LEFT JOIN Detachment d ON d.DetachmentId = fd.DetachmentId
            LEFT JOIN DetachmentComposition dc ON dc.DetachmentId = d.DetachmentId
            LEFT JOIN `Base` b ON b.BaseId = dc.BaseId
            WHERE f.FormationId = @id
            ORDER BY d.Class, d.DetachmentName, b.BaseName
            """;
        cmd.Parameters.AddWithValue("@id", formationId);

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        FormationRoster? roster = null;
        var detachments = new List<DetachmentGroup>();
        DetachmentGroup? current = null;
        var bases = new List<DetachmentBaseRow>();

        while (await reader.ReadAsync(cancellationToken))
        {
            roster ??= new FormationRoster
            {
                FormationId = reader.GetInt32("FormationId"),
                FormationName = reader.GetString("FormationName"),
                Detachments = detachments
            };

            if (reader.IsDBNull(reader.GetOrdinal("DetachmentId")))
                continue;

            var detachmentId = reader.GetInt32("DetachmentId");
            if (current is null || current.DetachmentId != detachmentId)
            {
                bases = [];
                current = new DetachmentGroup
                {
                    DetachmentId = detachmentId,
                    DetachmentName = reader.GetString("DetachmentName"),
                    CommandPoints = reader.GetInt32("CommandPoints"),
                    Class = reader.GetInt32("Class"),
                    Bases = bases
                };
                detachments.Add(current);
            }

            if (reader.IsDBNull(reader.GetOrdinal("BaseId")))
                continue;

            bases.Add(new DetachmentBaseRow
            {
                BaseId = reader.GetInt32("BaseId"),
                BaseName = reader.GetString("BaseName"),
                BaseCount = reader.GetInt32("BaseCount"),
                Class = reader.GetInt32("BaseClass"),
                DetachmentName = current.DetachmentName
            });
        }

        return roster;
    }

    public async Task<BaseProfile?> GetBaseProfileAsync(
        int baseId,
        string? detachmentName = null,
        int armyId = 0,
        int formationId = 0,
        int? titanIndex = null,
        CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);

        await using var baseCmd = conn.CreateCommand();
        baseCmd.CommandText = """
            SELECT BaseId, BaseName, Image, DestructionPoints, Morale, `Class`,
                   Movement, `Save`, FA
            FROM `Base`
            WHERE BaseId = @id
            LIMIT 1
            """;
        baseCmd.Parameters.AddWithValue("@id", baseId);

        int id;
        string name;
        byte[]? imageBytes;
        int destructionPoints;
        string morale;
        int @class;
        string movement;
        string save;
        string fa;
        await using (var reader = await baseCmd.ExecuteReaderAsync(cancellationToken))
        {
            if (!await reader.ReadAsync(cancellationToken))
                return null;

            id = reader.GetInt32("BaseId");
            name = reader.GetString("BaseName");
            var imageOrdinal = reader.GetOrdinal("Image");
            imageBytes = reader.IsDBNull(imageOrdinal)
                ? null
                : reader.GetFieldValue<byte[]>(imageOrdinal);
            destructionPoints = reader.GetInt32("DestructionPoints");
            morale = reader.GetString("Morale");
            @class = reader.GetInt32("Class");
            movement = reader.GetString("Movement");
            save = reader.GetString("Save");
            fa = reader.GetString("FA");
        }

        var abilities = new List<AbilityLink>();
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT sa.SpecialAbilityId, sa.SpecialAbilityName, bsa.AbilityValue
                FROM BaseSpecialAbility bsa
                JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId
                WHERE bsa.BaseId = @id
                ORDER BY sa.SpecialAbilityName
                """;
            cmd.Parameters.AddWithValue("@id", baseId);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                abilities.Add(new AbilityLink
                {
                    Id = reader.GetInt32("SpecialAbilityId"),
                    Name = ParameterizedName.Format(
                        reader.GetString("SpecialAbilityName"),
                        reader.GetString("AbilityValue"))
                });
            }
        }

        var allWeapons = await LoadWeaponsForBaseAsync(conn, baseId, cancellationToken);
        var builtIn = allWeapons.Where(w => !w.IsTitanWeapon).ToList();
        var chosen = new List<WeaponProfile>();
        if (armyId > 0 && formationId > 0)
        {
            var selected = await LoadChosenTitanCatalogAsync(conn, armyId, formationId, titanIndex, cancellationToken);
            foreach (var (titanWeaponId, catalogName, cost) in selected)
            {
                foreach (var weapon in allWeapons.Where(w => w.IsTitanWeapon && MatchesTitanCatalogName(w.Name, catalogName)))
                    chosen.Add(WithPointsCost(weapon, cost, titanWeaponId));
            }
        }

        return new BaseProfile
        {
            Id = id,
            Name = name,
            ImageBytes = imageBytes,
            Movement = movement,
            Save = save,
            FA = fa,
            Morale = morale,
            Class = @class,
            DestructionPoints = destructionPoints,
            Abilities = abilities,
            Weapons = builtIn,
            ChosenTitanWeapons = chosen,
            DetachmentName = string.IsNullOrWhiteSpace(detachmentName) ? null : detachmentName
        };
    }

    public async Task<TitanWeaponDetail?> GetTitanWeaponDetailAsync(
        int titanWeaponId,
        int formationId = 0,
        CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var catalogCmd = conn.CreateCommand();
        catalogCmd.CommandText = """
            SELECT TitanWeaponId, WeaponName, Notes, PointsCost
            FROM TitanWeapon
            WHERE TitanWeaponId = @id
            """;
        catalogCmd.Parameters.AddWithValue("@id", titanWeaponId);

        int id;
        string name;
        string notes;
        int pointsCost;
        await using (var reader = await catalogCmd.ExecuteReaderAsync(cancellationToken))
        {
            if (!await reader.ReadAsync(cancellationToken))
                return null;
            id = reader.GetInt32("TitanWeaponId");
            name = reader.GetString("WeaponName");
            notes = reader.GetString("Notes");
            pointsCost = reader.GetInt32("PointsCost");
        }

        var baseId = await ResolveTitanBaseIdAsync(conn, formationId, cancellationToken);
        IReadOnlyList<WeaponProfile> profiles = [];
        if (baseId is int resolved)
        {
            var weapons = await LoadWeaponsForBaseAsync(conn, resolved, cancellationToken);
            profiles = weapons
                .Where(w => w.IsTitanWeapon && MatchesTitanCatalogName(w.Name, name))
                .Select(w => WithPointsCost(w, pointsCost, id))
                .ToList();
        }

        return new TitanWeaponDetail
        {
            Id = id,
            Name = name,
            Notes = notes,
            PointsCost = pointsCost,
            Profiles = profiles
        };
    }

    public async Task<int> CreateArmyAsync(string name, int codexId, int pointsLimit, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            INSERT INTO Army (UserId, CodexId, ArmyName, PointsLimit)
            VALUES (@userId, @codexId, @name, @pointsLimit)
            """;
        cmd.Parameters.AddWithValue("@userId", RequireUserId());
        cmd.Parameters.AddWithValue("@codexId", codexId);
        cmd.Parameters.AddWithValue("@name", name);
        cmd.Parameters.AddWithValue("@pointsLimit", pointsLimit);
        await cmd.ExecuteNonQueryAsync(cancellationToken);
        return (int)cmd.LastInsertedId;
    }

    public async Task UpdateArmyAsync(int armyId, string name, int pointsLimit, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            UPDATE Army
            SET ArmyName = @name, PointsLimit = @pointsLimit
            WHERE ArmyId = @id AND UserId = @userId
            """;
        cmd.Parameters.AddWithValue("@id", armyId);
        cmd.Parameters.AddWithValue("@userId", RequireUserId());
        cmd.Parameters.AddWithValue("@name", name);
        cmd.Parameters.AddWithValue("@pointsLimit", pointsLimit);
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task SetArmyFormationQuantityAsync(int armyId, int formationId, int quantity, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await EnsureArmyOwnedAsync(conn, armyId, cancellationToken);
        await using var cmd = conn.CreateCommand();
        if (quantity <= 0)
        {
            cmd.CommandText = "DELETE FROM ArmyFormation WHERE ArmyId = @armyId AND FormationId = @formationId";
            cmd.Parameters.AddWithValue("@armyId", armyId);
            cmd.Parameters.AddWithValue("@formationId", formationId);
            await cmd.ExecuteNonQueryAsync(cancellationToken);
            return;
        }

        cmd.CommandText = """
            INSERT INTO ArmyFormation (ArmyId, FormationId, Quantity)
            VALUES (@armyId, @formationId, @quantity)
            ON DUPLICATE KEY UPDATE Quantity = @quantity
            """;
        cmd.Parameters.AddWithValue("@armyId", armyId);
        cmd.Parameters.AddWithValue("@formationId", formationId);
        cmd.Parameters.AddWithValue("@quantity", quantity);
        await cmd.ExecuteNonQueryAsync(cancellationToken);
        await TrimArmyTitanWeaponsAsync(conn, armyId, formationId, quantity, cancellationToken);
    }

    public async Task<IReadOnlyList<TitanWeaponOption>> GetTitanWeaponsAsync(int codexId, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT TitanWeaponId, WeaponName, Notes, PointsCost
            FROM TitanWeapon
            WHERE CodexId = @codexId
            ORDER BY WeaponName
            """;
        cmd.Parameters.AddWithValue("@codexId", codexId);

        var results = new List<TitanWeaponOption>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(new TitanWeaponOption
            {
                Id = reader.GetInt32("TitanWeaponId"),
                Name = reader.GetString("WeaponName"),
                Notes = reader.GetString("Notes"),
                PointsCost = reader.GetInt32("PointsCost")
            });
        }

        return results;
    }

    public async Task AddArmyTitanWeaponAsync(
        int armyId,
        int formationId,
        int titanIndex,
        int titanWeaponId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await EnsureArmyOwnedAsync(conn, armyId, cancellationToken);
        var slot = await GetTitanSlotAsync(conn, armyId, formationId, titanIndex, cancellationToken);
        if (slot is null)
            throw new InvalidOperationException("That titan is not in the army.");
        if (!slot.CanAdd)
            throw new InvalidOperationException("This titan has no remaining weapon slots.");

        await using var catalogCmd = conn.CreateCommand();
        catalogCmd.CommandText = """
            SELECT WeaponName, IsAssault, LimitPerTitan
            FROM TitanWeapon
            WHERE TitanWeaponId = @id
            """;
        catalogCmd.Parameters.AddWithValue("@id", titanWeaponId);
        string weaponName;
        bool isAssault;
        int limitPerTitan;
        await using (var reader = await catalogCmd.ExecuteReaderAsync(cancellationToken))
        {
            if (!await reader.ReadAsync(cancellationToken))
                throw new InvalidOperationException("That titan weapon was not found.");
            weaponName = reader.GetString("WeaponName");
            isAssault = reader.GetBoolean("IsAssault");
            limitPerTitan = reader.GetInt32("LimitPerTitan");
        }

        if (limitPerTitan > 0 && slot.Weapons.Count(w => w.Name == weaponName) >= limitPerTitan)
            throw new InvalidOperationException($"Only {limitPerTitan} {weaponName} may be taken on this titan.");

        if (isAssault && slot.Weapons.Any(w => w.Name == weaponName))
            throw new InvalidOperationException("The same assault weapon cannot be taken twice.");

        var stored = await LoadStoredTitanWeaponsAsync(conn, armyId, formationId, cancellationToken);
        stored.Add(new StoredArmyTitanWeapon
        {
            Id = stored.Count == 0 ? 1 : stored.Max(w => w.Id) + 1,
            TitanIndex = titanIndex,
            TitanWeaponId = titanWeaponId
        });
        await SaveStoredTitanWeaponsAsync(conn, armyId, formationId, stored, cancellationToken);
    }

    public async Task RemoveArmyTitanWeaponAsync(
        int armyId,
        int formationId,
        int weaponId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await EnsureArmyOwnedAsync(conn, armyId, cancellationToken);
        var stored = await LoadStoredTitanWeaponsAsync(conn, armyId, formationId, cancellationToken);
        stored.RemoveAll(w => w.Id == weaponId);
        await SaveStoredTitanWeaponsAsync(conn, armyId, formationId, stored, cancellationToken);
    }

    static async Task AttachTitansAsync(
        MySqlConnection conn,
        int armyId,
        List<ArmyEntry> entries,
        CancellationToken cancellationToken)
    {
        var templates = await LoadTitanTemplatesAsync(
            conn,
            entries.Select(e => e.FormationId).Distinct().ToList(),
            cancellationToken);
        var weapons = await LoadArmyTitanWeaponsAsync(conn, armyId, cancellationToken);

        for (var i = 0; i < entries.Count; i++)
        {
            var entry = entries[i];
            if (!templates.TryGetValue(entry.FormationId, out var formationTemplates))
                continue;

            entries[i] = new ArmyEntry
            {
                FormationId = entry.FormationId,
                FormationName = entry.FormationName,
                Contents = entry.Contents,
                Quantity = entry.Quantity,
                PointsCost = entry.PointsCost,
                CommandPoints = entry.CommandPoints,
                Class = entry.Class,
                Titans = BuildTitanSlots(entry.FormationId, entry.Quantity, formationTemplates, weapons)
            };
        }
    }

    static async Task<ArmyTitanSlot?> GetTitanSlotAsync(
        MySqlConnection conn,
        int armyId,
        int formationId,
        int titanIndex,
        CancellationToken cancellationToken)
    {
        await using var qtyCmd = conn.CreateCommand();
        qtyCmd.CommandText = """
            SELECT Quantity
            FROM ArmyFormation
            WHERE ArmyId = @armyId AND FormationId = @formationId
            """;
        qtyCmd.Parameters.AddWithValue("@armyId", armyId);
        qtyCmd.Parameters.AddWithValue("@formationId", formationId);
        var quantityObj = await qtyCmd.ExecuteScalarAsync(cancellationToken);
        if (quantityObj is null or DBNull)
            return null;

        var quantity = Convert.ToInt32(quantityObj);
        var templates = await LoadTitanTemplatesAsync(conn, [formationId], cancellationToken);
        if (!templates.TryGetValue(formationId, out var formationTemplates))
            return null;

        var weapons = await LoadArmyTitanWeaponsAsync(conn, armyId, cancellationToken);
        return BuildTitanSlots(formationId, quantity, formationTemplates, weapons)
            .FirstOrDefault(slot => slot.TitanIndex == titanIndex);
    }

    static async Task TrimArmyTitanWeaponsAsync(
        MySqlConnection conn,
        int armyId,
        int formationId,
        int quantity,
        CancellationToken cancellationToken)
    {
        await using var countCmd = conn.CreateCommand();
        countCmd.CommandText = """
            SELECT COALESCE(SUM(fd.Quantity * dc.BaseCount), 0)
            FROM FormationDetachment fd
            JOIN DetachmentComposition dc ON dc.DetachmentId = fd.DetachmentId
            JOIN `Base` b ON b.BaseId = dc.BaseId
            WHERE fd.FormationId = @formationId
              AND b.NumberOfTitanWeapons > 0
            """;
        countCmd.Parameters.AddWithValue("@formationId", formationId);
        var titansPerCopy = Convert.ToInt32(await countCmd.ExecuteScalarAsync(cancellationToken) ?? 0);
        var maxCount = quantity * titansPerCopy;
        var stored = await LoadStoredTitanWeaponsAsync(conn, armyId, formationId, cancellationToken);
        stored.RemoveAll(w => w.TitanIndex >= maxCount);
        await SaveStoredTitanWeaponsAsync(conn, armyId, formationId, stored, cancellationToken);
    }

    static async Task<List<WeaponProfile>> LoadWeaponsForBaseAsync(
        MySqlConnection conn,
        int baseId,
        CancellationToken cancellationToken)
    {
        var weapons = new List<WeaponProfile>();
        var weaponAbilities = new Dictionary<int, List<AbilityLink>>();
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT WeaponId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, IsTitanWeapon
                FROM Weapon
                WHERE BaseId = @id
                ORDER BY WeaponId
                """;
            cmd.Parameters.AddWithValue("@id", baseId);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                var weaponId = reader.GetInt32("WeaponId");
                weaponAbilities[weaponId] = [];
                weapons.Add(new WeaponProfile
                {
                    Id = weaponId,
                    Name = reader.GetString("Name"),
                    Range = reader.GetString("Range"),
                    Dice = reader.GetString("Dice"),
                    ToHit = reader.GetString("ToHit"),
                    ArmourPenetration = reader.GetString("ArmourPenetration"),
                    IsTitanWeapon = reader.GetBoolean("IsTitanWeapon"),
                    Abilities = weaponAbilities[weaponId]
                });
            }
        }

        if (weaponAbilities.Count == 0)
            return weapons;

        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT wsa.WeaponId, sa.SpecialAbilityId, sa.SpecialAbilityName, wsa.AbilityValue
                FROM WeaponSpecialAbility wsa
                JOIN SpecialAbility sa ON sa.SpecialAbilityId = wsa.SpecialAbilityId
                WHERE wsa.WeaponId IN (
                    SELECT WeaponId FROM Weapon WHERE BaseId = @id
                )
                ORDER BY sa.SpecialAbilityName
                """;
            cmd.Parameters.AddWithValue("@id", baseId);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                var weaponId = reader.GetInt32("WeaponId");
                if (!weaponAbilities.TryGetValue(weaponId, out var list))
                    continue;
                list.Add(new AbilityLink
                {
                    Id = reader.GetInt32("SpecialAbilityId"),
                    Name = ParameterizedName.Format(
                        reader.GetString("SpecialAbilityName"),
                        reader.GetString("AbilityValue"))
                });
            }
        }

        return weapons;
    }

    static async Task<List<(int TitanWeaponId, string Name, int PointsCost)>> LoadChosenTitanCatalogAsync(
        MySqlConnection conn,
        int armyId,
        int formationId,
        int? titanIndex,
        CancellationToken cancellationToken)
    {
        var stored = await LoadStoredTitanWeaponsAsync(conn, armyId, formationId, cancellationToken);
        if (titanIndex is int index)
            stored = stored.Where(w => w.TitanIndex == index).ToList();

        var ids = stored.Select(w => w.TitanWeaponId).Distinct().ToList();
        var catalog = await LoadTitanWeaponInfoAsync(conn, ids, cancellationToken);
        var results = new List<(int TitanWeaponId, string Name, int PointsCost)>();
        foreach (var weapon in stored)
        {
            if (!catalog.TryGetValue(weapon.TitanWeaponId, out var info))
                continue;
            results.Add((weapon.TitanWeaponId, info.Name, info.PointsCost));
        }

        return results;
    }

    static async Task<int?> ResolveTitanBaseIdAsync(
        MySqlConnection conn,
        int formationId,
        CancellationToken cancellationToken)
    {
        await using var cmd = conn.CreateCommand();
        if (formationId > 0)
        {
            cmd.CommandText = """
                SELECT b.BaseId
                FROM FormationDetachment fd
                JOIN DetachmentComposition dc ON dc.DetachmentId = fd.DetachmentId
                JOIN `Base` b ON b.BaseId = dc.BaseId
                WHERE fd.FormationId = @formationId
                  AND b.NumberOfTitanWeapons > 0
                ORDER BY b.BaseId
                LIMIT 1
                """;
            cmd.Parameters.AddWithValue("@formationId", formationId);
        }
        else
        {
            cmd.CommandText = """
                SELECT b.BaseId
                FROM `Base` b
                WHERE b.NumberOfTitanWeapons > 0
                ORDER BY b.BaseId
                LIMIT 1
                """;
        }

        var value = await cmd.ExecuteScalarAsync(cancellationToken);
        return value is null or DBNull ? null : Convert.ToInt32(value);
    }

    static bool MatchesTitanCatalogName(string weaponName, string catalogName) =>
        weaponName.Equals(catalogName, StringComparison.OrdinalIgnoreCase) ||
        weaponName.StartsWith(catalogName + " -- ", StringComparison.OrdinalIgnoreCase);

    static WeaponProfile WithPointsCost(WeaponProfile weapon, int pointsCost, int? titanWeaponId = null) => new()
    {
        Id = weapon.Id,
        Name = weapon.Name,
        Range = weapon.Range,
        Dice = weapon.Dice,
        ToHit = weapon.ToHit,
        ArmourPenetration = weapon.ArmourPenetration,
        IsTitanWeapon = weapon.IsTitanWeapon,
        PointsCost = pointsCost,
        TitanWeaponId = titanWeaponId,
        Abilities = weapon.Abilities
    };

    static async Task<Dictionary<int, List<TitanTemplate>>> LoadTitanTemplatesAsync(
        MySqlConnection conn,
        IReadOnlyList<int> formationIds,
        CancellationToken cancellationToken)
    {
        var result = new Dictionary<int, List<TitanTemplate>>();
        if (formationIds.Count == 0)
            return result;

        await using var cmd = conn.CreateCommand();
        var names = formationIds.Select((_, i) => $"@f{i}").ToArray();
        cmd.CommandText = $"""
            SELECT f.FormationId, b.BaseName, b.NumberOfTitanWeapons AS WeaponSlots,
                   SUM(fd.Quantity * dc.BaseCount) AS TitansPerCopy
            FROM Formation f
            JOIN FormationDetachment fd ON fd.FormationId = f.FormationId
            JOIN DetachmentComposition dc ON dc.DetachmentId = fd.DetachmentId
            JOIN `Base` b ON b.BaseId = dc.BaseId
            WHERE f.FormationId IN ({string.Join(", ", names)})
              AND b.NumberOfTitanWeapons > 0
            GROUP BY f.FormationId, b.BaseId, b.BaseName, b.NumberOfTitanWeapons
            ORDER BY f.FormationId, b.BaseName
            """;
        for (var i = 0; i < formationIds.Count; i++)
            cmd.Parameters.AddWithValue(names[i], formationIds[i]);

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var formationId = reader.GetInt32("FormationId");
            if (!result.TryGetValue(formationId, out var list))
            {
                list = [];
                result[formationId] = list;
            }

            list.Add(new TitanTemplate(
                reader.GetString("BaseName"),
                reader.GetInt32("WeaponSlots"),
                Convert.ToInt32(reader.GetValue(reader.GetOrdinal("TitansPerCopy")))));
        }

        return result;
    }

    static async Task<IReadOnlyList<ArmyTitanWeaponRow>> LoadArmyTitanWeaponsAsync(
        MySqlConnection conn,
        int armyId,
        CancellationToken cancellationToken)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT FormationId, TitanWeapons
            FROM ArmyFormation
            WHERE ArmyId = @armyId
            """;
        cmd.Parameters.AddWithValue("@armyId", armyId);

        var storedByFormation = new List<(int FormationId, List<StoredArmyTitanWeapon> Weapons)>();
        await using (var reader = await cmd.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                var json = reader.IsDBNull(reader.GetOrdinal("TitanWeapons"))
                    ? null
                    : reader.GetString("TitanWeapons");
                storedByFormation.Add((reader.GetInt32("FormationId"), ParseStoredTitanWeapons(json)));
            }
        }

        var ids = storedByFormation.SelectMany(x => x.Weapons).Select(w => w.TitanWeaponId).Distinct().ToList();
        var catalog = await LoadTitanWeaponInfoAsync(conn, ids, cancellationToken);

        var results = new List<ArmyTitanWeaponRow>();
        foreach (var (formationId, weapons) in storedByFormation)
        {
            foreach (var weapon in weapons)
            {
                if (!catalog.TryGetValue(weapon.TitanWeaponId, out var info))
                    continue;
                results.Add(new ArmyTitanWeaponRow(
                    weapon.Id,
                    weapon.TitanWeaponId,
                    formationId,
                    weapon.TitanIndex,
                    info.Name,
                    info.PointsCost));
            }
        }

        return results;
    }

    static async Task<List<StoredArmyTitanWeapon>> LoadStoredTitanWeaponsAsync(
        MySqlConnection conn,
        int armyId,
        int formationId,
        CancellationToken cancellationToken)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT TitanWeapons
            FROM ArmyFormation
            WHERE ArmyId = @armyId AND FormationId = @formationId
            """;
        cmd.Parameters.AddWithValue("@armyId", armyId);
        cmd.Parameters.AddWithValue("@formationId", formationId);
        var json = await cmd.ExecuteScalarAsync(cancellationToken);
        return ParseStoredTitanWeapons(json as string);
    }

    static async Task SaveStoredTitanWeaponsAsync(
        MySqlConnection conn,
        int armyId,
        int formationId,
        IReadOnlyList<StoredArmyTitanWeapon> weapons,
        CancellationToken cancellationToken)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            UPDATE ArmyFormation
            SET TitanWeapons = @json
            WHERE ArmyId = @armyId AND FormationId = @formationId
            """;
        cmd.Parameters.AddWithValue("@armyId", armyId);
        cmd.Parameters.AddWithValue("@formationId", formationId);
        cmd.Parameters.AddWithValue("@json", SerializeStoredTitanWeapons(weapons));
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    static async Task<Dictionary<int, int>> SumTitanWeaponPointsByArmyAsync(
        MySqlConnection conn,
        CancellationToken cancellationToken)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT ArmyId, TitanWeapons FROM ArmyFormation";
        var stored = new List<(int ArmyId, List<StoredArmyTitanWeapon> Weapons)>();
        await using (var reader = await cmd.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                var json = reader.IsDBNull(reader.GetOrdinal("TitanWeapons"))
                    ? null
                    : reader.GetString("TitanWeapons");
                stored.Add((reader.GetInt32("ArmyId"), ParseStoredTitanWeapons(json)));
            }
        }

        var ids = stored.SelectMany(x => x.Weapons).Select(w => w.TitanWeaponId).Distinct().ToList();
        var catalog = await LoadTitanWeaponInfoAsync(conn, ids, cancellationToken);
        var totals = new Dictionary<int, int>();
        foreach (var (armyId, weapons) in stored)
        {
            var points = weapons.Sum(w => catalog.TryGetValue(w.TitanWeaponId, out var info) ? info.PointsCost : 0);
            if (points == 0)
                continue;
            totals[armyId] = totals.GetValueOrDefault(armyId) + points;
        }

        return totals;
    }

    static async Task<Dictionary<int, (string Name, int PointsCost)>> LoadTitanWeaponInfoAsync(
        MySqlConnection conn,
        IReadOnlyList<int> ids,
        CancellationToken cancellationToken)
    {
        var result = new Dictionary<int, (string Name, int PointsCost)>();
        if (ids.Count == 0)
            return result;

        await using var cmd = conn.CreateCommand();
        var names = ids.Select((_, i) => $"@w{i}").ToArray();
        cmd.CommandText = $"""
            SELECT TitanWeaponId, WeaponName, PointsCost
            FROM TitanWeapon
            WHERE TitanWeaponId IN ({string.Join(", ", names)})
            """;
        for (var i = 0; i < ids.Count; i++)
            cmd.Parameters.AddWithValue(names[i], ids[i]);

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result[reader.GetInt32("TitanWeaponId")] = (
                reader.GetString("WeaponName"),
                reader.GetInt32("PointsCost"));
        }

        return result;
    }

    static List<StoredArmyTitanWeapon> ParseStoredTitanWeapons(string? json)
    {
        if (string.IsNullOrWhiteSpace(json) || json is "null" or "NULL")
            return [];

        return JsonSerializer.Deserialize<List<StoredArmyTitanWeapon>>(json, TitanWeaponJson) ?? [];
    }

    static string SerializeStoredTitanWeapons(IReadOnlyList<StoredArmyTitanWeapon> weapons) =>
        JsonSerializer.Serialize(weapons, TitanWeaponJson);

    static IReadOnlyList<ArmyTitanSlot> BuildTitanSlots(
        int formationId,
        int quantity,
        IReadOnlyList<TitanTemplate> templates,
        IReadOnlyList<ArmyTitanWeaponRow> weapons)
    {
        var totalTitans = quantity * templates.Sum(t => t.TitansPerCopy);
        if (totalTitans <= 0)
            return [];

        var slots = new List<ArmyTitanSlot>(totalTitans);
        var index = 0;
        for (var copy = 0; copy < quantity; copy++)
        {
            foreach (var template in templates)
            {
                for (var n = 0; n < template.TitansPerCopy; n++)
                {
                    var titanIndex = index;
                    var equipped = weapons
                        .Where(w => w.FormationId == formationId && w.TitanIndex == titanIndex)
                        .Select(w => new ArmyTitanWeaponItem
                        {
                            Id = w.Id,
                            TitanWeaponId = w.TitanWeaponId,
                            FormationId = formationId,
                            Name = w.Name,
                            PointsCost = w.PointsCost
                        })
                        .ToList();
                    var displayName = totalTitans > 1
                        ? $"{template.BaseName} {titanIndex + 1}"
                        : template.BaseName;
                    slots.Add(new ArmyTitanSlot
                    {
                        FormationId = formationId,
                        TitanIndex = titanIndex,
                        BaseName = displayName,
                        WeaponSlots = template.WeaponSlots,
                        Weapons = equipped
                    });
                    index++;
                }
            }
        }

        return slots;
    }

    sealed record TitanTemplate(string BaseName, int WeaponSlots, int TitansPerCopy);

    sealed record ArmyTitanWeaponRow(int Id, int TitanWeaponId, int FormationId, int TitanIndex, string Name, int PointsCost);

    sealed class StoredArmyTitanWeapon
    {
        public int Id { get; set; }
        public int TitanIndex { get; set; }
        public int TitanWeaponId { get; set; }
    }

    static RuleListItem ReadRule(MySqlDataReader reader) => new()
    {
        Id = reader.GetInt32("Id"),
        Name = reader.GetString("Name"),
        Description = reader.GetString("Description"),
        Kind = reader.GetString("Kind")
    };

    async Task AddParameterizedMatchesAsync(
        List<RuleListItem> results,
        string term,
        CancellationToken cancellationToken)
    {
        var names = await GetAllRuleNamesAsync(cancellationToken);
        foreach (var name in names)
        {
            if (!ParameterizedName.Matches(name.Name, term))
                continue;
            if (results.Any(rule => rule.Id == name.Id &&
                string.Equals(rule.Kind, name.Kind, StringComparison.OrdinalIgnoreCase)))
                continue;

            var full = await GetRuleAsync(name.Id, name.Kind, cancellationToken);
            if (full is not null)
                results.Insert(0, full);
        }
    }

    static (string Table, string IdColumn, string NameColumn) TableForKind(string kind) => kind switch
    {
        "Ability" => ("SpecialAbility", "SpecialAbilityId", "SpecialAbilityName"),
        "Special Rule" => ("SpecialRule", "SpecialRuleId", "SpecialRuleName"),
        _ => ("Rule", "RuleId", "RuleName")
    };

    async Task<MySqlConnection> OpenAdminAsync(CancellationToken cancellationToken) =>
        await OpenAsync(cancellationToken, asAdmin: true);

    async Task<MySqlConnection> OpenAsync(CancellationToken cancellationToken, bool asAdmin = false)
    {
        var (user, password) = asAdmin || SessionService.Instance.IsAdmin
            ? ("Admin", SessionService.AdminPassword)
            : ("Guest", SessionService.StandardPassword);
        Exception? last = null;

        foreach (var (host, port) in Endpoints)
        {
            var cs = new MySqlConnectionStringBuilder
            {
                Server = host,
                Port = port,
                UserID = user,
                Password = password,
                Database = "baguettepic",
                SslMode = MySqlSslMode.Disabled,
                AllowPublicKeyRetrieval = true,
                ConnectionTimeout = 5
            }.ConnectionString;

            var conn = new MySqlConnection(cs);
            try
            {
                await conn.OpenAsync(cancellationToken);
                return conn;
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                last = ex;
                conn.Dispose();
            }
        }

        throw last ?? new InvalidOperationException("Could not reach the database.");
    }

    static int RequireUserId() =>
        SessionService.Instance.CurrentUserId
        ?? throw new InvalidOperationException("Not signed in.");

    static async Task EnsureArmyOwnedAsync(
        MySqlConnection conn,
        int armyId,
        CancellationToken cancellationToken)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT 1
            FROM Army
            WHERE ArmyId = @id AND UserId = @userId
            LIMIT 1
            """;
        cmd.Parameters.AddWithValue("@id", armyId);
        cmd.Parameters.AddWithValue("@userId", RequireUserId());
        var value = await cmd.ExecuteScalarAsync(cancellationToken);
        if (value is null or DBNull)
            throw new InvalidOperationException("Army not found.");
    }

    static string EscapeLike(string value) =>
        value.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");
}
