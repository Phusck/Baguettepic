using Baguettepic.Models;

namespace Baguettepic.Services;

static class FormationNavigation
{
    public static async Task OpenAsync(int formationId)
    {
        var roster = await DatabaseService.Instance.GetFormationRosterAsync(formationId);
        if (roster?.SingleBase is { } row)
        {
            await Shell.Current.GoToAsync(
                $"BaseDetail?baseId={row.BaseId}&detachmentName={Uri.EscapeDataString(row.DetachmentName)}");
            return;
        }

        await Shell.Current.GoToAsync($"FormationDetachments?formationId={formationId}");
    }
}
