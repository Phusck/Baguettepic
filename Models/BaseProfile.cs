namespace Baguettepic.Models;

public sealed class BaseProfile
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string ImagePath { get; init; }
    public required int Movement { get; init; }
    public required string Save { get; init; }
    public required int FA { get; init; }
    public required int Morale { get; init; }
    public required int Class { get; init; }
    public required int DestructionPoints { get; init; }
    public required IReadOnlyList<AbilityLink> Abilities { get; init; }
    public required IReadOnlyList<WeaponProfile> Weapons { get; init; }

    public string? DetachmentName { get; init; }
    public bool HasImage => !string.IsNullOrWhiteSpace(ImagePath);
    public bool HasAbilities => Abilities.Count > 0;
    public bool HasWeapons => Weapons.Count > 0;
    public string MoveText => $"{Movement} cm";
    public string AfText => FA.ToString("+0;-0;0");
    public string MoraleText => Morale == 0 ? "--" : Morale.ToString();
    public string ClassText => Class.ToString();
    public string DestructionText => DestructionPoints.ToString();

    public ImageSource? Image =>
        !HasImage ? null
        : Uri.TryCreate(ImagePath, UriKind.Absolute, out var uri) &&
          (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps)
            ? ImageSource.FromUri(uri)
            : ImageSource.FromFile(ImagePath);
}
