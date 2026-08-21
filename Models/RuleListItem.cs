namespace Baguettepic.Models;

public sealed class RuleListItem
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Description { get; init; }
    public required string Kind { get; init; }
}

public sealed class RuleSearchDivider
{
    public static RuleSearchDivider Instance { get; } = new();
}
