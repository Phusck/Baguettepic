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
            SetBusy(true);
            StatusLabel.Text = "Searching…";
            var results = await DatabaseService.Instance.SearchRulesAsync(query, token);
            token.ThrowIfCancellationRequested();

            _rows.Clear();
            foreach (var row in BuildRows(results, query))
                _rows.Add(row);

            StatusLabel.ClearValue(Label.TextColorProperty);
            var filter = string.IsNullOrWhiteSpace(query) ? "all rules" : "matching rules";
            StatusLabel.Text = results.Count == 1 ? $"1 {filter.TrimEnd('s')}" : $"{results.Count} {filter}";
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

    static IEnumerable<object> BuildRows(IReadOnlyList<RuleListItem> results, string? query)
    {
        var term = (query ?? string.Empty).Trim();
        if (term.Length == 0)
            return results;

        var nameMatches = new List<RuleListItem>();
        var descriptionMatches = new List<RuleListItem>();
        foreach (var rule in results)
        {
            if (rule.Name.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                ParameterizedName.Matches(rule.Name, term))
                nameMatches.Add(rule);
            else
                descriptionMatches.Add(rule);
        }

        if (nameMatches.Count == 0 || descriptionMatches.Count == 0)
            return nameMatches.Count > 0 ? nameMatches : descriptionMatches;

        var rows = new List<object>(nameMatches.Count + descriptionMatches.Count + 1);
        rows.AddRange(nameMatches);
        rows.Add(RuleSearchDivider.Instance);
        rows.AddRange(descriptionMatches);
        return rows;
    }
}
