namespace Baguettepic.Services;

public enum UserRole
{
    Guest,
    Admin
}

public sealed class SessionService
{
    public const string AdminPassword = "WhySoTyranid";
    public const string GuestPassword = "OhMyImperialGuard";

    const string RoleKey = "login_role";
    const string PasswordKey = "admin_password";

    public static SessionService Instance { get; } = new();

    public UserRole? CurrentRole { get; private set; }

    public async Task<(UserRole Role, string Password)> LoadRememberedAsync()
    {
        var roleName = Preferences.Default.Get(RoleKey, nameof(UserRole.Guest));
        var role = roleName == nameof(UserRole.Admin) ? UserRole.Admin : UserRole.Guest;
        var password = await ReadPasswordAsync();
        return (role, password);
    }

    public async Task<string?> TryLoginAsync(UserRole role, string? password)
    {
        if (role == UserRole.Guest)
        {
            CurrentRole = UserRole.Guest;
            Preferences.Default.Set(RoleKey, nameof(UserRole.Guest));
            return null;
        }

        if (string.IsNullOrWhiteSpace(password))
            return "Enter the admin password.";

        if (password != AdminPassword)
            return "Incorrect password.";

        CurrentRole = UserRole.Admin;
        Preferences.Default.Set(RoleKey, nameof(UserRole.Admin));
        await WritePasswordAsync(password);
        return null;
    }

    public void Logout()
    {
        CurrentRole = null;
    }

    static async Task<string> ReadPasswordAsync()
    {
        try
        {
            return await SecureStorage.Default.GetAsync(PasswordKey) ?? string.Empty;
        }
        catch
        {
            return Preferences.Default.Get(PasswordKey, string.Empty);
        }
    }

    static async Task WritePasswordAsync(string password)
    {
        try
        {
            await SecureStorage.Default.SetAsync(PasswordKey, password);
        }
        catch
        {
            Preferences.Default.Set(PasswordKey, password);
        }
    }
}
