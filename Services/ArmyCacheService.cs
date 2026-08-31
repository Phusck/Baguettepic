using Baguettepic.Models;

namespace Baguettepic.Services;

public sealed class ArmyCacheService
{
    public static ArmyCacheService Instance { get; } = new();

    IReadOnlyList<ArmyListItem>? _armiesList;
    bool _armiesListDirty = true;
    readonly Dictionary<int, ArmyDetail> _armies = new();
    readonly HashSet<int> _dirtyArmies = new();

    public void Clear()
    {
        _armiesList = null;
        _armiesListDirty = true;
        _armies.Clear();
        _dirtyArmies.Clear();
    }

    public void InvalidateList() => _armiesListDirty = true;

    public void InvalidateArmy(int armyId)
    {
        _dirtyArmies.Add(armyId);
        _armiesListDirty = true;
    }

    public bool TryGetArmies(out IReadOnlyList<ArmyListItem> armies)
    {
        if (_armiesListDirty || _armiesList is null)
        {
            armies = [];
            return false;
        }

        armies = _armiesList;
        return true;
    }

    public bool TryGetArmy(int armyId, out ArmyDetail army)
    {
        if (_dirtyArmies.Contains(armyId) || !_armies.TryGetValue(armyId, out var cached))
        {
            army = null!;
            return false;
        }

        army = cached;
        return true;
    }

    public async Task<IReadOnlyList<ArmyListItem>> GetArmiesAsync(CancellationToken cancellationToken = default)
    {
        if (TryGetArmies(out var cached))
            return cached;

        return await RefreshArmiesAsync(cancellationToken);
    }

    public async Task<ArmyDetail?> GetArmyAsync(int armyId, CancellationToken cancellationToken = default)
    {
        if (TryGetArmy(armyId, out var cached))
            return cached;

        return await RefreshArmyAsync(armyId, cancellationToken);
    }

    public async Task<IReadOnlyList<ArmyListItem>> RefreshArmiesAsync(CancellationToken cancellationToken = default)
    {
        var fresh = await DatabaseService.Instance.GetArmiesAsync(cancellationToken);
        _armiesList = fresh;
        _armiesListDirty = false;
        return fresh;
    }

    public async Task<ArmyDetail?> RefreshArmyAsync(int armyId, CancellationToken cancellationToken = default)
    {
        var fresh = await DatabaseService.Instance.GetArmyAsync(armyId, cancellationToken);
        if (fresh is not null)
        {
            _armies[armyId] = fresh;
            _dirtyArmies.Remove(armyId);
        }
        else
        {
            _armies.Remove(armyId);
            _dirtyArmies.Remove(armyId);
        }

        _armiesListDirty = true;
        return fresh;
    }
}
