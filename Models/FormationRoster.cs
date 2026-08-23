namespace Baguettepic.Models;

public sealed class FormationRoster
{
    public required int FormationId { get; init; }
    public required string FormationName { get; init; }
    public required IReadOnlyList<DetachmentGroup> Detachments { get; init; }

    public DetachmentBaseRow? SingleBase =>
        Detachments.Count == 1 && Detachments[0].Bases.Count == 1
            ? Detachments[0].Bases[0]
            : null;
}
