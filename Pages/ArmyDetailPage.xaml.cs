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
            await FormationNavigation.OpenAsync(entry.FormationId);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not open that formation.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
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
                NotesLabel.Text = string.Empty;
                EntriesList.ItemsSource = null;
                StatusLabel.Text = string.Empty;
                return;
            }

            Title = army.Name;
            NameLabel.Text = army.Name;
            SummaryLabel.Text = army.Summary;
            NotesLabel.Text = army.Notes;
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
