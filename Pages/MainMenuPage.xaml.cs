using Baguettepic.Services;

namespace Baguettepic.Pages;

public partial class MainMenuPage : ContentPage
{
    public MainMenuPage()
    {
        InitializeComponent();
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        var user = SessionService.Instance.CurrentUser;
        RoleLabel.Text = user is null ? "Signed in" : $"Signed in as {user.Username}";
        AddUserButton.IsVisible = SessionService.Instance.IsAdmin;
    }

    async void OnRulesClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("Rules");

    async void OnCreateArmyClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("CreateArmy");

    async void OnLoadArmyClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("Armies");

    async void OnAddUserClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("AddUser");

    async void OnLogoutClicked(object? sender, EventArgs e)
    {
        SessionService.Instance.Logout();
        await Shell.Current.GoToAsync("//Login");
    }
}
