using System.Text;
using System.Text.RegularExpressions;

namespace Baguettepic.Services;

public static class ParameterizedName
{
    public static bool IsTemplate(string name)
    {
        foreach (var inner in Parentheticals(name))
        {
            if (ContainsPlaceholder(inner))
                return true;
        }

        return false;
    }

    public static bool HasConcreteParentheticalValue(string name)
    {
        foreach (var inner in Parentheticals(name))
        {
            if (ContainsPlaceholder(inner))
                continue;
            if (inner.Any(char.IsDigit))
                return true;
        }

        return false;
    }

    public static string Format(string templateName, string? value)
    {
        if (string.IsNullOrWhiteSpace(templateName) || string.IsNullOrWhiteSpace(value))
            return templateName;

        var parts = value.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0)
            return templateName;

        var index = 0;
        var depth = 0;
        var text = new StringBuilder(templateName.Length + value.Length);
        for (var i = 0; i < templateName.Length; i++)
        {
            var c = templateName[i];
            if (c == '(')
                depth++;
            else if (c == ')')
                depth = Math.Max(0, depth - 1);

            if (depth > 0 && index < parts.Length && IsPlaceholderAt(templateName, i))
            {
                text.Append(parts[index++]);
                continue;
            }

            text.Append(c);
        }

        return text.ToString();
    }

    public static bool Matches(string templateName, string candidate)
    {
        if (string.IsNullOrWhiteSpace(templateName) || string.IsNullOrWhiteSpace(candidate))
            return false;
        if (templateName.Equals(candidate, StringComparison.OrdinalIgnoreCase))
            return true;
        if (!IsTemplate(templateName))
            return false;

        return Regex.IsMatch(
            candidate.Trim(),
            "^" + ToMatchRegex(templateName) + "$",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }

    public static string ToMatchRegex(string templateName)
    {
        var depth = 0;
        var pattern = new StringBuilder(templateName.Length * 2);
        for (var i = 0; i < templateName.Length; i++)
        {
            var c = templateName[i];
            if (c == '(')
            {
                depth++;
                pattern.Append(@"\(");
                continue;
            }

            if (c == ')')
            {
                depth = Math.Max(0, depth - 1);
                pattern.Append(@"\)");
                continue;
            }

            if (depth > 0 && IsPlaceholderAt(templateName, i))
            {
                pattern.Append(".+?");
                continue;
            }

            pattern.Append(Regex.Escape(c.ToString()));
        }

        return pattern.ToString();
    }

    static IEnumerable<string> Parentheticals(string name)
    {
        var start = -1;
        for (var i = 0; i < name.Length; i++)
        {
            if (name[i] == '(')
            {
                start = i + 1;
            }
            else if (name[i] == ')' && start >= 0)
            {
                yield return name[start..i];
                start = -1;
            }
        }
    }

    static bool ContainsPlaceholder(string text)
    {
        for (var i = 0; i < text.Length; i++)
        {
            if (IsPlaceholderAt(text, i))
                return true;
        }

        return false;
    }

    static bool IsPlaceholderAt(string text, int index)
    {
        var c = text[index];
        if (c is not ('X' or 'x' or 'Y' or 'y'))
            return false;
        if (index > 0 && char.IsLetter(text[index - 1]))
            return false;
        if (index + 1 < text.Length && char.IsLetter(text[index + 1]))
            return false;
        return true;
    }
}
