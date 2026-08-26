using Baguettepic.Pages;
using Baguettepic.Services;

namespace Baguettepic;

public partial class AppShell : Shell
{
    public AppShell()
    {
        InitializeComponent();
        Routing.RegisterRoute("Placeholder", typeof(PlaceholderPage));
        Routing.RegisterRoute("Rules", typeof(RulesPage));
        Routing.RegisterRoute("RuleDetail", typeof(RuleDetailPage));
        Routing.RegisterRoute("RuleEdit", typeof(RuleEditPage));
        Routing.RegisterRoute("Armies", typeof(ArmiesPage));
        Routing.RegisterRoute("ArmyDetail", typeof(ArmyDetailPage));
        Routing.RegisterRoute("CreateArmy", typeof(CreateArmyPage));
        Routing.RegisterRoute("ArmyBuilder", typeof(ArmyBuilderPage));
        Routing.RegisterRoute("FormationPicker", typeof(FormationPickerPage));
        Routing.RegisterRoute("TitanWeaponPicker", typeof(TitanWeaponPickerPage));
        Routing.RegisterRoute("TitanWeaponDetail", typeof(TitanWeaponDetailPage));
        Routing.RegisterRoute("FormationDetachments", typeof(FormationDetachmentsPage));
        Routing.RegisterRoute("BaseDetail", typeof(BaseDetailPage));
        Routing.RegisterRoute("AddUser", typeof(AddUserPage));
        Navigating += OnNavigating;
    }

    void OnNavigating(object? sender, ShellNavigatingEventArgs e)
    {
        if (!SessionService.Instance.MustChangePassword)
            return;

        var target = e.Target.Location.OriginalString;
        if (target.Contains("ChangePassword", StringComparison.OrdinalIgnoreCase) ||
            target.Contains("Login", StringComparison.OrdinalIgnoreCase))
            return;

        e.Cancel();
        Dispatcher.Dispatch(() => _ = GoToAsync("//ChangePassword"));
    }
}
