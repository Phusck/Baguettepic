-- Core rules from Palladium NetEpic 3
-- Latest Rulebook NNN under Palladium NetEpic 3 English Latex
-- (currently Rulebook 303: Important Concepts, Combat Phase, Morale, Movement Phase)

SET NAMES utf8mb4;

INSERT INTO Rule (RuleName, Description)
SELECT n, d FROM (
    SELECT
        'Pinned' AS n,
        'A base is pinned in an assault if it is engaged by an opponent of the same or a higher class. A pinned base loses its order and cannot move or fire. However, it may be activated during the Movement Phase if it has abilities or psychic powers that can be used.' AS d
    UNION ALL
    SELECT
        'Template',
        'A game component, usually circular, used to represent the area of effect of certain weapons or abilities.

Weapons that use a template have "Template" listed in the Dice column of their unit profile and possess the Template (X) ability. The size of the template is specified in the weapon''s abilities.

Firing arc and range are measured between the centre of the firing base and the centre of the template.

A base is hit by a template if the centre of its base is covered by the template, even if the base itself is not within line of sight.

## Circular Template

When using a circular template, the centre of the template must be within range, within line of sight, and within the weapon''s firing arc.

The template may cover bases that the firing base cannot see, provided it covers at least one valid target. If additional templates are used, each template must meet these requirements.

## Rangeless Flame Template

When using a rangeless flame template, the template may be placed in any position provided it lies entirely within the weapon''s firing arc. The narrow tip of the template must be placed over the centre of the firing base.

The template must also cover at least one valid target.

## Ranged Flame Template

When using a ranged flame template, its narrow end must be within line of sight and the entire template must be within the weapon''s firing arc, although the entire template does not need to be within line of sight.

The template''s central axis must point towards the centre of the target base, with its narrow end facing the firing base. The template must also cover at least one valid target.

## To-Hit

For a template weapon, roll one die for each base whose centre is covered by the template. Each result equal to or greater than the weapon''s To-Hit value inflicts one hit.

## Template Types

- Flame Templates: Teardrop-shaped templates used by flame weapons.
- 7.5 cm Templates: Circular templates with a diameter of 7.5 cm, used by weapons with the Template (7.5 cm) ability.
- 12 cm Templates: Circular templates with a diameter of 12 cm, used by weapons with the Template (12 cm) ability and when resolving a Titan Fall.'
    UNION ALL
    SELECT
        'Reroll',
        'Rolling one or more dice from a dice roll again. The rerolled results are final, even if they are worse than the original results. A rerolled die can never be rerolled a second time.'
    UNION ALL
    SELECT
        'Coherency',
        'Bases belonging to the same detachment must remain close to one another. This is represented by detachment coherency, which requires every base in the detachment to be no more than 6 cm from another base in that detachment. A detachment is in coherency if you can trace a path between any two of its bases through other bases in the detachment, with each base maintaining coherency.

Coherency must be maintained at all times, including while the detachment is moving. If a detachment is no longer in coherency, the separated parts of the detachment must attempt to rejoin during their next movement. The detachment is not required to restore coherency until it moves.

If this movement does not allow the separated parts to restore coherency, only one group is retained, chosen by the owning player. All other bases are immediately destroyed.'
    UNION ALL
    SELECT
        'Fall Back',
        'A detachment that fails a Morale Test is considered to be Falling Back. Replace its current order with a Fall Back order, and it must immediately make a Fall Back move. If the detachment has not yet acted during the current turn, it loses the opportunity to do so.

A detachment with a Fall Back order cannot perform any actions during the Combat Phase. It may remove its Fall Back order by passing a Rally Test or during its next activation in the Movement Phase by performing one of the actions permitted by the Fall Back order.

If a Falling Back detachment is completely pinned and cannot be activated during the Movement Phase, it remains Falling Back for the rest of the turn.

While a detachment has a Fall Back order:

- It has no zone of control.
- It cannot capture objectives.
- It cannot make Consolidation moves.
- Every base in the detachment suffers a -2 penalty to its AF.

## Fall Back Order / Without Orders

Detachments that are falling back or have no orders may perform one of two different actions:

Hold: The detachment cannot move but may make Snap Fire during the Combat Phase. It receives a revealed Forced March order.

Regroup: The detachment may make a normal move but cannot engage in an assault. Once the movement has been completed, remove its order counter, if it has one.

## Rally Test

When a detachment makes a Rally Test, it performs a Morale Test.

If the test is passed, remove its Fall Back order counter. The detachment may receive orders normally during the following turn.

If the test is failed, it retains its Fall Back order.

## Fall Back Movement

A detachment making a Fall Back move moves between 0 and 25 cm, regardless of its Movement characteristic, subject to the following restrictions:

- The detachment must leave every enemy interdiction zone by the shortest possible route. If this is impossible, it must move as far away as possible from all enemy bases.
- Once the detachment has left an enemy interdiction zone, it cannot enter another enemy interdiction zone.
- The detachment cannot enter an enemy zone of control, even if the enemy base is of a lower class.

Apart from these restrictions, the detachment may use its movement freely, including remaining in place.

A detachment engaged in an assault never makes a Fall Back move, whether or not it is pinned.

If, for any reason, the affected bases cannot leave enemy zones of control, they are destroyed.'
    UNION ALL
    SELECT
        'Countercharge',
        'Countercharge is an action available from a Charge order. The detachment may make a normal move and retains its revealed Charge order beside it. This allows the detachment to make a second move as a reaction, provided that this move enables it to engage an enemy detachment that ends its movement within range.

## Performing a Countercharge

To perform a Countercharge, a detachment must have been activated during the Movement Phase and placed in a Countercharge position. A base''s Countercharge radius is equal to its Movement characteristic.

If an enemy detachment ends its movement within this radius, the detachment may move to engage it in an assault. This is a standard movement that follows the normal movement rules, except that it is performed as a reaction to an enemy activation.

A Countercharge cannot be used to bring reserves onto the battlefield or to disengage from an assault.'
    UNION ALL
    SELECT
        'Shooting While Engaged in an Assault',
        'A base engaged in an assault may shoot if it is not pinned and has an order that permits it to fire.

It suffers a -1 penalty to the To-Hit rolls of all its weapons unless it is at least three classes higher than every opposing base. It may target either the enemy bases engaged with it or other valid targets.

If the assault was resolved earlier during the turn and the base survived, it may shoot without this penalty.'
    UNION ALL
    SELECT
        'Shooting into an Assault',
        'An assault may be targeted without restriction, either by standard shooting attacks or by template weapons. In both cases, attacks suffer a -1 penalty to their To-Hit rolls unless the target is at least three classes higher than every opposing base engaged with it.

For direct-fire attacks, each attack that misses must be rerolled against an opposing base in base-to-base contact with the original target. The firing player chooses which eligible opposing base is targeted by the rerolled attack.

For template attacks, To-Hit rolls are made normally against every base whose centre is covered by the template. If a base is covered but an opposing base engaged with it is not, that opposing base may be hit in the same manner as with a direct-fire attack.

Casualties must be distributed across as many separate duels as possible. They cannot be allocated in a way that leaves some bases fighting two against one while other bases are left without an opponent.'
    UNION ALL
    SELECT
        'Zone of Control',
        'A base represents a threat to the area around it, represented in the game by its zone of control. It is centred on the centre of the base and has a diameter of:

- 7.5 cm for Class 1–4 bases.
- 12 cm for Class 5 and higher bases.

For game purposes, a base must be no larger than its zone of control.

A base loses its zone of control in the following circumstances:

- If it is pinned in an assault.
- If it has engaged an enemy base in an assault.
- If it is immobilised.
- If it has a Fall Back order.

## Movement and Zones of Control

A base may only move through an enemy base''s zone of control if it is of a higher class than the enemy base. Engaging in an assault is an exception to this restriction.

If a base begins its movement within a zone of control, that zone of control is ignored for the duration of that movement.

A base is considered to be within another base''s zone of control if any part of it is inside the zone, not only its centre.

A base may move through the zones of control of enemy bases that it intends to engage without restriction. It may also move through multiple overlapping zones of control to make contact with its target.

## Garrison

A garrison''s zone of control extends around the entire perimeter of the structure, as though the centre of each garrisoned base were positioned at its edge. This applies regardless of the number of bases inside the structure.'
    UNION ALL
    SELECT
        'Interdiction Zone',
        'The interdiction zone represents a base''s long-range threat and affects certain aspects of the game for opposing bases, such as morale. It extends 25 cm around the base. A base does not generate an interdiction zone if it has a Fall Back order or is at altitude.'
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM Rule r WHERE r.RuleName = src.n
);

UPDATE Rule r
INNER JOIN (
    SELECT
        'Pinned' AS n,
        'A base is pinned in an assault if it is engaged by an opponent of the same or a higher class. A pinned base loses its order and cannot move or fire. However, it may be activated during the Movement Phase if it has abilities or psychic powers that can be used.' AS d
    UNION ALL
    SELECT
        'Fall Back',
        'A detachment that fails a Morale Test is considered to be Falling Back. Replace its current order with a Fall Back order, and it must immediately make a Fall Back move. If the detachment has not yet acted during the current turn, it loses the opportunity to do so.

A detachment with a Fall Back order cannot perform any actions during the Combat Phase. It may remove its Fall Back order by passing a Rally Test or during its next activation in the Movement Phase by performing one of the actions permitted by the Fall Back order.

If a Falling Back detachment is completely pinned and cannot be activated during the Movement Phase, it remains Falling Back for the rest of the turn.

While a detachment has a Fall Back order:

- It has no zone of control.
- It cannot capture objectives.
- It cannot make Consolidation moves.
- Every base in the detachment suffers a -2 penalty to its AF.

## Fall Back Order / Without Orders

Detachments that are falling back or have no orders may perform one of two different actions:

Hold: The detachment cannot move but may make Snap Fire during the Combat Phase. It receives a revealed Forced March order.

Regroup: The detachment may make a normal move but cannot engage in an assault. Once the movement has been completed, remove its order counter, if it has one.

## Rally Test

When a detachment makes a Rally Test, it performs a Morale Test.

If the test is passed, remove its Fall Back order counter. The detachment may receive orders normally during the following turn.

If the test is failed, it retains its Fall Back order.

## Fall Back Movement

A detachment making a Fall Back move moves between 0 and 25 cm, regardless of its Movement characteristic, subject to the following restrictions:

- The detachment must leave every enemy interdiction zone by the shortest possible route. If this is impossible, it must move as far away as possible from all enemy bases.
- Once the detachment has left an enemy interdiction zone, it cannot enter another enemy interdiction zone.
- The detachment cannot enter an enemy zone of control, even if the enemy base is of a lower class.

Apart from these restrictions, the detachment may use its movement freely, including remaining in place.

A detachment engaged in an assault never makes a Fall Back move, whether or not it is pinned.

If, for any reason, the affected bases cannot leave enemy zones of control, they are destroyed.'
    UNION ALL
    SELECT
        'Countercharge',
        'Countercharge is an action available from a Charge order. The detachment may make a normal move and retains its revealed Charge order beside it. This allows the detachment to make a second move as a reaction, provided that this move enables it to engage an enemy detachment that ends its movement within range.

## Performing a Countercharge

To perform a Countercharge, a detachment must have been activated during the Movement Phase and placed in a Countercharge position. A base''s Countercharge radius is equal to its Movement characteristic.

If an enemy detachment ends its movement within this radius, the detachment may move to engage it in an assault. This is a standard movement that follows the normal movement rules, except that it is performed as a reaction to an enemy activation.

A Countercharge cannot be used to bring reserves onto the battlefield or to disengage from an assault.'
    UNION ALL
    SELECT
        'Shooting While Engaged in an Assault',
        'A base engaged in an assault may shoot if it is not pinned and has an order that permits it to fire.

It suffers a -1 penalty to the To-Hit rolls of all its weapons unless it is at least three classes higher than every opposing base. It may target either the enemy bases engaged with it or other valid targets.

If the assault was resolved earlier during the turn and the base survived, it may shoot without this penalty.'
    UNION ALL
    SELECT
        'Shooting into an Assault',
        'An assault may be targeted without restriction, either by standard shooting attacks or by template weapons. In both cases, attacks suffer a -1 penalty to their To-Hit rolls unless the target is at least three classes higher than every opposing base engaged with it.

For direct-fire attacks, each attack that misses must be rerolled against an opposing base in base-to-base contact with the original target. The firing player chooses which eligible opposing base is targeted by the rerolled attack.

For template attacks, To-Hit rolls are made normally against every base whose centre is covered by the template. If a base is covered but an opposing base engaged with it is not, that opposing base may be hit in the same manner as with a direct-fire attack.

Casualties must be distributed across as many separate duels as possible. They cannot be allocated in a way that leaves some bases fighting two against one while other bases are left without an opponent.'
    UNION ALL
    SELECT
        'Zone of Control',
        'A base represents a threat to the area around it, represented in the game by its zone of control. It is centred on the centre of the base and has a diameter of:

- 7.5 cm for Class 1–4 bases.
- 12 cm for Class 5 and higher bases.

For game purposes, a base must be no larger than its zone of control.

A base loses its zone of control in the following circumstances:

- If it is pinned in an assault.
- If it has engaged an enemy base in an assault.
- If it is immobilised.
- If it has a Fall Back order.

## Movement and Zones of Control

A base may only move through an enemy base''s zone of control if it is of a higher class than the enemy base. Engaging in an assault is an exception to this restriction.

If a base begins its movement within a zone of control, that zone of control is ignored for the duration of that movement.

A base is considered to be within another base''s zone of control if any part of it is inside the zone, not only its centre.

A base may move through the zones of control of enemy bases that it intends to engage without restriction. It may also move through multiple overlapping zones of control to make contact with its target.

## Garrison

A garrison''s zone of control extends around the entire perimeter of the structure, as though the centre of each garrisoned base were positioned at its edge. This applies regardless of the number of bases inside the structure.'
    UNION ALL
    SELECT
        'Interdiction Zone',
        'The interdiction zone represents a base''s long-range threat and affects certain aspects of the game for opposing bases, such as morale. It extends 25 cm around the base. A base does not generate an interdiction zone if it has a Fall Back order or is at altitude.'
) AS src ON src.n = r.RuleName
SET r.Description = src.d;
