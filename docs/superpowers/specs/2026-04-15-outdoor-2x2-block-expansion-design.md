# Outdoor 2x2 Block Expansion Design

- Date: 2026-04-15
- Status: Draft

## Goal

Expand the outdoor world from the current single prototype block into a continuous `2x2` district that feels materially larger, supports longer travel, and creates more building-choice tension without breaking the existing portrait-first, player-centered traversal model.

The player should still see only the nearby world around them, but moving across the map should now feel like a real outing rather than a short walk between four props.

## Why This Change Exists

The current outdoor map proves the control loop, building entry, and pressure systems, but it still reads like one small test street. That limits:

- long-distance travel tension
- route choice under cold pressure
- meaningful tradeoffs between building types
- future scaling of pursuit and outdoor survival systems

The next step is not an infinite world or a region map. It is one larger district with enough scale to make movement itself consequential.

## Player Experience

The outdoor district should feel like a continuous urban area made from four connected blocks:

- the current `mart_01` block remains part of the layout
- the player can move across a wider district without screen breaks
- the main road is still the backbone, but there are now side pockets, parking areas, and cross-connections
- buildings are spread far enough apart that travel cost matters
- the district should support “go farther for a better option” decisions

This pass is still grounded and readable. It is not a full city simulation.

## Scope

This pass includes:

- a continuous `2x2` outdoor district
- a data-driven outdoor block layout instead of a one-off hardcoded street
- more outdoor building placements
- a mixed building set combining life-world and survival-oriented destinations
- updated world bounds, building placement, and obstacle layout
- tests that lock the wider traversal and building-presence contract

This pass does not include:

- procedural outdoor generation
- region streaming
- district-to-district travel
- combat
- multiple threat species
- outdoor loot nodes or street scavenging

## Recommended Architecture

### Approach Chosen

Use a block-layout data model and let `OutdoorController` render the district from that data.

This is preferred over directly hardcoding a much larger `outdoor_mode.tscn`, because the next expansion after `2x2` will otherwise become expensive and brittle.

### Rejected Alternatives

#### 1. Just enlarge `WORLD_BOUNDS` and manually add more buildings

Fastest, but it creates a larger prototype street rather than a true district model. It also keeps layout logic buried in scene edits.

#### 2. Hand-build the entire 2x2 map in the scene

Visually straightforward, but it scales badly. Future edits to roads, parking pockets, and building spacing become scene surgery.

## World Model

The outdoor district is made of four linked blocks:

- northwest
- northeast
- southwest
- southeast

These are not separate maps. They are one continuous world space.

Each block can define:

- road bands
- sidewalk bands
- optional parking or service pockets
- rubble / vehicle obstacle zones
- building anchors

The first pass should keep the street grammar simple and consistent. The goal is district scale, not high-fidelity environmental variety yet.

## Data Model

Add a new outdoor layout data file that defines the district shape. The model should be lightweight and purpose-built.

Recommended file:

- `game/data/outdoor_layout.json`

Recommended top-level fields:

- `world_bounds`
- `player_spawn`
- `blocks`
- `roads`
- `obstacles`
- `threat_spawns`

### Buildings

Keep building identity in `game/data/buildings.json`, but extend each row so outdoor placement is driven by a stable outdoor district model rather than a single loose point.

Recommended additions per building row:

- `outdoor_anchor_id`
- optional `district_label`

The layout file owns anchor positions. Buildings reference anchors by id.

This keeps:

- building identity and indoor linkage in `buildings.json`
- outdoor geometry and placement in `outdoor_layout.json`

## Building Mix

The first `2x2` district should keep the existing four buildings and add a mixed set that supports both life-world tone and survival value.

Recommended additions:

- `convenience_01`
- `hardware_01`
- `gas_station_01`
- `laundry_01`

This creates a better spread between:

- food / daily goods
- tools / repair materials
- fuel / travel tone
- ordinary civilian interiors

More can come later, but these are enough for a materially larger first district.

## Layout Rules

The map should obey these rules:

- the existing `mart_01` area remains part of the district
- the four blocks should feel connected by one main road spine and one crossing axis
- not every block needs the same density
- at least one block should feel sparser so distance is noticeable
- at least one block should have a parking-pocket or side-lot shape
- building spacing must force longer walks than the current setup
- traversal should remain portrait-readable with the current player-centered camera

## Controller Changes

`OutdoorController` should stop treating the world as a hand-authored one-street prototype.

It should instead:

- load outdoor layout data from `ContentLibrary`
- render ground bands and obstacle props from the layout model
- resolve building positions from anchor ids
- update `WORLD_BOUNDS` from the loaded layout
- keep player movement and building-entry checks working against the wider district

The controller should remain the single place where outdoor world data becomes visible runtime nodes.

## Scene Changes

`outdoor_mode.tscn` should become thinner.

It should keep only durable presentation containers such as:

- camera
- player marker
- canvas layer
- top ribbon
- frost overlay
- host nodes for generated world content

Road geometry, obstacle geometry, and building markers should no longer be treated as mostly hand-authored scene content.

## Testing

The expanded district needs explicit tests for scale and placement.

Add or extend tests so they verify:

- outdoor bounds are materially larger than the current prototype footprint
- the district contains more than the original four buildings
- the player can travel significantly farther while remaining in one continuous outdoor scene
- building entry still works for the new anchor-driven positions
- the smoke loop still boots and transitions into indoor play

The key contract is not just “more nodes exist.” It is “the outdoor world now supports longer continuous travel.”

## Risks

### Risk: Big empty map

If the `2x2` district is enlarged without enough spatial grammar, the result will feel empty rather than larger.

Mitigation:

- use four distinct block roles
- vary spacing
- include side pockets and obstacle rhythms

### Risk: Scene/data split becomes confusing

If outdoor geometry is half scene-authored and half data-authored, maintenance gets messy quickly.

Mitigation:

- keep runtime world content generated from layout data
- keep the scene focused on containers and HUD

### Risk: Building additions outpace indoor content

More outdoor buildings imply more indoor events.

Mitigation:

- in this pass, only add buildings whose indoor shells/events can be supplied immediately
- defer larger building catalogs until the outdoor district model is stable

## Success Criteria

This pass is successful when:

- the player can walk a noticeably larger continuous outdoor district
- the world feels like four linked blocks rather than one test street
- there are more building choices spread across meaningful travel distance
- the outdoor controller is layout-data-driven rather than mostly hardcoded
- portrait readability is preserved
- existing outdoor-to-indoor transitions continue to work
