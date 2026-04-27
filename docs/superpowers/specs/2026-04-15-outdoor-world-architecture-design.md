# Outdoor World Architecture Design

- Date: 2026-04-15
- Status: Draft
- Supersedes: `2026-04-15-outdoor-2x2-block-expansion-design.md`

## Goal

Replace the current prototype outdoor map direction with an architecture that can grow into a very large fixed city while preserving uninterrupted player movement.

The immediate implementation target is still a small playable slice, but the structure must be able to scale toward a much larger world, potentially on the order of `64x64` blocks, without rewriting the outdoor system again.

## Core Principles

- The city is fixed, not procedurally rearranged per run.
- The city is fully accessible from the start.
- Access is limited by survival risk, distance, cold, threats, and hostile forces, not by artificial map locks.
- The player experiences continuous movement with no screen-to-screen transitions while outdoors.
- Internally, the game may stream nearby blocks to keep the system scalable.
- The map is not fully visible at run start. Visited territory reveals over time.
- Unvisited territory should be almost fully blacked out on the map.
- Map knowledge resets per run.

## Player Experience

Outdoor play should feel like moving through one continuous frozen city.

The player should be able to:

- leave the starting district immediately
- push into distant areas if they are willing to accept the survival risk
- learn the city through repeated runs
- become skilled at route selection, landmark memory, and danger prediction

The game should support a “veteran of the city” fantasy. The player eventually knows the city well, but that knowledge comes from repeated play rather than procedural randomness.

## World Model

### Fixed Grid

The city is modeled as a grid of fixed-size outdoor blocks.

- Every block has the same world-space dimensions.
- Block internals can differ completely.
- A block may contain a dense shopfront street, a residential pocket, a sparse snowy gap, or a large single facility.

The fixed block size is a systems decision, not a visual sameness decision.

### Continuous Space

The player must not feel block loading.

- Outdoor movement remains fully continuous.
- Crossing a block boundary does not trigger a scene swap.
- Block loading and unloading happens internally.

### Streaming Window

Only the nearby portion of the city should be active at once.

Initial target:

- keep the player’s current block plus the surrounding `3x3` block window active

This is the baseline scalability contract for the outdoor world.

## Data Model

### Recommended Structure

Use a shared outdoor world schema backed by JSON.

The engine side should stay generic. Content should live in data.

Recommended file families:

- `game/data/outdoor/world_layout.json`
  - world metadata, block size, streaming assumptions, city dimensions, global rules
- `game/data/outdoor/blocks/<x>_<y>.json`
  - one file per authored block
- `game/data/buildings.json`
  - building identity, indoor linkage, tags, and outdoor anchor references

### Block File Responsibilities

Each block file should describe:

- block coordinates
- local road geometry
- sidewalks / snow fields / lots
- obstacle placements
- building anchors
- threat spawn anchors
- landmark metadata

The block file does not own indoor building identity. It only owns where anchors and world geometry live.

### Building Placement

Buildings remain canonical entities in `buildings.json`, but they should no longer be treated as raw global points.

Recommended shape:

- `outdoor_block_coord`
- `outdoor_anchor_id`

This allows:

- stable building identity
- fixed city layout
- independent editing of block geometry and building content

## City Visibility

The city is globally real but locally known.

### World Access

- All blocks exist from the start.
- The player can physically travel anywhere if they survive the route.

### Map Knowledge

- Unvisited map space should be almost completely obscured.
- Visiting reveals the area.
- Revealed state is per-run.
- This is map knowledge, not world unlocking.

This distinction is important. The city is open. The player’s map is not.

## Progression Philosophy

Progression should come from:

- route mastery
- threat understanding
- climate management
- logistics
- city memory

Progression should not come from:

- hard map locks
- staged zone unlocks
- arbitrary “you may not enter this district yet” gating

If an area feels inaccessible, the reason should be practical survival pressure, not an obvious designer wall.

## 2x2 Slice Policy

The old `2x2 expansion` idea is no longer the architectural target. It becomes the first authored slice that validates the new world model.

That first slice should:

- live inside the larger block-grid architecture
- prove streaming boundaries
- prove block-to-block continuity
- prove that new authored blocks can be added without restructuring the system

The first slice is not the whole design.

## Runtime Responsibilities

### Outdoor World Runtime

The outdoor runtime layer should:

- know the player’s current block coordinate
- keep nearby blocks loaded
- unload distant blocks
- build world nodes from block data
- resolve building anchors into interactable building markers
- keep threat systems working across streamed block boundaries

### Scene Responsibilities

The outdoor scene should stay thin.

It should mainly host:

- camera
- player marker
- shared outdoor HUD
- frost overlay
- runtime world hosts

Most actual outdoor geometry should be generated from block data, not authored directly into a giant scene file.

## Testing Requirements

The architecture must be locked with tests, not just eyeballing.

Tests should eventually prove:

- fixed block-size world coordinates are loaded correctly
- nearby `3x3` block activation works
- block transitions do not interrupt movement
- buildings resolve from block anchors correctly
- visited-map state reveals only what the run has traversed
- smoke flow still supports outdoor traversal into indoor buildings

## Risks

### Risk: Fake scale

A larger coordinate space alone will not create city scale.

Mitigation:

- author blocks with distinct internal shapes
- vary block density and building mix
- ensure travel between destinations is meaningful

### Risk: Streaming seams

If block activation is visible, the city will feel fake.

Mitigation:

- stream ahead of the player
- preserve continuity of obstacles, roads, and threat state
- avoid obvious pop-in near the viewport center

### Risk: Data explosion

If every block is unique, content count will grow quickly.

Mitigation:

- keep one generic block schema
- let AI generate many individual block files that still obey the same schema

## Success Criteria

This direction is correct when:

- the outdoor world is architected for a large fixed city, not a prototype map
- the player can move continuously while the runtime streams nearby blocks internally
- the city can scale far beyond the first authored district
- map revelation is per-run and based on visited territory
- the system supports the long-term “city veteran” fantasy instead of disposable random maps
