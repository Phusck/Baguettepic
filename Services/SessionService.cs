namespace Baguettepic.Services;

public sealed class SessionUser
{
    public required int Id { get; init; }
    public required string Username { get; init; }
    public required bool IsAdmin { get; init; }
    public required bool MustChangePassword { get; init; }
}

public sealed class SessionService
{
    public const string AdminPassword = "WhySoTyranid";
    public const string StandardPassword = "OhMyImperialGuard";

    const string UsernameKey = "login_username";
    const string PasswordKey = "login_password";

    public static SessionService Instance { get; } = new();

    public SessionUser? CurrentUser { get; private set; }

    public bool IsAdmin => CurrentUser?.IsAdmin == true;
    public bool MustChangePassword => CurrentUser?.MustChangePassword == true;
    public int? CurrentUserId => CurrentUser?.Id;

    public async Task<(string Username, string Password)> LoadRememberedAsync()
    {
        var username = await ReadSecretAsync(UsernameKey);
        var password = await ReadSecretAsync(PasswordKey);
        return (username, password);
    }

    public async Task<string?> TryLoginAsync(string? username, string? password)
    {
        username = username?.Trim() ?? string.Empty;
        password ??= string.Empty;
        if (username.Length == 0)
            return "Enter a username.";
        if (password.Length == 0)
            return "Enter a password.";

        SessionUser? user;
        try
        {
            user = await DatabaseService.Instance.AuthenticateAsync(username, password);
        }
        catch (Exception)
        {
            return "Could not reach the database.";
        }

        if (user is null)
            return "Incorrect username or password.";

        CurrentUser = user;
        await WriteSecretAsync(UsernameKey, username);
        await WriteSecretAsync(PasswordKey, password);
        return null;
    }

    public void MarkPasswordChanged()
    {
        if (CurrentUser is null)
            return;
        CurrentUser = new SessionUser
        {
            Id = CurrentUser.Id,
            Username = CurrentUser.Username,
            IsAdmin = CurrentUser.IsAdmin,
            MustChangePassword = false
        };
    }

    public async Task RememberPasswordAsync(string password) =>
        await WriteSecretAsync(PasswordKey, password);

    public void Logout()
    {
        CurrentUser = null;
    }

    static async Task<string> ReadSecretAsync(string key)
    {
        try
        {
            return await SecureStorage.Default.GetAsync(key) ?? string.Empty;
        }
        catch
        {
            return Preferences.Default.Get(key, string.Empty);
        }
    }

    static async Task WriteSecretAsync(string key, string value)
    {
        try
        {
            await SecureStorage.Default.SetAsync(key, value);
            Preferences.Default.Remove(key);
        }
        catch
        {
            Preferences.Default.Set(key, value);
        }
    }
}
