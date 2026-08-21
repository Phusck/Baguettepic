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

        var (role, password) = await SessionService.Instance.LoadRememberedAsync();
        AdminRadio.IsChecked = role == UserRole.Admin;
        GuestRadio.IsChecked = role == UserRole.Guest;
        PasswordEntry.Text = password;
        ErrorLabel.IsVisible = false;
        UpdatePasswordVisibility();
    }

    void OnRoleChanged(object? sender, CheckedChangedEventArgs e)
    {
        if (e.Value)
            UpdatePasswordVisibility();
    }

    void UpdatePasswordVisibility()
    {
        PasswordSection.IsVisible = AdminRadio.IsChecked;
    }

    async void OnLoginClicked(object? sender, EventArgs e)
    {
        ErrorLabel.IsVisible = false;

        var role = AdminRadio.IsChecked ? UserRole.Admin : UserRole.Guest;
        var error = await SessionService.Instance.TryLoginAsync(role, PasswordEntry.Text);
        if (error is not null)
        {
            ErrorLabel.Text = error;
            ErrorLabel.IsVisible = true;
            return;
        }

        await Shell.Current.GoToAsync("//MainMenu");
    }
}
