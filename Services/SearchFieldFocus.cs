namespace Baguettepic.Services;

public static class SearchFieldFocus
{
    /// <summary>
    /// Focuses a page's sole search/filter entry and selects its text so typing replaces it.
    /// Call when the page appears (and again after add-and-stay actions).
    /// </summary>
    public static void FocusAndSelect(Entry entry)
    {
        entry.Dispatcher.Dispatch(() =>
        {
            entry.Focus();
            var text = entry.Text ?? string.Empty;
            entry.CursorPosition = 0;
            entry.SelectionLength = text.Length;
        });
    }
}
