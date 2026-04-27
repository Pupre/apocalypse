# Outdoor Spatial Map UI Design

- Status: active
- Date: 2026-04-15

## Goal

Replace the current mismatched outdoor map split with a coherent spatial map system:

- an outdoor minimap that shows only the immediate nearby world
- a full-screen draggable outdoor map that uses the same spatial visual language at larger scale
- fog-of-war over unvisited outdoor territory
- indoor structure revealed only after the player has physically entered that building

The user intent is explicit:

- the minimap should behave like a real minimap
- the current enlarged outdoor map should stop feeling like a different abstract system
- the expanded map should feel like a bigger version of the same world representation

## Core Principle

The outdoor map stack should use one spatial language, not two unrelated ones.

- The minimap is the near-field version
- The full-screen map is the navigable large-scale version

The difference is scale and interaction, not abstraction level.

## Surfaces

### 1. Outdoor Minimap

- Always visible during outdoor play
- Player-centered
- North fixed
- Shows only very nearby context
- Shows roads, nearby entrances, obstacles, and threats
- Does not try to expose the city at planning scale

This should feel like immediate tactical awareness.

### 2. Outdoor Full Map

- Opened from the minimap
- Full-screen overlay
- Draggable by touch/mouse
- Uses the same spatial world representation as the minimap, just at a larger navigable scale
- Outdoor time and simulation pause while it is open

This should feel like planning and orientation, not a debug view.

### 3. Indoor Structure Layer

- Indoor structure is not drawn on the outdoor map by default
- A building exterior can be visible on the outdoor map before entry
- Its internal structure becomes available only after the player has entered that building during the current run
- When the player taps a building on the full map, a separate indoor-structure layer opens for that building

The city map and indoor map should not be composited together at full density on the same base layer. That would become visually noisy too quickly.

## Visibility Rules

### Outdoor

- Visited outdoor space is visible
- Unvisited outdoor space is darkened heavily
- The player can still physically travel into the whole fixed city
- But the map only knows what the current run has discovered

### Indoor

- Indoor structure remains hidden until that building has been entered
- A never-entered building can still show name and outer footprint
- Tapping an unentered building should not reveal interior room structure

## Interaction Model

### Minimap

- Tap opens the full-screen outdoor map
- No drag
- No route editing
- No pin placement

### Full-Screen Outdoor Map

- Drag to pan around the city
- Close with explicit close button and back/cancel input
- Read-only in this pass
- Tapping a building selects it
- Selecting a known building can open its indoor-structure layer

### Building Detail / Indoor Layer

- Separate layer, not merged directly into the city map view
- Shows the building’s known indoor structure if the player has entered it
- If the building has never been entered, show only minimal building identity and deny interior reveal

## Why This Split

Three different jobs exist here:

1. immediate navigation while moving
2. large-scale route planning
3. recalling indoor structure

Trying to solve all three jobs inside one always-on visual treatment makes the UI noisy and unclear.

This design keeps them connected while still separating their responsibilities.

## Rendering Direction

### Minimap

The minimap should render from local world-space data:

- player position
- nearby roads
- nearby building entrances
- nearby obstacles
- nearby threats

### Full Outdoor Map

The full map should render from authored outdoor world-space geometry at city scale, not from abstract block tiles as the final presentation.

The fixed-size block runtime remains the data architecture underneath, but the player-facing map should read as a spatial city view, not as a grid debug surface.

### Indoor Structure Layer

The indoor layer can still use a more schematic representation if needed, because interior structure is more legible when abstracted.

That means:

- outdoor map should be spatial
- indoor layer may be schematic

This is intentional, not inconsistent.

## Fog-Of-War

### Outdoor Fog

- Applied to unexplored outdoor territory
- Dark enough that it reads as unknown, not just desaturated
- Lifted only by current-run exploration

### Indoor Fog

- Indoor layout is either known or unknown at building level in this pass
- Once a building has been entered, its available indoor structure can be shown in the separate layer
- Detailed room-by-room rediscovery behavior is out of scope for this pass unless already available from indoor memory systems

## Input And Pause Rules

- Opening the full outdoor map pauses outdoor movement and time progression
- Closing the full map resumes outdoor simulation
- Opening an indoor structure layer from the map keeps the map-navigation experience in a paused state

This is a single-player planning affordance and does not harm the intended tension.

## Testing Requirements

Implementation should verify at least:

- outdoor minimap remains visible in outdoor mode
- minimap shows only local nearby context
- full-screen map opens from the minimap
- full-screen map is draggable
- opening the full-screen map pauses outdoor time/simulation
- closing the map resumes outdoor time/simulation
- unvisited outdoor territory is darkened
- tapped buildings can open an indoor detail layer only if previously entered
- unentered buildings do not reveal interiors

## Out Of Scope

Not included in this pass:

- route plotting
- fast travel
- custom pins
- permanent cross-run map reveal
- save/resume design
- perfect zoom tooling
- fully unified indoor/outdoor renderer internals

## Replacement Note

This spec supersedes the earlier outdoor map split that treated the full-screen map as a block-grid strategy surface while treating the minimap separately.

That earlier direction is no longer the active target for player-facing UI.
