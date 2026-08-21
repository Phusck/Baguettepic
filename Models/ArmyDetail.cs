namespace Baguettepic.Models;

public sealed class ArmyDetail
{
    public required int Id { get; init; }
    public required int CodexId { get; init; }
    public required string Name { get; init; }
    public required string CodexName { get; init; }
    public required int PointsLimit { get; init; }
    public required string Notes { get; init; }
    public required IReadOnlyList<ArmyEntry> Entries { get; init; }

    public int PointsCost => Entries.Sum(e => e.LinePoints);
    public int CommandPoints => Entries.Sum(e => e.LineCommandPoints);
    public string Summary => $"{CodexName}  ·  {PointsCost} / {PointsLimit} pts  ·  {CommandPoints} CP";
}
