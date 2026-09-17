using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.WindowsPdf;

static class ArmyPdfExportService
{
    public static async Task ChangeFolderAsync(Page page)
    {
        var picked = await PdfExportFolderPicker.PickAsync();
        if (string.IsNullOrWhiteSpace(picked))
            return;

        PdfExportFolderStore.Set(picked);
        await page.DisplayAlertAsync("PDF folder", picked, "OK");
    }

    public static async Task ExportArmyAsync(Page page, int armyId)
    {
        var army = await ArmyCacheService.Instance.GetArmyAsync(armyId);
        if (army is null)
        {
            await page.DisplayAlertAsync("Create PDFs", "Army not found.", "OK");
            return;
        }

        if (!WindowsFolderName.IsValid(army.Name, out _))
        {
            await page.DisplayAlertAsync(
                "Create PDFs",
                "This army's name is not a legal Windows folder name. Rename it, then try again.",
                "OK");
            return;
        }

        if (army.Entries.Count == 0)
        {
            await page.DisplayAlertAsync("Create PDFs", "This army has no formations yet.", "OK");
            return;
        }

        var root = PdfExportFolderStore.GetExisting() ?? await PdfExportFolderPicker.PickAsync();
        if (string.IsNullOrWhiteSpace(root))
        {
            await page.DisplayAlertAsync("Create PDFs", "No folder selected.", "OK");
            return;
        }

        PdfExportFolderStore.Set(root);

        var units = await CollectUniqueUnitsAsync(army);
        if (units.Count == 0)
        {
            await page.DisplayAlertAsync("Create PDFs", "Could not find a unit in this army.", "OK");
            return;
        }

        var pages = new List<UnitPdfPage>(units.Count);
        foreach (var profile in units)
        {
            pages.Add(new UnitPdfPage(
                profile,
                await LoadRuleEntriesAsync(UnitAndWeaponAbilities(profile)),
                await LoadRuleEntriesAsync(profile.PsychicPowers)));
        }

        var armyDir = Path.Combine(root, army.Name);
        Directory.CreateDirectory(armyDir);

        var path = Path.Combine(armyDir, WindowsFolderName.SanitizeFileName(army.Name) + ".pdf");
        try
        {
            UnitPdfWriter.Write(pages, path);
        }
        catch (IOException)
        {
            path = Path.Combine(
                armyDir,
                WindowsFolderName.SanitizeFileName(army.Name) + "-" + DateTime.Now.ToString("HHmmss") + ".pdf");
            UnitPdfWriter.Write(pages, path);
        }

        var openFolder = await page.DisplayAlertAsync("PDFs created", path, "Open folder", "OK");
        if (openFolder)
            OpenFolder(armyDir);
    }

    static async Task<IReadOnlyList<BaseProfile>> CollectUniqueUnitsAsync(ArmyDetail army)
    {
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var units = new List<BaseProfile>();

        foreach (var entry in army.Entries)
        {
            var roster = await DatabaseService.Instance.GetFormationRosterAsync(entry.FormationId);
            if (roster is null)
                continue;

            foreach (var row in DistinctBases(roster))
            {
                var titans = entry.Titans.Where(t => t.BaseName == row.BaseName).ToList();
                if (titans.Count == 0)
                {
                    await AddUnitAsync(units, seen, row, army.Id, entry.FormationId, titanIndex: null, titan: null);
                    continue;
                }

                foreach (var titan in titans)
                    await AddUnitAsync(units, seen, row, army.Id, entry.FormationId, titan.TitanIndex, titan);
            }
        }

        return units;
    }

    static IEnumerable<DetachmentBaseRow> DistinctBases(FormationRoster roster)
    {
        var seen = new HashSet<int>();
        foreach (var row in roster.Detachments.SelectMany(d => d.Bases))
        {
            if (seen.Add(row.BaseId))
                yield return row;
        }
    }

    static async Task AddUnitAsync(
        List<BaseProfile> units,
        HashSet<string> seen,
        DetachmentBaseRow row,
        int armyId,
        int formationId,
        int? titanIndex,
        ArmyTitanSlot? titan)
    {
        var key = UnitKey(row.BaseId, titan);
        if (!seen.Add(key))
            return;

        var profile = await DatabaseService.Instance.GetBaseProfileAsync(
            row.BaseId,
            row.DetachmentName,
            armyId,
            formationId,
            titanIndex);
        if (profile is not null)
            units.Add(profile);
    }

    static string UnitKey(int baseId, ArmyTitanSlot? titan)
    {
        if (titan is null || titan.Weapons.Count == 0)
            return $"{baseId}";

        var weapons = string.Join(",", titan.Weapons.Select(w => w.TitanWeaponId).OrderBy(id => id));
        return $"{baseId}:{weapons}";
    }

    static void OpenFolder(string folder)
    {
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = folder,
            UseShellExecute = true
        });
    }

    static IReadOnlyList<AbilityLink> UnitAndWeaponAbilities(BaseProfile profile)
    {
        var seen = new HashSet<int>();
        var links = new List<AbilityLink>();
        foreach (var link in profile.Abilities
                     .Concat(profile.Weapons.SelectMany(w => w.Abilities))
                     .Concat(profile.ChosenTitanWeapons.SelectMany(w => w.Abilities)))
        {
            if (seen.Add(link.Id))
                links.Add(link);
        }

        return links;
    }

    static async Task<IReadOnlyList<RuleListItem>> LoadRuleEntriesAsync(IReadOnlyList<AbilityLink> links)
    {
        var results = new List<RuleListItem>(links.Count);
        foreach (var link in links)
        {
            var rule = await CatalogCacheService.Instance.GetRuleAsync(link.Id, link.Kind);
            results.Add(new RuleListItem
            {
                Id = link.Id,
                Name = link.Name,
                Description = rule?.Description ?? string.Empty,
                Kind = link.Kind
            });
        }

        return results;
    }
}
