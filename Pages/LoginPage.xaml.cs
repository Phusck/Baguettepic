using Baguettepic.Services;

namespace Baguettepic.Pages;

public partial class LoginPage : ContentPage
{
    public LoginPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        var (username, password) = await SessionService.Instance.LoadRememberedAsync();
        UsernameEntry.Text = username;
        PasswordEntry.Text = password;
        ErrorLabel.IsVisible = false;
    }

    void OnUsernameCompleted(object? sender, EventArgs e) =>
        PasswordEntry.Focus();

    async void OnLoginClicked(object? sender, EventArgs e)
    {
        ErrorLabel.IsVisible = false;

        var error = await SessionService.Instance.TryLoginAsync(
            UsernameEntry.Text, PasswordEntry.Text);
        if (error is not null)
        {
            ErrorLabel.Text = error;
            ErrorLabel.IsVisible = true;
            return;
        }

        if (SessionService.Instance.MustChangePassword)
            await Shell.Current.GoToAsync("//ChangePassword");
        else
            await Shell.Current.GoToAsync("//MainMenu");
    }
}
