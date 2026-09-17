namespace Baguettepic.Services;

public static class WindowsFolderName
{
    public const string InvalidMessage =
        "Army names cannot contain \\ / : * ? \" < > | and cannot be a reserved Windows name.";

    static readonly HashSet<string> Reserved = new(StringComparer.OrdinalIgnoreCase)
    {
        "CON", "PRN", "AUX", "NUL",
        "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
        "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
    };

    public static bool IsValid(string name, out string? error)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            error = "Enter a name.";
            return false;
        }

        if (name.EndsWith('.') || name.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
        {
            error = InvalidMessage;
            return false;
        }

        if (Reserved.Contains(NameStem(name)))
        {
            error = InvalidMessage;
            return false;
        }

        error = null;
        return true;
    }

    public static string SanitizeFileName(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            return "unit";

        var invalid = Path.GetInvalidFileNameChars();
        var cleaned = new string(name.Trim().Select(c => Array.IndexOf(invalid, c) >= 0 ? '_' : c).ToArray())
            .Trim()
            .TrimEnd('.');
        if (cleaned.Length == 0 || Reserved.Contains(NameStem(cleaned)))
            return "unit";

        return cleaned;
    }

    static string NameStem(string name)
    {
        var dot = name.IndexOf('.');
        return dot >= 0 ? name[..dot] : name;
    }
}
