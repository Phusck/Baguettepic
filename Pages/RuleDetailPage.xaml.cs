using Baguettepic.Models;
using Baguettepic.Services;

namespace Baguettepic.Pages;

[QueryProperty(nameof(RuleId), "id")]
[QueryProperty(nameof(Kind), "kind")]
public partial class RuleDetailPage : ContentPage
{
    int _id;
    string _kind = "Rule";
    CancellationTokenSource? _linkifyCts;

    public string RuleId
    {
        get => _id.ToString();
        set => int.TryParse(value, out _id);
    }

    public string Kind
    {
        get => _kind;
        set => _kind = Uri.UnescapeDataString(value ?? "Rule");
    }

    public RuleDetailPage()
    {
        InitializeComponent();
    }

    public RuleDetailPage(int id, string kind) : this()
    {
        _id = id;
        _kind = kind;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        EditButton.IsVisible = SessionService.Instance.IsAdmin;
        await LoadAsync();
    }

    protected override void OnDisappearing()
    {
        _linkifyCts?.Cancel();
        base.OnDisappearing();
    }

    async Task LoadAsync()
    {
        _linkifyCts?.Cancel();
        _linkifyCts = new CancellationTokenSource();
        var token = _linkifyCts.Token;

        try
        {
            var rule = await DatabaseService.Instance.GetRuleAsync(_id, _kind, token);
            token.ThrowIfCancellationRequested();
            if (rule is null)
            {
                NameLabel.Text = "Rule not found";
                DescriptionView.Source = MarkdownRenderer.ToHtmlSource("_This rule is no longer available._");
                EditButton.IsVisible = false;
                return;
            }

            _id = rule.Id;
            _kind = rule.Kind;
            Title = rule.Name;
            NameLabel.Text = rule.Name;
            DescriptionView.Source = MarkdownRenderer.ToHtmlSource(rule.Description);

            _ = LinkifyAsync(rule, token);
        }
        catch (OperationCanceledException)
        {
        }
        catch (Exception ex)
        {
            NameLabel.Text = "Could not load rule";
            DescriptionView.Source = MarkdownRenderer.ToHtmlSource("Check the database connection.");
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async Task LinkifyAsync(RuleListItem rule, CancellationToken token)
    {
        try
        {
            var names = await DatabaseService.Instance.GetAllRuleNamesAsync(token);
            token.ThrowIfCancellationRequested();

            var linked = await Task.Run(() => RuleLinkifier.Apply(rule.Description, names, rule.Id, rule.Kind), token);
            token.ThrowIfCancellationRequested();

            if (linked == rule.Description)
                return;

            await MainThread.InvokeOnMainThreadAsync(() =>
            {
                if (!token.IsCancellationRequested)
                    DescriptionView.Source = MarkdownRenderer.ToHtmlSource(linked);
            });
        }
        catch (OperationCanceledException)
        {
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
        }
    }

    async void OnEditClicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync($"RuleEdit?id={_id}&kind={Uri.EscapeDataString(_kind)}");

    void OnDescriptionNavigating(object? sender, WebNavigatingEventArgs e)
    {
        if (!RuleLinkifier.TryParseLink(e.Url, out var id, out var kind))
        {
            if (e.Url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                e.Url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                e.Cancel = true;
            }

            return;
        }

        e.Cancel = true;
        Dispatcher.Dispatch(async () =>
        {
            await Navigation.PushAsync(new RuleDetailPage(id, kind));
        });
    }
}
