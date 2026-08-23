using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(BaseId), "baseId")]
[QueryProperty(nameof(DetachmentName), "detachmentName")]
public partial class BaseDetailPage : ContentPage
{
    int _baseId;
    string? _detachmentName;

    public BaseDetailPage()
    {
        InitializeComponent();
    }

    public string BaseId
    {
        get => _baseId.ToString();
        set => int.TryParse(value, out _baseId);
    }

    public string DetachmentName
    {
        get => _detachmentName ?? string.Empty;
        set => _detachmentName = string.IsNullOrWhiteSpace(value) ? null : Uri.UnescapeDataString(value);
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadAsync();
    }

    async void OnBackClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("..");

    async Task LoadAsync()
    {
        try
        {
            SetBusy(true);
            var profile = await DatabaseService.Instance.GetBaseProfileAsync(_baseId, _detachmentName);
            if (profile is null)
            {
                ContentHost.IsVisible = true;
                NameLabel.Text = "Base not found";
                DetachmentLabel.IsVisible = false;
                return;
            }

            Title = profile.Name;
            NameLabel.Text = profile.Name;
            DetachmentLabel.Text = profile.DetachmentName ?? string.Empty;
            DetachmentLabel.IsVisible = !string.IsNullOrWhiteSpace(profile.DetachmentName);

            if (profile.HasImage)
            {
                BaseImage.Source = profile.Image;
                BaseImage.IsVisible = true;
                ImagePlaceholder.IsVisible = false;
            }
            else
            {
                BaseImage.Source = null;
                BaseImage.IsVisible = false;
                ImagePlaceholder.IsVisible = true;
            }

            MoveValue.Text = profile.MoveText;
            SaveValue.Text = profile.Save;
            AfValue.Text = profile.AfText;
            MoraleValue.Text = profile.MoraleText;
            ClassValue.Text = profile.ClassText;
            DpValue.Text = profile.DestructionText;

            BindAbilities(AbilitiesLayout, profile.Abilities);
            AbilitiesHost.IsVisible = profile.HasAbilities;

            WeaponsHost.Children.Clear();
            foreach (var weapon in profile.Weapons)
                WeaponsHost.Children.Add(CreateWeaponView(weapon));

            ContentHost.IsVisible = true;
        }
        catch (Exception ex)
        {
            ContentHost.IsVisible = true;
            ErrorLabel.IsVisible = true;
            ErrorLabel.Text = "Could not load this base.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            SetBusy(false);
        }
    }

    View CreateWeaponView(WeaponProfile weapon)
    {
        var header = new Grid
        {
            ColumnDefinitions = Columns(5),
            BackgroundColor = ThemeColor("Gold", "Primary")
        };
        AddHeader(header, 0, "Range");
        AddHeader(header, 1, "Dice");
        AddHeader(header, 2, "To Hit");
        AddHeader(header, 3, "AP");
        AddHeader(header, 4, "Arc");

        var values = new Grid
        {
            ColumnDefinitions = Columns(5),
            BackgroundColor = ThemeColor("Gray600", "Gray100")
        };
        AddValue(values, 0, weapon.Range);
        AddValue(values, 1, weapon.DiceText);
        AddValue(values, 2, weapon.ToHit);
        AddValue(values, 3, weapon.ApText);
        AddValue(values, 4, weapon.ArcText);

        var table = new Border { StrokeThickness = 1 };
        table.Content = new VerticalStackLayout { Spacing = 0, Children = { header, values } };

        var block = new VerticalStackLayout { Spacing = 8 };
        block.Children.Add(new Label
        {
            Text = weapon.Name,
            Style = (Style)Application.Current!.Resources["Title"],
            FontSize = 18
        });
        block.Children.Add(table);

        if (weapon.HasAbilities)
        {
            var chips = new FlexLayout
            {
                Wrap = Microsoft.Maui.Layouts.FlexWrap.Wrap,
                JustifyContent = Microsoft.Maui.Layouts.FlexJustify.Start,
                AlignItems = Microsoft.Maui.Layouts.FlexAlignItems.Start
            };
            BindAbilities(chips, weapon.Abilities);
            block.Children.Add(chips);
        }

        return block;
    }

    void BindAbilities(FlexLayout layout, IReadOnlyList<AbilityLink> abilities)
    {
        layout.Children.Clear();
        foreach (var ability in abilities)
        {
            var button = new Button
            {
                Text = ability.Name,
                Style = (Style)Resources["ChipButton"],
                BindingContext = ability,
                Margin = new Thickness(0, 0, 8, 8)
            };
            button.Clicked += OnAbilityClicked;
            layout.Children.Add(button);
        }
    }

    async void OnAbilityClicked(object? sender, EventArgs e)
    {
        if (sender is not Button { BindingContext: AbilityLink ability })
            return;

        await Shell.Current.GoToAsync($"RuleDetail?id={ability.Id}&kind={Uri.EscapeDataString(ability.Kind)}");
    }

    void AddHeader(Grid grid, int column, string text)
    {
        var label = new Label
        {
            Text = text,
            Style = (Style)Resources["StatHeader"],
            Padding = new Thickness(2, 8)
        };
        Grid.SetColumn(label, column);
        grid.Children.Add(label);
    }

    void AddValue(Grid grid, int column, string text)
    {
        var label = new Label
        {
            Text = text,
            Style = (Style)Resources["StatValue"]
        };
        Grid.SetColumn(label, column);
        grid.Children.Add(label);
    }

    static Color ThemeColor(string darkKey, string lightKey)
    {
        var app = Application.Current;
        var key = app?.RequestedTheme == AppTheme.Dark ? darkKey : lightKey;
        if (app?.Resources.TryGetValue(key, out var value) == true && value is Color color)
            return color;
        return Colors.Transparent;
    }

    static ColumnDefinitionCollection Columns(int count)
    {
        var columns = new ColumnDefinitionCollection();
        for (var i = 0; i < count; i++)
            columns.Add(new ColumnDefinition(GridLength.Star));
        return columns;
    }

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
