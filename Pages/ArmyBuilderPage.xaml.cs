using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(ArmyId), "id")]
public partial class ArmyBuilderPage : ContentPage
{
    int _armyId;
    int _codexId;

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
                EntriesList.ItemsSource = null;
                StatusLabel.Text = string.Empty;
                return;
            }

            _codexId = army.CodexId;
            Title = army.Name;
            NameLabel.Text = army.Name;
            SummaryLabel.Text = army.Summary;
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

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
