namespace Baguettepic.WindowsPdf;

static class PdfExportFolderStore
{
    const string Key = "pdf_export_root";

    public static string? GetExisting()
    {
        var path = Preferences.Default.Get(Key, string.Empty);
        if (string.IsNullOrWhiteSpace(path) || !Directory.Exists(path))
            return null;

        return path;
    }

    public static void Set(string path) => Preferences.Default.Set(Key, path);
}
