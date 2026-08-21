using Baguettepic.Services;
using MySqlConnector;

namespace Baguettepic.Pages;

[QueryProperty(nameof(RuleId), "id")]
[QueryProperty(nameof(Kind), "kind")]
public partial class RuleEditPage : ContentPage
{
    int _id;
    string _kind = "Rule";
    bool _isNew = true;

    public string RuleId
    {
        get => _id.ToString();
        set
        {
            if (int.TryParse(value, out var id) && id > 0)
            {
                _id = id;
                _isNew = false;
            }
        }
    }

    public string Kind
    {
        get => _kind;
        set
        {
            if (!string.IsNullOrWhiteSpace(value))
                _kind = Uri.UnescapeDataString(value);
        }
    }

    public RuleEditPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        if (SessionService.Instance.CurrentRole != UserRole.Admin)
        {
            await DisplayAlertAsync("Admin only", "Only an admin can add or edit rules.", "OK");
            await Shell.Current.GoToAsync("..");
            return;
        }

        if (_isNew)
        {
            Title = "New Rule";
            return;
        }

        Title = "Edit Rule";
        try
        {
            var rule = await DatabaseService.Instance.GetRuleAsync(_id, _kind);
            if (rule is null)
            {
                await DisplayAlertAsync("Not found", "That rule is no longer available.", "OK");
                await Shell.Current.GoToAsync("..");
                return;
            }

            NameEntry.Text = rule.Name;
            DescriptionEditor.Text = rule.Description;
        }
        catch (Exception ex)
        {
            ErrorLabel.Text = "Could not load the rule.";
            ErrorLabel.IsVisible = true;
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async void OnSaveClicked(object? sender, EventArgs e)
    {
        ErrorLabel.IsVisible = false;
        var name = NameEntry.Text?.Trim() ?? string.Empty;
        var description = DescriptionEditor.Text ?? string.Empty;

        if (name.Length == 0)
        {
            ErrorLabel.Text = "Enter a name.";
            ErrorLabel.IsVisible = true;
            return;
        }

        try
        {
            if (_isNew)
                await DatabaseService.Instance.CreateRuleAsync(name, description);
            else
                await DatabaseService.Instance.UpdateRuleAsync(_id, _kind, name, description);

            await Shell.Current.GoToAsync("..");
        }
        catch (MySqlException ex) when (ex.ErrorCode == MySqlErrorCode.DuplicateKeyEntry)
        {
            ErrorLabel.Text = "A rule with that name already exists.";
            ErrorLabel.IsVisible = true;
        }
        catch (Exception ex)
        {
            ErrorLabel.Text = "Could not save the rule.";
            ErrorLabel.IsVisible = true;
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }
}
