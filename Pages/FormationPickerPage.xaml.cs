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
    CancellationTokenSource? _toastCts;

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

    protected override void OnDisappearing()
    {
        _toastCts?.Cancel();
        _toastCts?.Dispose();
        _toastCts = null;
        base.OnDisappearing();
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
            SearchFieldFocus.FocusAndSelect(SearchEntry);
        }
    }

    void OnSearchTextChanged(object? sender, TextChangedEventArgs e) =>
        ApplyFilter(e.NewTextValue);

    async void OnSearchCompleted(object? sender, EventArgs e)
    {
        if (_visible.Count != 1)
            return;

        await AddFormationAsync(_visible[0]);
    }

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
            await FormationNavigation.OpenAsync(formation.Id);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not open that formation.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async void OnAddClicked(object? sender, EventArgs e)
    {
        if (sender is not BindableObject bindable || bindable.BindingContext is not FormationOption formation)
            return;

        await AddFormationAsync(formation);
    }

    async Task AddFormationAsync(FormationOption formation)
    {
        try
        {
            var army = await DatabaseService.Instance.GetArmyAsync(_armyId);
            var current = army?.Entries.FirstOrDefault(x => x.FormationId == formation.Id);
            var quantity = (current?.Quantity ?? 0) + 1;
            await DatabaseService.Instance.SetArmyFormationQuantityAsync(_armyId, formation.Id, quantity);
            SearchFieldFocus.FocusAndSelect(SearchEntry);
            await ShowAddedToastAsync(formation.Name);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not add that formation.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task ShowAddedToastAsync(string formationName)
    {
        _toastCts?.Cancel();
        _toastCts?.Dispose();
        _toastCts = new CancellationTokenSource();
        var token = _toastCts.Token;

        AddedToastLabel.Text = $"{formationName} added";
        AddedToast.CancelAnimations();
        AddedToast.Opacity = 1;
        AddedToast.IsVisible = true;

        try
        {
            await Task.Delay(1000, token);
            await AddedToast.FadeTo(0, 120);
            if (!token.IsCancellationRequested)
                AddedToast.IsVisible = false;
        }
        catch (TaskCanceledException)
        {
        }
    }

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
