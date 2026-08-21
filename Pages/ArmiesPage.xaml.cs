using System.Collections.ObjectModel;
using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

public partial class ArmiesPage : ContentPage
{
    readonly ObservableCollection<ArmyListItem> _armies = [];

    public ArmiesPage()
    {
        InitializeComponent();
        ArmiesList.ItemsSource = _armies;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadAsync();
    }

    async void OnArmyTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not ArmyListItem item)
            return;

        await Shell.Current.GoToAsync($"ArmyDetail?id={item.Id}");
    }

    async Task LoadAsync()
    {
        try
        {
            SetBusy(true);
            StatusLabel.Text = "Loading…";
            var results = await DatabaseService.Instance.GetArmiesAsync();

            _armies.Clear();
            foreach (var army in results)
                _armies.Add(army);

            StatusLabel.ClearValue(Label.TextColorProperty);
            StatusLabel.Text = results.Count == 1 ? "1 army" : $"{results.Count} armies";
        }
        catch (Exception ex)
        {
            _armies.Clear();
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not load armies. Check the database connection.";
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
