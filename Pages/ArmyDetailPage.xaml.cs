using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(ArmyId), "id")]
public partial class ArmyDetailPage : ContentPage
{
    int _armyId;

    public ArmyDetailPage()
    {
        InitializeComponent();
    }

    public string ArmyId
    {
        get => _armyId.ToString();
        set
        {
            if (int.TryParse(value, out var id))
                _armyId = id;
        }
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadAsync();
    }

    async void OnEditClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync($"ArmyBuilder?id={_armyId}");

    async void OnEntryTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not ArmyEntry entry)
            return;

        try
        {
            await FormationNavigation.OpenAsync(entry.FormationId, _armyId, TitanIndexFor(entry));
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not open that formation.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async void OnTitanTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not ArmyTitanSlot slot)
            return;

        try
        {
            await FormationNavigation.OpenAsync(slot.FormationId, _armyId, slot.TitanIndex);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not open that titan.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async void OnWeaponTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not ArmyTitanWeaponItem weapon)
            return;

        try
        {
            await FormationNavigation.OpenTitanWeaponAsync(weapon.TitanWeaponId, weapon.FormationId);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not open that weapon.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    static int? TitanIndexFor(ArmyEntry entry) =>
        entry.Titans.Count == 1 ? entry.Titans[0].TitanIndex : null;

    void BindFactionRules(IReadOnlyList<AbilityLink> rules)
    {
        FactionAbilitiesLayout.Children.Clear();
        foreach (var rule in rules)
        {
            var button = new Button
            {
                Text = rule.Name,
                Style = (Style)Resources["ChipButton"],
                BindingContext = rule,
                Margin = new Thickness(0, 0, 8, 8)
            };
            button.Clicked += OnFactionRuleClicked;
            FactionAbilitiesLayout.Children.Add(button);
        }

        FactionAbilitiesHost.IsVisible = rules.Count > 0;
    }

    async void OnFactionRuleClicked(object? sender, EventArgs e)
    {
        if (sender is not Button { BindingContext: AbilityLink rule })
            return;

        await Shell.Current.GoToAsync($"RuleDetail?id={rule.Id}&kind={Uri.EscapeDataString(rule.Kind)}");
    }

    async Task LoadAsync()
    {
        try
        {
            SetBusy(true);
            StatusLabel.Text = "Loading…";
            var army = await DatabaseService.Instance.GetArmyAsync(_armyId);
            if (army is null)
            {
                NameLabel.Text = "Army not found";
                SummaryLabel.Text = string.Empty;
                BindFactionRules([]);
                EntriesList.ItemsSource = null;
                StatusLabel.Text = string.Empty;
                return;
            }

            Title = army.Name;
            NameLabel.Text = army.Name;
            SummaryLabel.Text = army.Summary;
            BindFactionRules(army.SpecialRules);
            EntriesList.ItemsSource = army.Entries;
            StatusLabel.ClearValue(Label.TextColorProperty);
            StatusLabel.Text = army.Entries.Count == 1 ? "1 formation" : $"{army.Entries.Count} formations";
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not load this army. Check the database connection.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            SetBusy(false);
        }
    }

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
