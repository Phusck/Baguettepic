using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(FormationId), "formationId")]
public partial class FormationDetachmentsPage : ContentPage
{
    int _formationId;

    public FormationDetachmentsPage()
    {
        InitializeComponent();
    }

    public string FormationId
    {
        get => _formationId.ToString();
        set => int.TryParse(value, out _formationId);
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

        await Shell.Current.GoToAsync(
            $"BaseDetail?baseId={row.BaseId}&detachmentName={Uri.EscapeDataString(row.DetachmentName)}");
    }

    void SetBusy(bool busy)
    {
        BusyIndicator.IsVisible = busy;
        BusyIndicator.IsRunning = busy;
    }
}
