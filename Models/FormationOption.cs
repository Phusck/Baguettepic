namespace Baguettepic.Models;

public sealed class FormationOption
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string KindName { get; init; }
    public required string Contents { get; init; }
    public required int PointsCost { get; init; }
    public required int CommandPoints { get; init; }
    public required int Class { get; init; }

    public string CostText => $"{PointsCost} pts";
    public string DetailText => $"{KindName}  ·  {Contents}  ·  {CommandText}";
    public string CommandText => CommandPoints > 0
        ? $"+{CommandPoints} CP"
        : $"{CommandPoints} CP";
}
