using System.Collections.ObjectModel;
using Baguettepic.Models;
using Baguettepic.Services;
using MySqlConnector;

namespace Baguettepic.Pages;

public partial class CreateArmyPage : ContentPage
{
    readonly ObservableCollection<CodexOption> _visible = [];
    IReadOnlyList<CodexOption> _all = [];
    CodexOption? _selected;

    public CreateArmyPage()
    {
        InitializeComponent();
        CodexList.ItemsSource = _visible;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadCodicesAsync();
    }

    async Task LoadCodicesAsync()
    {
        try
        {
            _all = await DatabaseService.Instance.GetCodicesAsync();
            if (_selected is null && _all.Count > 0)
                _selected = _all[0];
            else if (_selected is not null)
                _selected = _all.FirstOrDefault(c => c.Id == _selected.Id) ?? _all.FirstOrDefault();

            ApplyFilter(CodexFilterEntry.Text);
        }
        catch (Exception ex)
        {
            ErrorLabel.Text = "Could not load Codexes. Check the database connection.";
            ErrorLabel.IsVisible = true;
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    void OnCodexFilterTextChanged(object? sender, TextChangedEventArgs e) =>
        ApplyFilter(e.NewTextValue);

    void ApplyFilter(string? query)
    {
        var term = (query ?? string.Empty).Trim();
        IEnumerable<CodexOption> matches = _all;
        if (term.Length > 0)
        {
            matches = _all.Where(c =>
                c.Name.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        _visible.Clear();
        foreach (var item in matches)
            _visible.Add(item);

        CodexList.SelectedItem = _visible.FirstOrDefault(c => c.Id == _selected?.Id);
    }

    void OnCodexSelectionChanged(object? sender, SelectionChangedEventArgs e)
    {
        if (e.CurrentSelection.FirstOrDefault() is CodexOption codex)
            _selected = codex;
    }

    async void OnCreateClicked(object? sender, EventArgs e)
    {
        ErrorLabel.IsVisible = false;
        var name = NameEntry.Text?.Trim() ?? string.Empty;
        if (name.Length == 0)
        {
            ErrorLabel.Text = "Enter a name.";
            ErrorLabel.IsVisible = true;
            return;
        }

        if (_selected is null)
        {
            ErrorLabel.Text = "Choose a Codex.";
            ErrorLabel.IsVisible = true;
            return;
        }

        if (!int.TryParse(PointsEntry.Text, out var pointsLimit) || pointsLimit <= 0)
        {
            ErrorLabel.Text = "Enter a points limit greater than 0.";
            ErrorLabel.IsVisible = true;
            return;
        }

        try
        {
            var id = await DatabaseService.Instance.CreateArmyAsync(name, _selected.Id, pointsLimit);
            await Shell.Current.GoToAsync($"ArmyBuilder?id={id}");
        }
        catch (MySqlException ex) when (ex.ErrorCode == MySqlErrorCode.DuplicateKeyEntry)
        {
            ErrorLabel.Text = "An army with that name already exists.";
            ErrorLabel.IsVisible = true;
        }
        catch (Exception ex)
        {
            ErrorLabel.Text = "Could not create the army.";
            ErrorLabel.IsVisible = true;
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }
}
