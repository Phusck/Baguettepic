namespace Baguettepic.Models;

public sealed class TitanWeaponOption
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Notes { get; init; }
    public required int PointsCost { get; init; }

    public string CostText => $"{PointsCost} pts";
    public string DetailText => string.IsNullOrWhiteSpace(Notes) ? "Titan weapon" : Notes;
}
