using Markdig;

namespace Baguettepic.Services;

public static class MarkdownRenderer
{
    static readonly MarkdownPipeline Pipeline = new MarkdownPipelineBuilder()
        .UseAdvancedExtensions()
        .UseSoftlineBreakAsHardlineBreak()
        .DisableHtml()
        .Build();

    public static HtmlWebViewSource ToHtmlSource(string? markdown)
    {
        var dark = Application.Current?.RequestedTheme == AppTheme.Dark;
        var body = Markdown.ToHtml(markdown ?? string.Empty, Pipeline);
        var bg = dark ? "#120E0C" : "#E8DCC8";
        var fg = dark ? "#EDE4D4" : "#1A1210";
        var muted = dark ? "#B8A994" : "#4A4036";
        var accent = dark ? "#C9A84C" : "#7A1518";
        var codeBg = dark ? "#241E1A" : "#D4C8B4";

        var html = $$"""
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <style>
              html, body {
                background: {{bg}};
                color: {{fg}};
                font-family: "Segoe UI", "Open Sans", sans-serif;
                font-size: 16px;
                line-height: 1.55;
                margin: 0;
                padding: 4px 2px 16px 2px;
              }
              h1, h2, h3, h4 {
                color: {{accent}};
                font-family: Inquisitor, Palatino, "Palatino Linotype", "Times New Roman", serif;
                letter-spacing: 0.04em;
                margin: 1.1em 0 0.4em 0;
              }
              p { margin: 0 0 0.85em 0; }
              a { color: {{accent}}; }
              code, pre { background: {{codeBg}}; border-radius: 4px; }
              code { padding: 0.1em 0.35em; }
              pre { padding: 10px; overflow: auto; }
              ul, ol { padding-left: 1.4em; }
              blockquote { margin-left: 0; padding-left: 0.9em; border-left: 3px solid {{accent}}; color: {{muted}}; }
            </style>
            </head>
            <body>{{body}}</body>
            </html>
            """;

        return new HtmlWebViewSource { Html = html };
    }
}
