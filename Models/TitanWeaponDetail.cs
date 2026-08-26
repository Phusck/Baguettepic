namespace Baguettepic.Models;

public sealed class TitanWeaponDetail
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Notes { get; init; }
    public required int PointsCost { get; init; }
    public required IReadOnlyList<WeaponProfile> Profiles { get; init; }

    public string CostText => $"{PointsCost} pts";
    public bool HasNotes => !string.IsNullOrWhiteSpace(Notes);
    public bool HasProfiles => Profiles.Count > 0;
}
