using Baguettepic.Pages;

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
    }
}
