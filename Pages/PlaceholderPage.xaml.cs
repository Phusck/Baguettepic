namespace Baguettepic.Pages;

[QueryProperty(nameof(FeatureName), "title")]
public partial class PlaceholderPage : ContentPage
{
    public PlaceholderPage()
    {
        InitializeComponent();
    }

    public string FeatureName
    {
        get => Title;
        set
        {
            Title = value;
            MessageLabel.Text = $"{value} will be added later.";
        }
    }
}
