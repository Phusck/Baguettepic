using Baguettepic.Services;
using MySqlConnector;

namespace Baguettepic.Pages;

public partial class AddUserPage : ContentPage
{
    public AddUserPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        if (!SessionService.Instance.IsAdmin)
        {
            await DisplayAlertAsync("Admin only", "Only an admin can add users.", "OK");
            await Shell.Current.GoToAsync("..");
            return;
        }
    }

    async void OnAddClicked(object? sender, EventArgs e)
    {
        StatusLabel.IsVisible = false;
        var username = UsernameEntry.Text?.Trim() ?? string.Empty;
        if (username.Length == 0)
        {
            ShowStatus("Enter a username.", Colors.IndianRed);
            return;
        }

        try
        {
            await DatabaseService.Instance.CreateUserAsync(username);
            UsernameEntry.Text = string.Empty;
            ShowStatus($"{username} can now log in.", null);
        }
        catch (MySqlException ex) when (ex.ErrorCode == MySqlErrorCode.DuplicateKeyEntry)
        {
            ShowStatus("That username is already taken.", Colors.IndianRed);
        }
        catch (Exception ex)
        {
            ShowStatus("Could not add that user.", Colors.IndianRed);
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    void ShowStatus(string message, Color? color)
    {
        if (color is Color textColor)
            StatusLabel.TextColor = textColor;
        else
            StatusLabel.ClearValue(Label.TextColorProperty);
        StatusLabel.Text = message;
        StatusLabel.IsVisible = true;
    }
}
