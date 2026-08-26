using Baguettepic.Models;
using Baguettepic.Services;
using MySqlConnector;

namespace Baguettepic.Pages;

[QueryProperty(nameof(ArmyId), "id")]
public partial class ArmyBuilderPage : ContentPage
{
    int _armyId;
    int _codexId;
    int _pointsLimit;

    public ArmyBuilderPage()
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

    async Task LoadAsync()
    {
        try
        {
            SetBusy(true);
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

            _codexId = army.CodexId;
            _pointsLimit = army.PointsLimit;
            Title = army.Name;
            NameLabel.Text = army.Name;
            SummaryLabel.Text = army.Summary;
            BindFactionRules(army.SpecialRules);
            if (army.PointsCost > army.PointsLimit)
                SummaryLabel.TextColor = Colors.IndianRed;
            else
                SummaryLabel.ClearValue(Label.TextColorProperty);
            EntriesList.ItemsSource = army.Entries;
            StatusLabel.ClearValue(Label.TextColorProperty);
            StatusLabel.Text = army.Entries.Count == 0
                ? "Empty list"
                : army.Entries.Count == 1 ? "1 formation" : $"{army.Entries.Count} formations";
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not load this army.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            SetBusy(false);
        }
    }

    void OnEditClicked(object? sender, EventArgs e)
    {
        EditErrorLabel.IsVisible = false;
        EditNameEntry.Text = NameLabel.Text;
        EditPointsEntry.Text = _pointsLimit.ToString();
        EditOverlay.IsVisible = true;
        EditNameEntry.Focus();
    }

    void OnEditCancelClicked(object? sender, EventArgs e) =>
        EditOverlay.IsVisible = false;

    async void OnEditSaveClicked(object? sender, EventArgs e)
    {
        EditErrorLabel.IsVisible = false;
        var name = EditNameEntry.Text?.Trim() ?? string.Empty;
        if (name.Length == 0)
        {
            EditErrorLabel.Text = "Enter a name.";
            EditErrorLabel.IsVisible = true;
            return;
        }

        if (!int.TryParse(EditPointsEntry.Text, out var pointsLimit) || pointsLimit <= 0)
        {
            EditErrorLabel.Text = "Enter a max points value greater than 0.";
            EditErrorLabel.IsVisible = true;
            return;
        }

        try
        {
            await DatabaseService.Instance.UpdateArmyAsync(_armyId, name, pointsLimit);
            EditOverlay.IsVisible = false;
            await LoadAsync();
        }
        catch (MySqlException ex) when (ex.ErrorCode == MySqlErrorCode.DuplicateKeyEntry)
        {
            EditErrorLabel.Text = "An army with that name already exists.";
            EditErrorLabel.IsVisible = true;
        }
        catch (Exception ex)
        {
            EditErrorLabel.Text = "Could not save the army.";
            EditErrorLabel.IsVisible = true;
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async void OnAddFormationClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync($"FormationPicker?armyId={_armyId}&codexId={_codexId}");

    async void OnPlusClicked(object? sender, EventArgs e)
    {
        if (EntryFrom(sender) is { } entry)
            await ChangeQuantityAsync(entry, entry.Quantity + 1);
    }

    async void OnMinusClicked(object? sender, EventArgs e)
    {
        if (EntryFrom(sender) is { } entry)
            await ChangeQuantityAsync(entry, entry.Quantity - 1);
    }

    async void OnRemoveClicked(object? sender, EventArgs e)
    {
        if (EntryFrom(sender) is { } entry)
            await ChangeQuantityAsync(entry, 0);
    }

    async void OnBasesClicked(object? sender, EventArgs e)
    {
        if (EntryFrom(sender) is not { } entry)
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

    async void OnAddWeaponClicked(object? sender, EventArgs e)
    {
        if (sender is not BindableObject bindable || bindable.BindingContext is not ArmyTitanSlot slot)
            return;

        await Shell.Current.GoToAsync(
            $"TitanWeaponPicker?armyId={_armyId}&codexId={_codexId}&formationId={slot.FormationId}&titanIndex={slot.TitanIndex}");
    }

    async void OnRemoveWeaponClicked(object? sender, EventArgs e)
    {
        if (sender is not BindableObject bindable || bindable.BindingContext is not ArmyTitanWeaponItem weapon)
            return;

        try
        {
            await DatabaseService.Instance.RemoveArmyTitanWeaponAsync(_armyId, weapon.FormationId, weapon.Id);
            await LoadAsync();
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not remove that weapon.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task ChangeQuantityAsync(ArmyEntry entry, int quantity)
    {
        try
        {
            await DatabaseService.Instance.SetArmyFormationQuantityAsync(_armyId, entry.FormationId, quantity);
            await LoadAsync();
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not update the army.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    static ArmyEntry? EntryFrom(object? sender) =>
        sender is BindableObject bindable ? bindable.BindingContext as ArmyEntry : null;

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

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
