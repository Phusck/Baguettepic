using System.Collections.ObjectModel;
using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(ArmyId), "armyId")]
[QueryProperty(nameof(CodexId), "codexId")]
public partial class FormationPickerPage : ContentPage
{
    readonly ObservableCollection<FormationOption> _visible = [];
    IReadOnlyList<FormationOption> _all = [];
    int _armyId;
    int _codexId;

    public FormationPickerPage()
    {
        InitializeComponent();
        FormationsList.ItemsSource = _visible;
    }

    public string ArmyId
    {
        get => _armyId.ToString();
        set => int.TryParse(value, out _armyId);
    }

    public string CodexId
    {
        get => _codexId.ToString();
        set => int.TryParse(value, out _codexId);
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
            _all = await DatabaseService.Instance.GetPurchasableFormationsAsync(_codexId);
            ApplyFilter(SearchEntry.Text);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not load formations.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            SetBusy(false);
        }
    }

    void OnSearchTextChanged(object? sender, TextChangedEventArgs e) =>
        ApplyFilter(e.NewTextValue);

    void ApplyFilter(string? query)
    {
        var term = (query ?? string.Empty).Trim();
        IEnumerable<FormationOption> matches = _all;
        if (term.Length > 0)
        {
            matches = _all.Where(f =>
                f.Name.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                f.KindName.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                f.Contents.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var list = matches.ToList();
        _visible.Clear();
        foreach (var item in list)
            _visible.Add(item);

        StatusLabel.ClearValue(Label.TextColorProperty);
        StatusLabel.Text = list.Count == 1 ? "1 formation" : $"{list.Count} formations";
    }

    async void OnFormationTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not FormationOption formation)
            return;

        try
        {
            var army = await DatabaseService.Instance.GetArmyAsync(_armyId);
            var current = army?.Entries.FirstOrDefault(x => x.FormationId == formation.Id);
            var quantity = (current?.Quantity ?? 0) + 1;
            await DatabaseService.Instance.SetArmyFormationQuantityAsync(_armyId, formation.Id, quantity);
            await Shell.Current.GoToAsync("..");
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not add that formation.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
