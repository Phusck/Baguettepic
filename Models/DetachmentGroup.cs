namespace Baguettepic.Models;

public sealed class DetachmentGroup
{
    public required int DetachmentId { get; init; }
    public required string DetachmentName { get; init; }
    public required int Class { get; init; }
    public required int CommandPoints { get; init; }
    public required IReadOnlyList<DetachmentBaseRow> Bases { get; init; }

    public bool HasBases => Bases.Count > 0;
    public bool HasNoBases => Bases.Count == 0;
    public string Summary => CommandPoints > 0
        ? $"Class {Class}  ·  +{CommandPoints} CP"
        : $"Class {Class}  ·  {CommandPoints} CP";
}
