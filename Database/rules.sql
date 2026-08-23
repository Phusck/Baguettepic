-- Core rules from Palladium NetEpic 3
-- Latest Rulebook NNN under Palladium NetEpic 3 English Latex
-- (currently Rulebook 303: Important Concepts, Combat Phase, Markers and Templates)

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
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM Rule r WHERE r.RuleName = src.n
);
