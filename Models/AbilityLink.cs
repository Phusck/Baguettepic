namespace Baguettepic.Models;

public sealed class AbilityLink
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public string Kind { get; init; } = "Ability";
}
