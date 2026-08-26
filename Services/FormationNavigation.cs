namespace Baguettepic.Services;

static class FormationNavigation
{
    public static async Task OpenAsync(int formationId, int? armyId = null, int? titanIndex = null)
    {
        var roster = await DatabaseService.Instance.GetFormationRosterAsync(formationId);
        var armyQuery = ArmyQuery(armyId, formationId, titanIndex);

        if (roster?.SingleBase is { } row)
        {
            await Shell.Current.GoToAsync(
                $"BaseDetail?baseId={row.BaseId}&detachmentName={Uri.EscapeDataString(row.DetachmentName)}{armyQuery}");
            return;
        }

        await Shell.Current.GoToAsync($"FormationDetachments?formationId={formationId}{ArmyQuery(armyId, null, titanIndex)}");
    }

    public static Task OpenTitanWeaponAsync(int titanWeaponId, int formationId = 0) =>
        Shell.Current.GoToAsync($"TitanWeaponDetail?id={titanWeaponId}&formationId={formationId}");

    static string ArmyQuery(int? armyId, int? formationId, int? titanIndex)
    {
        if (armyId is not > 0)
            return string.Empty;

        var query = $"&armyId={armyId.Value}";
        if (formationId is > 0)
            query += $"&formationId={formationId.Value}";
        if (titanIndex is int index)
            query += $"&titanIndex={index}";
        return query;
    }
}
