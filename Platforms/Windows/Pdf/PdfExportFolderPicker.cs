using WinUIWindow = Microsoft.UI.Xaml.Window;

namespace Baguettepic.WindowsPdf;

static class PdfExportFolderPicker
{
    public static async Task<string?> PickAsync()
    {
        var nativeWindow = GetNativeWindow();
        if (nativeWindow is null)
            return null;

        var picker = new Windows.Storage.Pickers.FolderPicker
        {
            SuggestedStartLocation = Windows.Storage.Pickers.PickerLocationId.DocumentsLibrary
        };
        picker.FileTypeFilter.Add("*");

        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(nativeWindow);
        WinRT.Interop.InitializeWithWindow.Initialize(picker, hwnd);

        var folder = await picker.PickSingleFolderAsync();
        return folder?.Path;
    }

    static WinUIWindow? GetNativeWindow()
    {
        var window = Application.Current?.Windows.FirstOrDefault();
        return window?.Handler?.PlatformView as WinUIWindow;
    }
}
