using System.Collections.ObjectModel;
using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

public partial class RulesPage : ContentPage
{
    readonly ObservableCollection<object> _rows = [];
    CancellationTokenSource? _searchCts;

    public RulesPage()
    {
        InitializeComponent();
        RulesList.ItemsSource = _rows;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        AddNewButton.IsVisible = SessionService.Instance.IsAdmin;
        await SearchAsync(SearchEntry.Text);
        SearchFieldFocus.FocusAndSelect(SearchEntry);
    }

    protected override void OnDisappearing()
    {
        _searchCts?.Cancel();
        base.OnDisappearing();
    }

    async void OnAddNewClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("RuleEdit");

    async void OnRuleTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not RuleListItem item)
            return;

        await Shell.Current.GoToAsync($"RuleDetail?id={item.Id}&kind={Uri.EscapeDataString(item.Kind)}");
    }

    async void OnSearchTextChanged(object? sender, TextChangedEventArgs e)
    {
        await SearchAsync(e.NewTextValue);
    }

    async Task SearchAsync(string? query)
    {
        _searchCts?.Cancel();
        _searchCts = new CancellationTokenSource();
        var token = _searchCts.Token;

        try
        {
            await Task.Delay(200, token);
            var term = (query ?? string.Empty).Trim();

            SetBusy(true);
            StatusLabel.ClearValue(Label.TextColorProperty);
            StatusLabel.Text = term.Length == 0 ? "Loading…" : "Searching names…";

            var nameResults = await CatalogCacheService.Instance.SearchRulesByNameAsync(query, token);
            token.ThrowIfCancellationRequested();

            _rows.Clear();
            foreach (var row in nameResults)
                _rows.Add(row);

            SetStatus(nameResults.Count, term, searchingDescriptions: false);
            SetBusy(false);

            if (term.Length == 0)
                return;

            StatusLabel.Text = FormatStatus(nameResults.Count, term, searchingDescriptions: true);
            var descriptionResults = await CatalogCacheService.Instance.SearchRulesByDescriptionAsync(
                term,
                nameResults,
                token);
            token.ThrowIfCancellationRequested();

            if (descriptionResults.Count > 0)
            {
                if (nameResults.Count > 0)
                    _rows.Add(RuleSearchDivider.Instance);

                foreach (var row in descriptionResults)
                    _rows.Add(row);
            }

            SetStatus(nameResults.Count + descriptionResults.Count, term, searchingDescriptions: false);
        }
        catch (OperationCanceledException)
        {
            // A newer search replaced this one.
        }
        catch (Exception ex)
        {
            _rows.Clear();
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not load rules. Check the database connection.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            if (!token.IsCancellationRequested)
                SetBusy(false);
        }
    }

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }

    void SetStatus(int count, string term, bool searchingDescriptions) =>
        StatusLabel.Text = FormatStatus(count, term, searchingDescriptions);

    static string FormatStatus(int count, string term, bool searchingDescriptions)
    {
        if (term.Length == 0)
            return count == 1 ? "1 rule" : $"{count} rules";

        var summary = count == 1 ? "1 matching rule" : $"{count} matching rules";
        return searchingDescriptions ? $"{summary} — searching descriptions…" : summary;
    }
}
