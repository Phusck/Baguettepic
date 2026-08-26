namespace Baguettepic.Models;

public sealed class ArmyTitanWeaponItem
{
    public required int Id { get; init; }
    public required int TitanWeaponId { get; init; }
    public required int FormationId { get; init; }
    public required string Name { get; init; }
    public required int PointsCost { get; init; }

    public string CostText => $"{PointsCost} pts";
}
