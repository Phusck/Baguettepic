namespace Baguettepic.Models;

public sealed class ArmyListItem
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string CodexName { get; init; }
    public required int PointsLimit { get; init; }
    public required int PointsCost { get; init; }
    public required int CommandPoints { get; init; }
    public required int EntryCount { get; init; }

    public string SummaryText => $"{CodexName}  ·  {PointsCost} / {PointsLimit} pts  ·  {CommandPoints} CP";
}
