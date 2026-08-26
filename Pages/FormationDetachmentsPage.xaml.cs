using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(FormationId), "formationId")]
[QueryProperty(nameof(ArmyId), "armyId")]
[QueryProperty(nameof(TitanIndex), "titanIndex")]
public partial class FormationDetachmentsPage : ContentPage
{
    int _formationId;
    int _armyId;
    int? _titanIndex;

    public FormationDetachmentsPage()
    {
        InitializeComponent();
    }

    public string FormationId
    {
        get => _formationId.ToString();
        set => int.TryParse(value, out _formationId);
    }

    public string ArmyId
    {
        get => _armyId.ToString();
        set => int.TryParse(value, out _armyId);
    }

    public string TitanIndex
    {
        get => _titanIndex?.ToString() ?? string.Empty;
        set => _titanIndex = int.TryParse(value, out var index) ? index : null;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadAsync();
    }

    async Task LoadAsync()
    {
        try
        {
            SetBusy(true);
            var roster = await DatabaseService.Instance.GetFormationRosterAsync(_formationId);
            if (roster is null)
            {
                NameLabel.Text = "Formation not found";
                StatusLabel.Text = string.Empty;
                BindableLayout.SetItemsSource(DetachmentsHost, null);
                return;
            }

            Title = roster.FormationName;
            NameLabel.Text = roster.FormationName;
            BindableLayout.SetItemsSource(DetachmentsHost, roster.Detachments);
            StatusLabel.ClearValue(Label.TextColorProperty);
            StatusLabel.Text = roster.Detachments.Count == 1
                ? "1 detachment"
                : $"{roster.Detachments.Count} detachments";
        }
        catch (Exception ex)
        {
            StatusLabel.TextColor = Colors.IndianRed;
            StatusLabel.Text = "Could not load detachments.";
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            SetBusy(false);
        }
    }

    async void OnBaseTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not DetachmentBaseRow row)
            return;

        var armyQuery = _armyId > 0
            ? $"&armyId={_armyId}&formationId={_formationId}"
              + (_titanIndex is int index ? $"&titanIndex={index}" : string.Empty)
            : string.Empty;
        await Shell.Current.GoToAsync(
            $"BaseDetail?baseId={row.BaseId}&detachmentName={Uri.EscapeDataString(row.DetachmentName)}{armyQuery}");
    }

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
