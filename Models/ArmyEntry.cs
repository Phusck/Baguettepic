namespace Baguettepic.Models;

public sealed class ArmyEntry
{
    public required int FormationId { get; init; }
    public required string FormationName { get; init; }
    public required string Contents { get; init; }
    public required int Quantity { get; init; }
    public required int PointsCost { get; init; }
    public required int CommandPoints { get; init; }
    public required int Class { get; init; }
    public required IReadOnlyList<ArmyTitanSlot> Titans { get; init; }

    public bool HasTitans => Titans.Count > 0;
    public int LinePoints => Quantity * PointsCost + Titans.Sum(t => t.Weapons.Sum(w => w.PointsCost));
    public int LineCommandPoints => Quantity * CommandPoints;
    public string CostText => $"{LinePoints} pts";
    public string CommandText => LineCommandPoints > 0
        ? $"+{LineCommandPoints} CP"
        : $"{LineCommandPoints} CP";
    public string DetailText => $"{Quantity} × {Contents}  ·  {CommandText}";
}
