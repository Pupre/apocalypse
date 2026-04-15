# Outdoor Map And Fog UI Design

- Status: active
- Date: 2026-04-15

## Goal

Add an outdoor minimap and a full-screen city map that make long-distance travel legible without weakening exploration.

The map UI must support the current fixed-city, fixed-size block runtime:

- the city is globally open from the start
- map knowledge is not globally open
- only blocks visited during the current run are revealed
- unvisited blocks remain almost fully black

This feature is for outdoor play only in this pass.

## Design Summary

Outdoor play gets two connected but different map surfaces:

1. a small minimap in the upper-right play area
2. a full-screen map overlay opened by tapping the minimap

These two surfaces do not serve the same job.

- The minimap is a local situational aid. It follows the player in real time and shows the nearby world around them.
- The full-screen map is a strategic planning surface. It shows the authored city block grid, reveals only visited blocks for the current run, and keeps everything else nearly black.

The outdoor minimap must behave like an actual minimap, not like a miniature block-level city map.

## Minimap

### Placement

- Position: upper-right, below the top ribbon rather than embedded inside it
- Shape: small square panel
- Tone: cold, subdued, readable over snow and streets
- Priority: secondary to play space; it must not eat too much forward view

### Behavior

- The minimap is always visible during outdoor play
- It is not shown indoors
- It centers on the player and follows movement continuously
- North stays fixed; the minimap does not rotate with facing or travel direction
- It shows nearby local world space, not the global city block grid
- The player marker is bright and immediately readable
- It shows nearby outdoor context such as roads, nearby entrances, obstacles, and threat markers
- It does not try to reveal the entire city or solve long-distance planning by itself

### Scope For Pass 1

- local world-space minimap only
- no rotation
- no route drawing
- no destination pins
- no loot markers
- no labels for distant buildings
- no zoom controls

## Full-Screen Map

### Open/Close

- Open by tapping the minimap
- Open as a full-screen overlay on top of the outdoor world
- Close with an explicit close button or the existing back/cancel input
- The overlay must sit above the shared HUD so its close button is never blocked by the top ribbon

### Why Full-Screen

This is a planning tool, not a bottom-sheet supplement.

A bottom sheet would preserve more of the live world but would compress the map too much. For long-distance survival planning, the map should temporarily become the primary surface.

### Behavior

- The map shows the authored city block grid for the current world slice
- Only visited blocks for the current run are revealed
- Unvisited blocks remain nearly black
- The player marker is clearly visible
- The current block is easy to distinguish from merely visited blocks
- Opening the full-screen map pauses outdoor moment-to-moment play and time progression
- Closing the full-screen map resumes outdoor play

### Why The Surfaces Differ

The minimap and the full-screen map intentionally use different visual languages.

- The minimap is for immediate survival awareness while moving
- The full-screen map is for long-distance planning and visited-territory recall

Trying to make both surfaces use the same block-grid presentation would make the minimap feel abstract and unhelpful during live traversal.

## Fog-Of-War Rules

### Reveal Unit

- reveal unit is the outdoor block
- revealing happens when the player enters a block
- reveal state is stored per run
- reveal state resets on a new run

### Visibility Treatment

- visited block: map contents visible
- current block: visited styling plus stronger highlight
- unvisited block: almost fully black

The key point is that the player may physically reach the whole city, but their map remains ignorant until they have been there during that run.

## Information Density

To keep the map game-like rather than tool-like:

- do not show exact path guidance
- do not pre-reveal building names in unvisited blocks
- do not preview hidden content
- do not add failure/success affordances

The map exists to support orientation and planning, not to solve exploration.

## Rendering Model

The outdoor world runtime already knows:

- block coordinates
- active streamed blocks
- visited block state
- nearby authored geometry and world-space anchors used by the outdoor controller

The map UI should be a visual consumer of that model rather than a parallel world representation.

Recommended rendering split:

- `OutdoorMinimap` control: local world-space window, always-on, player-centered
- `OutdoorMapOverlay` control: full-screen block-grid city map with fog-of-war
- `OutdoorMinimap` reads outdoor controller/runtime world-space data
- `OutdoorMapOverlay` reads world layout plus visited-block state from `RunState`

## Input Model

- Outdoor moment-to-moment play remains movement-first
- The minimap is a passive display until tapped
- The full-screen map is read-only in this pass
- Tapping the full-screen map does not move the player

This avoids turning the map into a shortcut teleport or a route command surface too early.

## Testing Requirements

Implementation should verify at least:

- minimap is visible outdoors and hidden indoors
- minimap follows the player continuously in local world space
- minimap keeps north fixed
- minimap shows nearby entrances, obstacles, and threat markers
- tapping the minimap opens the full-screen overlay
- the full-screen overlay sits above the HUD and its close button remains clickable
- opening the full-screen overlay pauses outdoor play/time
- closing the full-screen overlay resumes outdoor play
- closing returns to normal outdoor play
- entering a new block marks it visited
- visited blocks render as visible
- unvisited blocks render as blacked out
- current block is highlighted more strongly than previously visited blocks

## Out Of Scope

Not included in this pass:

- save/resume handling for map state
- permanent map knowledge across runs
- destination pins, notes, filters, or custom markers
- tap-to-travel behavior
- map-based fast travel
- indoor map integration
- redesigning the indoor minimap in this same pass

## Follow-Up Note

The abstract block-style map treatment removed from the outdoor minimap is a better fit for indoor navigation than for outdoor live traversal.

That does not make indoor minimap redesign part of this pass, but it does establish the likely direction for a future indoor minimap rework.
