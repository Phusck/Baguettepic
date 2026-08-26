using Baguettepic.Services;

namespace Baguettepic.Pages;

public partial class ChangePasswordPage : ContentPage
{
    public ChangePasswordPage()
    {
        InitializeComponent();
    }

    async void OnSaveClicked(object? sender, EventArgs e)
    {
        ErrorLabel.IsVisible = false;
        var password = PasswordEntry.Text ?? string.Empty;
        if (password.Length == 0)
        {
            ShowError("Enter a new password.");
            return;
        }

        if (string.Equals(password, SessionService.StandardPassword, StringComparison.OrdinalIgnoreCase))
        {
            ShowError("Choose a different password.");
            return;
        }

        try
        {
            await DatabaseService.Instance.ChangePasswordAsync(password);
            SessionService.Instance.MarkPasswordChanged();
            await SessionService.Instance.RememberPasswordAsync(password);
            await Shell.Current.GoToAsync("//MainMenu");
        }
        catch (Exception ex)
        {
            ShowError("Could not save the password.");
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async void OnLogoutClicked(object? sender, EventArgs e)
    {
        SessionService.Instance.Logout();
        await Shell.Current.GoToAsync("//Login");
    }

    void ShowError(string message)
    {
        ErrorLabel.Text = message;
        ErrorLabel.IsVisible = true;
    }
}
