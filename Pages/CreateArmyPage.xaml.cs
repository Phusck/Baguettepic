using Baguettepic.Models;
using Baguettepic.Services;
using MySqlConnector;

namespace Baguettepic.Pages;

public partial class CreateArmyPage : ContentPage
{
    public CreateArmyPage()
    {
        InitializeComponent();
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
            var codices = await DatabaseService.Instance.GetCodicesAsync();
            CodexPicker.ItemsSource = codices.ToList();
            if (CodexPicker.SelectedIndex < 0 && codices.Count > 0)
                CodexPicker.SelectedIndex = 0;
        }
        catch (Exception ex)
        {
            ErrorLabel.Text = "Could not load Codexes. Check the database connection.";
            ErrorLabel.IsVisible = true;
            System.Diagnostics.Debug.WriteLine(ex);
        }
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

        if (CodexPicker.SelectedItem is not CodexOption codex)
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
            var id = await DatabaseService.Instance.CreateArmyAsync(name, codex.Id, pointsLimit, string.Empty);
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
