using System.Text.RegularExpressions;
using Baguettepic.Models;

namespace Baguettepic.Services;

public static class RuleLinkifier
{
    public const string LinkHost = "baguettepic.rules";

    public static string Apply(string markdown, IReadOnlyList<RuleListItem> rules, int currentId, string currentKind)
    {
        var candidates = rules
            .Where(rule => !string.IsNullOrWhiteSpace(rule.Name))
            .Where(rule => rule.Id != currentId || !string.Equals(rule.Kind, currentKind, StringComparison.OrdinalIgnoreCase))
            .GroupBy(rule => rule.Name, StringComparer.OrdinalIgnoreCase)
            .Select(group => group.First())
            .OrderByDescending(rule => rule.Name.Length)
            .ToList();

        if (candidates.Count == 0)
            return markdown;

        var (protectedText, tokens) = Protect(markdown);
        var byName = new Dictionary<string, RuleListItem>(StringComparer.OrdinalIgnoreCase);
        foreach (var rule in candidates)
            byName.TryAdd(rule.Name, rule);

        var alternation = string.Join("|", candidates.Select(rule => Regex.Escape(rule.Name)));
        var regex = new Regex(
            $@"(?<![A-Za-z0-9])(?:{alternation})(?![A-Za-z0-9])",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

        var linked = regex.Replace(protectedText, match =>
        {
            if (!byName.TryGetValue(match.Value, out var rule))
                return match.Value;

            var url = $"https://{LinkHost}/rule?id={rule.Id}&kind={Uri.EscapeDataString(rule.Kind)}";
            return $"[{match.Value}]({url})";
        });

        return Restore(linked, tokens);
    }

    public static bool TryParseLink(string url, out int id, out string kind)
    {
        id = 0;
        kind = string.Empty;
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri))
            return false;
        if (!uri.Host.Equals(LinkHost, StringComparison.OrdinalIgnoreCase))
            return false;

        var query = ParseQuery(uri.Query);
        if (!query.TryGetValue("id", out var idText) || !int.TryParse(idText, out id))
            return false;
        if (!query.TryGetValue("kind", out var kindText) || string.IsNullOrWhiteSpace(kindText))
            return false;

        kind = Uri.UnescapeDataString(kindText);
        return true;
    }

    static (string Text, List<string> Tokens) Protect(string markdown)
    {
        var tokens = new List<string>();
        string Tokenize(Match match)
        {
            tokens.Add(match.Value);
            return $"\u0000{tokens.Count - 1}\u0000";
        }

        var text = Regex.Replace(markdown, @"```[\s\S]*?```", Tokenize);
        text = Regex.Replace(text, @"`[^`]+`", Tokenize);
        text = Regex.Replace(text, @"!\[[^\]]*\]\([^)]*\)", Tokenize);
        text = Regex.Replace(text, @"\[[^\]]*\]\([^)]*\)", Tokenize);
        return (text, tokens);
    }

    static string Restore(string text, List<string> tokens) =>
        Regex.Replace(text, "\u0000(\\d+)\u0000", match =>
            tokens[int.Parse(match.Groups[1].Value)]);

    static Dictionary<string, string> ParseQuery(string query)
    {
        var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        if (query.StartsWith('?'))
            query = query[1..];

        foreach (var part in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var separator = part.IndexOf('=');
            if (separator < 0)
                continue;

            var key = Uri.UnescapeDataString(part[..separator]);
            var value = Uri.UnescapeDataString(part[(separator + 1)..].Replace("+", " "));
            values[key] = value;
        }

        return values;
    }
}
