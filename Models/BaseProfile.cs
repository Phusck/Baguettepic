namespace Baguettepic.Models;

public sealed class BaseProfile
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required byte[]? ImageBytes { get; init; }
    public required string Movement { get; init; }
    public required string Save { get; init; }
    public required string FA { get; init; }
    public required string Morale { get; init; }
    public required int Class { get; init; }
    public required int DestructionPoints { get; init; }
    public required IReadOnlyList<AbilityLink> Abilities { get; init; }
    public required IReadOnlyList<AbilityLink> PsychicPowers { get; init; }
    public required IReadOnlyList<WeaponProfile> Weapons { get; init; }
    public IReadOnlyList<WeaponProfile> ChosenTitanWeapons { get; init; } = [];

    public string? DetachmentName { get; init; }
    public bool HasImage => ImageBytes is { Length: > 0 };
    public bool HasAbilities => Abilities.Count > 0;
    public bool HasPsychicPowers => PsychicPowers.Count > 0;
    public bool HasWeapons => Weapons.Count > 0;
    public string MoveText => FormatMove(Movement);
    public string AfText => string.IsNullOrWhiteSpace(FA) ? "--" : FA;
    public string MoraleText => string.IsNullOrWhiteSpace(Morale) ? "--" : Morale;

    static string FormatMove(string movement)
    {
        if (string.IsNullOrWhiteSpace(movement) || movement == "--")
            return "--";
        return movement.Contains("cm", StringComparison.OrdinalIgnoreCase)
            ? movement
            : $"{movement} cm";
    }
    public string ClassText => Class.ToString();
    public string DestructionText => DestructionPoints.ToString();

    public ImageSource? Image =>
        ImageBytes is { Length: > 0 } bytes
            ? ImageSource.FromStream(() => new MemoryStream(bytes))
            : null;
}
