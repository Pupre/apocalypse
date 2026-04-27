# Outdoor 3x3 Authored Slice Design

- Date: 2026-04-17
- Status: Draft
- Extends: `2026-04-15-outdoor-world-architecture-design.md`

## Goal

Expand the currently authored outdoor slice from `2x2` blocks to `3x3` blocks so the city stops feeling small before deeper story, loot, and map-item systems are added.

This is not a new outdoor architecture. The fixed-city block runtime, `3x3` streaming window, and large-world contract remain unchanged. The work here is content authoring and runtime validation at a larger playable radius.

## Why This Comes First

Right now the strongest outdoor limitation is scale.

- the player hits the edge of authored content too quickly
- building choice is still narrow
- travel distance is too short for route pressure to matter
- adding more loot and more story before widening the city would have low payoff

This pass therefore prioritizes `space first, depth second`.

## Scope

### In Scope

- expand the authored outdoor slice from `4` blocks to `9` blocks
- keep the existing `8x8` world schema and `3x3` streaming runtime
- add the missing five block files needed for one contiguous `3x3` district
- add enough new building anchors and building entries that the new slice feels meaningfully larger
- add thin indoor shells for any newly enterable buildings so traversal and entry still work
- vary block composition so the new city slice does not read as repeated clones

### Out of Scope

- deep narrative pass for every new building
- full loot/balance overhaul
- map-item reveal system
- world-scale expansion beyond the first authored `3x3` slice
- major changes to the runtime streaming model

## Authored Slice Shape

The authored slice should become these nine blocks:

- `(0,0)`
- `(1,0)`
- `(2,0)`
- `(0,1)`
- `(1,1)`
- `(2,1)`
- `(0,2)`
- `(1,2)`
- `(2,2)`

The current four authored blocks remain intact as the starting portion of the city. The new five blocks extend that playable footprint into a complete contiguous `3x3` slice.

## Block Authoring Policy

The new five blocks must **not** all use the same density or same shape grammar.

This variation should come from local block identity, not from a fake “downtown versus outskirts” rule. The user does not want the current authored area treated as a city center. The slice should instead feel like adjacent frozen neighborhoods with different lots, facilities, and street use patterns.

### Required Variation

Across the five new blocks, include a mix such as:

- a denser mixed-use block
- a block with one larger facility and fewer side destinations
- a block with broader open snow or lot space
- a service/logistics-feeling block
- a lower-density residential or mixed neighborhood block

The exact theme per block can stay lightweight in this pass, but the physical layout should already feel different.

## Building Density Target

The authored `2x2` slice already carries `16` buildings.

This pass should add roughly `12-16` more buildings across the new five blocks, for a total authored slice target of roughly `28-32` buildings.

Per new block:

- minimum: `2` enterable buildings
- preferred: `3`
- upper bound for this pass: `4`

This keeps the expansion meaningful without forcing a heavy story pass immediately.

## Indoor Content Policy For New Buildings

New buildings only need thin indoor shells in this pass.

Each new building must support:

- successful outdoor entry
- indoor location text
- baseline movement structure
- at least minimal search/loot interaction
- safe reuse of existing thin indoor event patterns where appropriate

This pass should favor breadth and traversal validity over bespoke interior writing.

## Outdoor Data Changes

### Block Files

Add five new files under:

- `game/data/outdoor/blocks/2_0.json`
- `game/data/outdoor/blocks/2_1.json`
- `game/data/outdoor/blocks/2_2.json`
- `game/data/outdoor/blocks/1_2.json`
- `game/data/outdoor/blocks/0_2.json`

Each file should define:

- road geometry
- snow fields / lots
- obstacles
- building anchors
- threat spawn anchors
- at least one landmark

### Buildings

`game/data/buildings.json` must be expanded so new anchors resolve to real buildings with indoor event paths.

The existing structure stays the same:

- `outdoor_block_coord`
- `outdoor_anchor_id`
- `indoor_event_path`

No new placement model is needed.

## Runtime Expectations

The runtime already supports a `3x3` active window. This pass should prove that the authored city slice now actually fills that window meaningfully when the player moves through the new district.

Correct behavior means:

- movement remains continuous across the new block seams
- building anchors resolve correctly in all nine blocks
- threat spawning still works in the new blocks
- the player can travel farther before the city feels exhausted

## Testing Requirements

Tests for this pass should lock:

- authored block count expands from `4` to `9`
- authored building count rises to the new target range
- controller/runtime smoke still works with the larger authored slice
- the player can still enter indoor buildings from the expanded district without regression

Tests do not need to prove rich narrative quality. They only need to prove that the new city footprint exists, loads, and remains traversable.

## Risks

### Risk: Bigger But Still Thin

A `3x3` slice can still feel fake if the new blocks are just repeated crossroad clones.

Mitigation:

- vary road placement, lot shapes, open snow usage, and anchor layout
- ensure each new block has at least one memorable landmark or shape difference

### Risk: Breadth Without Utility

If the map becomes larger but the new buildings do nothing, expansion will feel cosmetic.

Mitigation:

- every new block should add at least a couple of enterable buildings
- every new building should at least support thin indoor play

### Risk: Premature Content Depth

If this pass tries to fully flesh out the narrative and loot identity of every new destination, scope will bloat immediately.

Mitigation:

- keep new interiors thin
- save deep writing and loot specialization for the next pass

## Success Criteria

This pass is successful when:

- the city no longer feels like a tiny prototype district
- the authored outdoor footprint is a full contiguous `3x3` slice
- the new five blocks do not all feel like copies of one another
- the player has materially more building choice and travel distance
- the runtime architecture remains unchanged and stable
- future loot/story expansion now has enough physical city to matter
