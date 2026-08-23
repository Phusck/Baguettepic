namespace Baguettepic.Models;

public sealed class DetachmentBaseRow
{
    public required int BaseId { get; init; }
    public required string BaseName { get; init; }
    public required int BaseCount { get; init; }
    public required int Class { get; init; }
    public required string DetachmentName { get; init; }

    public string DetailText => $"{BaseCount} × {BaseName}";
    public string ClassText => $"Class {Class}";
}
