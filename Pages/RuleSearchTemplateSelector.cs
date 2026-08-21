using Baguettepic.Models;

namespace Baguettepic.Pages;

public sealed class RuleSearchTemplateSelector : DataTemplateSelector
{
    public DataTemplate RuleTemplate { get; set; } = null!;
    public DataTemplate DividerTemplate { get; set; } = null!;

    protected override DataTemplate OnSelectTemplate(object item, BindableObject container) =>
        item is RuleSearchDivider ? DividerTemplate : RuleTemplate;
}
