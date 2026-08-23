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

    IReadOnlyList<RuleListItem>? _ruleNamesCache;

    public async Task<IReadOnlyList<RuleListItem>> SearchRulesAsync(string? query, CancellationToken cancellationToken = default)
    {
        var term = (query ?? string.Empty).Trim();
        var like = "%" + EscapeLike(term) + "%";

        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
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

        var results = new List<RuleListItem>();
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(ReadRule(reader));
        }

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
            GROUP BY a.ArmyId, a.ArmyName, c.CodexName, a.PointsLimit
            ORDER BY a.ArmyName
            """;

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
                PointsCost = reader.GetInt32("PointsCost"),
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
            SELECT a.ArmyId, a.CodexId, a.ArmyName, c.CodexName, a.PointsLimit, a.Notes,
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
            WHERE a.ArmyId = @id
            ORDER BY Class, f.FormationName
            """;
        cmd.Parameters.AddWithValue("@id", armyId);

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        ArmyDetail? army = null;
        var entries = new List<ArmyEntry>();
        while (await reader.ReadAsync(cancellationToken))
        {
            army ??= new ArmyDetail
            {
                Id = reader.GetInt32("ArmyId"),
                CodexId = reader.GetInt32("CodexId"),
                Name = reader.GetString("ArmyName"),
                CodexName = reader.GetString("CodexName"),
                PointsLimit = reader.GetInt32("PointsLimit"),
                Notes = reader.GetString("Notes"),
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
                Class = reader.GetInt32("Class")
            });
        }

        return army;
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
            ORDER BY k.FormationKindId, Class, f.FormationName
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

    public async Task<BaseProfile?> GetBaseProfileAsync(int baseId, string? detachmentName = null, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);

        await using var baseCmd = conn.CreateCommand();
        baseCmd.CommandText = """
            SELECT BaseId, BaseName, ImagePath, DestructionPoints, Morale, `Class`,
                   Movement, `Save`, FA
            FROM `Base`
            WHERE BaseId = @id
            LIMIT 1
            """;
        baseCmd.Parameters.AddWithValue("@id", baseId);

        int id;
        string name;
        string imagePath;
        int destructionPoints;
        int morale;
        int @class;
        int movement;
        string save;
        int fa;
        await using (var reader = await baseCmd.ExecuteReaderAsync(cancellationToken))
        {
            if (!await reader.ReadAsync(cancellationToken))
                return null;

            id = reader.GetInt32("BaseId");
            name = reader.GetString("BaseName");
            imagePath = reader.GetString("ImagePath");
            destructionPoints = reader.GetInt32("DestructionPoints");
            morale = reader.GetInt32("Morale");
            @class = reader.GetInt32("Class");
            movement = reader.GetInt32("Movement");
            save = reader.GetString("Save");
            fa = reader.GetInt32("FA");
        }

        var abilities = new List<AbilityLink>();
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT sa.SpecialAbilityId, sa.SpecialAbilityName
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
                    Name = reader.GetString("SpecialAbilityName")
                });
            }
        }

        var weapons = new List<WeaponProfile>();
        var weaponAbilities = new Dictionary<int, List<AbilityLink>>();
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT WeaponId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, FiringArc, IsTitanWeapon
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
                    Dice = reader.GetInt32("Dice"),
                    ToHit = reader.GetString("ToHit"),
                    ArmourPenetration = reader.GetInt32("ArmourPenetration"),
                    FiringArc = reader.GetInt32("FiringArc"),
                    IsTitanWeapon = reader.GetBoolean("IsTitanWeapon"),
                    Abilities = weaponAbilities[weaponId]
                });
            }
        }

        if (weaponAbilities.Count > 0)
        {
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                SELECT wsa.WeaponId, sa.SpecialAbilityId, sa.SpecialAbilityName
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
                    Name = reader.GetString("SpecialAbilityName")
                });
            }
        }

        return new BaseProfile
        {
            Id = id,
            Name = name,
            ImagePath = imagePath,
            Movement = movement,
            Save = save,
            FA = fa,
            Morale = morale,
            Class = @class,
            DestructionPoints = destructionPoints,
            Abilities = abilities,
            Weapons = weapons,
            DetachmentName = string.IsNullOrWhiteSpace(detachmentName) ? null : detachmentName
        };
    }

    public async Task<int> CreateArmyAsync(string name, int codexId, int pointsLimit, string notes, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            INSERT INTO Army (CodexId, ArmyName, PointsLimit, Notes)
            VALUES (@codexId, @name, @pointsLimit, @notes)
            """;
        cmd.Parameters.AddWithValue("@codexId", codexId);
        cmd.Parameters.AddWithValue("@name", name);
        cmd.Parameters.AddWithValue("@pointsLimit", pointsLimit);
        cmd.Parameters.AddWithValue("@notes", notes);
        await cmd.ExecuteNonQueryAsync(cancellationToken);
        return (int)cmd.LastInsertedId;
    }

    public async Task SetArmyFormationQuantityAsync(int armyId, int formationId, int quantity, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken);
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
    }

    static RuleListItem ReadRule(MySqlDataReader reader) => new()
    {
        Id = reader.GetInt32("Id"),
        Name = reader.GetString("Name"),
        Description = reader.GetString("Description"),
        Kind = reader.GetString("Kind")
    };

    static (string Table, string IdColumn, string NameColumn) TableForKind(string kind) => kind switch
    {
        "Ability" => ("SpecialAbility", "SpecialAbilityId", "SpecialAbilityName"),
        "Special Rule" => ("SpecialRule", "SpecialRuleId", "SpecialRuleName"),
        _ => ("Rule", "RuleId", "RuleName")
    };

    async Task<MySqlConnection> OpenAsync(CancellationToken cancellationToken)
    {
        var (user, password) = CredentialsForCurrentUser();
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

    static (string User, string Password) CredentialsForCurrentUser()
    {
        return SessionService.Instance.CurrentRole == UserRole.Admin
            ? ("Admin", SessionService.AdminPassword)
            : ("Guest", SessionService.GuestPassword);
    }

    static string EscapeLike(string value) =>
        value.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");
}
