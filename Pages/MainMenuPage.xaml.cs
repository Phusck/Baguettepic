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
        RoleLabel.Text = SessionService.Instance.CurrentRole switch
        {
            UserRole.Admin => "Signed in as Admin",
            UserRole.Guest => "Signed in as Guest",
            _ => "Signed in"
        };
    }

    async void OnRulesClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("Rules");

    async void OnCreateArmyClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("CreateArmy");

    async void OnLoadArmyClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("Armies");

    async void OnLogoutClicked(object? sender, EventArgs e)
    {
        SessionService.Instance.Logout();
        await Shell.Current.GoToAsync("//Login");
    }
}
