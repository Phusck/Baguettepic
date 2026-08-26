namespace Baguettepic.Models;

public sealed class ArmyTitanSlot
{
    public required int FormationId { get; init; }
    public required int TitanIndex { get; init; }
    public required string BaseName { get; init; }
    public required int WeaponSlots { get; init; }
    public required IReadOnlyList<ArmyTitanWeaponItem> Weapons { get; init; }

    public bool CanAdd => Weapons.Count < WeaponSlots;
    public string Header => $"{BaseName}  ·  {Weapons.Count}/{WeaponSlots} weapons";
}
