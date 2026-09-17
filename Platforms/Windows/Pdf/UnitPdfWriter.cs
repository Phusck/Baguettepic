using Baguettepic.Models;
using Baguettepic.Services;
using QuestPDF.Fluent;
using QuestPDF.Infrastructure;
using PdfContainer = QuestPDF.Infrastructure.IContainer;

namespace Baguettepic.WindowsPdf;

static class UnitPdfWriter
{
    const string Inquisitor = "Inquisitor";
    const string OpenSans = "OpenSans";
    const string OpenSansSemibold = "OpenSansSemibold";
    const string HeaderFill = "#7A1518";
    const string HeaderText = "#E4D5B5";
    const string ValueFill = "#FFFFFF";
    const string Ink = "#1A1210";
    const string Border = "#C9A84C";
    const string NameFill = "#C9A84C";
    const string PageVoid = "#16110C";
    const string InnerFill = "#FFFFFF";

    const float CardWidthMm = 70;
    const float CardHeightMm = 120;
    const float InnerPadLeftMm = 7.2f;
    const float InnerPadRightMm = 7.4f;
    const float InnerPadTopMm = 10.0f;
    const float InnerPadBottomMm = 9.6f;

    const float TableHeaderSize = 8;
    const float TableValueSize = 9;
    const float WeaponNameSize = 10.5f;
    const float WeaponAbilitySize = 8;
    const float NameListSize = 9;

    static readonly byte[]? FrameBytes = LoadAsset("Baguettepic.Pdf.card-frame.png");
    static readonly string EdgeFrameSvg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 1200" preserveAspectRatio="none">
          <rect x="1.6" y="1.6" width="696.8" height="1196.8" fill="none" stroke="#C9A84C" stroke-width="3.2"/>
          <rect x="6" y="6" width="688" height="1188" fill="none" stroke="#6B1014" stroke-width="1.6"/>
        </svg>
        """;
    static bool _fontsReady;

    static UnitPdfWriter()
    {
        QuestPDF.Settings.License = LicenseType.Community;
        EnsureFonts();
    }

    public static void Write(IReadOnlyList<UnitPdfPage> units, string path)
    {
        EnsureFonts();

        Document.Create(container =>
        {
            foreach (var unit in units)
            {
                container.Page(page =>
                {
                    page.Size(CardWidthMm * 2, CardHeightMm, Unit.Millimetre);
                    page.Margin(0);
                    page.PageColor(PageVoid);
                    page.DefaultTextStyle(text => text
                        .FontSize(7)
                        .FontColor(Ink)
                        .FontFamily(OpenSans));

                    page.Content().Row(row =>
                    {
                        row.ConstantItem(CardWidthMm, Unit.Millimetre)
                            .Height(CardHeightMm, Unit.Millimetre)
                            .Element(card => WriteCardFace(card, inner =>
                                inner.Column(column => WriteUnitFace(column, unit.Profile, unit.Skills, unit.PsychicPowers))));

                        row.ConstantItem(CardWidthMm, Unit.Millimetre)
                            .Height(CardHeightMm, Unit.Millimetre)
                            .Element(card => WriteCardFace(card, inner =>
                                inner.ScaleToFit().Column(column =>
                                {
                                    column.Spacing(2);
                                    WriteRuleList(column, "Skills", unit.Skills);
                                    WriteRuleList(column, "Psychic powers", unit.PsychicPowers);
                                })));
                    });
                });
            }
        }).GeneratePdf(path);
    }

    static void WriteCardFace(PdfContainer container, Action<PdfContainer> content)
    {
        container.Layers(layers =>
        {
            layers.Layer().Background(InnerFill);

            layers.PrimaryLayer()
                .PaddingLeft(InnerPadLeftMm, Unit.Millimetre)
                .PaddingRight(InnerPadRightMm, Unit.Millimetre)
                .PaddingTop(InnerPadTopMm, Unit.Millimetre)
                .PaddingBottom(InnerPadBottomMm, Unit.Millimetre)
                .Element(content);

            if (FrameBytes is { Length: > 0 })
                layers.Layer().Image(FrameBytes).UseOriginalImage(true).FitUnproportionally();

            layers.Layer().Svg(EdgeFrameSvg).FitArea();
        });
    }

    static void WriteUnitFace(
        ColumnDescriptor column,
        BaseProfile profile,
        IReadOnlyList<RuleListItem> skills,
        IReadOnlyList<RuleListItem> psychicPowers)
    {
        column.Spacing(2);

        column.Item().AlignCenter().Text(profile.Name)
            .FontFamily(Inquisitor)
            .FontSize(17)
            .FontColor(Ink);

        if (TryDecodeImage(profile.ImageBytes) is { } image)
            column.Item().Element(c => WriteCenteredImage(c, image));

        column.Item().ExtendVertical().ScaleToFit().Column(tables =>
        {
            tables.Spacing(1.8f);
            tables.Item().Element(c => WriteStatTable(c, profile));
            WriteNameList(tables, "Skills", skills);
            WriteNameList(tables, "Psychic powers", psychicPowers);

            foreach (var weapon in profile.Weapons.Concat(profile.ChosenTitanWeapons))
            {
                tables.Item().Column(block =>
                {
                    block.Spacing(0.6f);
                    block.Item().Element(c => WriteWeaponTable(c, weapon));
                    if (weapon.HasAbilities)
                    {
                        block.Item().Text(string.Join(", ", weapon.Abilities.Select(a => a.Name)))
                            .FontSize(WeaponAbilitySize)
                            .FontColor(Ink);
                    }
                });
            }
        });
    }

    static void WriteCenteredImage(PdfContainer container, byte[] image)
    {
        container
            .Height(30, Unit.Millimetre)
            .AlignCenter()
            .AlignMiddle()
            .Image(image)
            .FitArea();
    }

    static void WriteStatTable(PdfContainer container, BaseProfile profile)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(columns =>
            {
                columns.RelativeColumn();
                columns.RelativeColumn();
                columns.RelativeColumn();
                columns.RelativeColumn();
                columns.RelativeColumn(1.25f);
            });

            Header(table, "Move");
            Header(table, "Save");
            Header(table, "FA");
            Header(table, "Morale");
            Header(table, "Class size");

            Value(table, profile.MoveText);
            Value(table, Blank(profile.Save));
            Value(table, profile.AfText);
            Value(table, profile.MoraleText);
            Value(table, profile.ClassText);
        });
    }

    static void WriteWeaponTable(PdfContainer container, WeaponProfile weapon)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(columns =>
            {
                columns.RelativeColumn(1.15f);
                columns.RelativeColumn(1.7f);
                columns.RelativeColumn(1.05f);
                columns.RelativeColumn(0.85f);
            });

            table.Cell().ColumnSpan(4).Element(NameCell).Text(weapon.Name)
                .FontFamily(Inquisitor)
                .FontSize(WeaponNameSize)
                .FontColor(Ink);

            Header(table, "Range");
            Header(table, "Attack Dice");
            Header(table, "To Hit");
            Header(table, "AP");

            Value(table, Blank(weapon.Range));
            Value(table, weapon.DiceText);
            Value(table, Blank(weapon.ToHit));
            Value(table, weapon.ApText);
        });
    }

    static void WriteNameList(ColumnDescriptor column, string heading, IReadOnlyList<RuleListItem> rules)
    {
        if (rules.Count == 0)
            return;

        column.Item().Text(text =>
        {
            text.Span($"{heading}: ").FontFamily(OpenSansSemibold).FontSize(NameListSize);
            text.Span(string.Join(", ", rules.Select(rule => rule.Name))).FontSize(NameListSize);
        });
    }

    static void WriteRuleList(ColumnDescriptor column, string heading, IReadOnlyList<RuleListItem> rules)
    {
        if (rules.Count == 0)
            return;

        column.Item().AlignCenter().Text(heading)
            .FontFamily(Inquisitor)
            .FontSize(12)
            .FontColor(Ink);

        foreach (var rule in rules)
        {
            column.Item().Text(rule.Name)
                .FontFamily(OpenSansSemibold)
                .FontSize(7)
                .FontColor(Ink);

            var description = MarkdownRenderer.ToPlainText(rule.Description);
            if (description.Length == 0)
                continue;

            column.Item().Text(description)
                .FontSize(5)
                .FontColor(Ink)
                .LineHeight(1.15f);
        }
    }

    static void Header(TableDescriptor table, string label) =>
        table.Cell().Element(HeaderCell).Text(SingleLine(label))
            .FontFamily(OpenSansSemibold)
            .FontSize(TableHeaderSize)
            .FontColor(HeaderText);

    static void Value(TableDescriptor table, string value) =>
        table.Cell().Element(ValueCell).Text(SingleLine(value)).FontSize(TableValueSize).FontColor(Ink);

    static PdfContainer HeaderCell(PdfContainer container) =>
        Cell(container, HeaderFill);

    static PdfContainer ValueCell(PdfContainer container) =>
        Cell(container, ValueFill);

    static PdfContainer NameCell(PdfContainer container) =>
        Cell(container, NameFill);

    static PdfContainer Cell(PdfContainer container, string fill) =>
        container
            .Border(0.5f)
            .BorderColor(Border)
            .Background(fill)
            .PaddingVertical(0.6f)
            .PaddingHorizontal(0.4f)
            .AlignCenter()
            .AlignMiddle()
            .ScaleToFit();

    static void EnsureFonts()
    {
        if (_fontsReady)
            return;

        RegisterFont(Inquisitor, "Inquisitor.otf");
        RegisterFont(OpenSans, "OpenSans-Regular.ttf");
        RegisterFont(OpenSansSemibold, "OpenSans-Semibold.ttf");
        _fontsReady = true;
    }

    static void RegisterFont(string family, string fileName)
    {
        var path = Path.Combine(AppContext.BaseDirectory, fileName);
        if (!File.Exists(path))
            return;

        using var stream = File.OpenRead(path);
        QuestPDF.Drawing.FontManager.RegisterFontWithCustomName(family, stream);
    }

    static byte[]? LoadAsset(string resourceName)
    {
        using var stream = typeof(UnitPdfWriter).Assembly.GetManifestResourceStream(resourceName);
        if (stream is null)
            return null;

        using var memory = new MemoryStream();
        stream.CopyTo(memory);
        return memory.ToArray();
    }

    static byte[]? TryDecodeImage(byte[]? bytes)
    {
        if (bytes is not { Length: > 0 })
            return null;

        try
        {
            QuestPDF.Infrastructure.Image.FromBinaryData(bytes);
            return bytes;
        }
        catch
        {
            return null;
        }
    }

    static string Blank(string value) =>
        string.IsNullOrWhiteSpace(value) ? "--" : value;

    static string SingleLine(string value) =>
        Blank(value).Replace(' ', '\u00A0');
}
