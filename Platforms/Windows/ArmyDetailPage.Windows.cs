using Baguettepic.WindowsPdf;

namespace Baguettepic.Pages;

public partial class ArmyDetailPage
{
    partial void AddWindowsPdfActions()
    {
        var create = new Button { Text = "Create PDFs" };
        create.Clicked += OnCreatePdfsClicked;
        var change = new Button { Text = "Change PDF folder" };
        change.Clicked += OnChangePdfFolderClicked;

        BottomActions.Children.Insert(0, create);
        BottomActions.Children.Insert(1, change);
    }

    async void OnCreatePdfsClicked(object? sender, EventArgs e)
    {
        SetBusy(true);
        BottomActions.IsEnabled = false;
        try
        {
            await ArmyPdfExportService.ExportArmyAsync(this, _armyId);
        }
        catch (Exception ex)
        {
            await DisplayAlertAsync("Create PDFs", ShortError(ex), "OK");
            System.Diagnostics.Debug.WriteLine(ex);
        }
        finally
        {
            BottomActions.IsEnabled = true;
            SetBusy(false);
        }
    }

    async void OnChangePdfFolderClicked(object? sender, EventArgs e)
    {
        try
        {
            await ArmyPdfExportService.ChangeFolderAsync(this);
        }
        catch (Exception ex)
        {
            await DisplayAlertAsync("PDF folder", "Could not change the folder.", "OK");
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    static string ShortError(Exception ex)
    {
        var current = ex;
        while (current.InnerException is not null)
            current = current.InnerException;

        var line = current.Message.ReplaceLineEndings(" ").Trim();
        if (line.Length > 280)
            line = line[..277] + "...";
        return string.IsNullOrWhiteSpace(line) ? "Could not create the PDFs." : line;
    }
}
