namespace Baguettepic.Models;

public sealed class WeaponProfile
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Range { get; init; }
    public required string Dice { get; init; }
    public required string ToHit { get; init; }
    public required string ArmourPenetration { get; init; }
    public required bool IsTitanWeapon { get; init; }
    public int? PointsCost { get; init; }
    public int? TitanWeaponId { get; init; }
    public required IReadOnlyList<AbilityLink> Abilities { get; init; }

    public bool HasAbilities => Abilities.Count > 0;
    public string DiceText => FormatDice(Dice, Abilities);
    public string ApText => FormatAp(ArmourPenetration);

    static string Blank(string value) =>
        string.IsNullOrWhiteSpace(value) || value == "0" ? "--" : value;

    static string FormatDice(string dice, IReadOnlyList<AbilityLink> abilities)
    {
        if (!string.Equals(dice, "Template", StringComparison.OrdinalIgnoreCase))
            return Blank(dice);

        foreach (var ability in abilities)
        {
            if (ability.Name.StartsWith("Template (", StringComparison.OrdinalIgnoreCase) &&
                ability.Name.EndsWith(')'))
                return ability.Name;

            if (string.Equals(ability.Name, "Flame Template", StringComparison.OrdinalIgnoreCase))
                return ability.Name;
        }

        return "Template";
    }

    static string FormatAp(string value)
    {
        if (string.IsNullOrWhiteSpace(value) || value == "--")
            return "--";
        if (int.TryParse(value, out var n))
            return n.ToString("+0;-0;0");
        return value;
    }
}
