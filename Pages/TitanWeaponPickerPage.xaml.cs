using System.Collections.ObjectModel;
using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(ArmyId), "armyId")]
[QueryProperty(nameof(CodexId), "codexId")]
[QueryProperty(nameof(FormationId), "formationId")]
[QueryProperty(nameof(TitanIndex), "titanIndex")]
public partial class TitanWeaponPickerPage : ContentPage
{
    readonly ObservableCollection<TitanWeaponOption> _visible = [];
    IReadOnlyList<TitanWeaponOption> _all = [];
    int _armyId;
    int _codexId;
    int _formationId;
    int _titanIndex;
    CancellationTokenSource? _toastCts;

    public TitanWeaponPickerPage()
    {
        InitializeComponent();
        WeaponsList.ItemsSource = _visible;
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

    public string FormationId
    {
        get => _formationId.ToString();
        set => int.TryParse(value, out _formationId);
    }

    public string TitanIndex
    {
        get => _titanIndex.ToString();
        set => int.TryParse(value, out _titanIndex);
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
            _all = await DatabaseService.Instance.GetTitanWeaponsAsync(_codexId);
            ApplyFilter(SearchEntry.Text);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not load titan weapons.";
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

        await AddWeaponAsync(_visible[0]);
    }

    void ApplyFilter(string? query)
    {
        var term = (query ?? string.Empty).Trim();
        IEnumerable<TitanWeaponOption> matches = _all;
        if (term.Length > 0)
        {
            matches = _all.Where(w =>
                w.Name.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                w.Notes.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var list = matches.ToList();
        _visible.Clear();
        foreach (var item in list)
            _visible.Add(item);

        StatusLabel.ClearValue(Label.TextColorProperty);
        StatusLabel.Text = list.Count == 1 ? "1 weapon" : $"{list.Count} weapons";
    }

    async void OnAddClicked(object? sender, EventArgs e)
    {
        if (sender is not BindableObject bindable || bindable.BindingContext is not TitanWeaponOption weapon)
            return;

        await AddWeaponAsync(weapon);
    }

    async void OnWeaponTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not TitanWeaponOption weapon)
            return;

        try
        {
            await FormationNavigation.OpenTitanWeaponAsync(weapon.Id, _formationId);
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not open that weapon.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task AddWeaponAsync(TitanWeaponOption weapon)
    {
        try
        {
            await DatabaseService.Instance.AddArmyTitanWeaponAsync(
                _armyId, _formationId, _titanIndex, weapon.Id);
            SearchFieldFocus.FocusAndSelect(SearchEntry);
            await ShowAddedToastAsync(weapon.Name);
            StatusLabel.ClearValue(Label.TextColorProperty);
            StatusLabel.Text = _visible.Count == 1 ? "1 weapon" : $"{_visible.Count} weapons";
        }
        catch (InvalidOperationException ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = ex.Message;
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not add that weapon.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task ShowAddedToastAsync(string weaponName)
    {
        _toastCts?.Cancel();
        _toastCts?.Dispose();
        _toastCts = new CancellationTokenSource();
        var token = _toastCts.Token;

        AddedToastLabel.Text = $"{weaponName} added";
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
