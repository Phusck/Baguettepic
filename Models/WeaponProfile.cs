namespace Baguettepic.Models;

public sealed class WeaponProfile
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Range { get; init; }
    public required int Dice { get; init; }
    public required string ToHit { get; init; }
    public required int ArmourPenetration { get; init; }
    public required int FiringArc { get; init; }
    public required bool IsTitanWeapon { get; init; }
    public required IReadOnlyList<AbilityLink> Abilities { get; init; }

    public bool HasAbilities => Abilities.Count > 0;
    public string DiceText => Dice == 0 ? "--" : Dice.ToString();
    public string ApText => ArmourPenetration.ToString("+0;-0;0");
    public string ArcText => FiringArc == 0 ? "--" : $"{FiringArc}°";
}
