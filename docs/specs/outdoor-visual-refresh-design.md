# Outdoor Visual Refresh Design

- Status: approved
- Created: 2026-04-02
- Last updated: 2026-04-02
- Scope: first outdoor visual refresh for the prototype

## Purpose

Replace the current placeholder outdoor presentation with a game-like top-down pixel-art scene that supports future expansion without locking the project into a heavy art pipeline too early.

This refresh is not a final world-art pass. It defines the first reusable outdoor visual language for movement, navigation, entry points, and basic collision readability.

## Fixed Direction

### Visual Style

- perspective: `top-down 2D`
- art style: `pixel art`
- first target tone: `생활권 폐허형`
- readability priority: `high`
- atmosphere priority: secondary to movement clarity, entry clarity, and obstacle readability

### World Feel

- the intended player experience is `one large continuous world`
- the internal implementation may use chunked data or chunked loading later
- the first outdoor map should already feel like part of a larger world rather than a single arena
- future regions may expand into `도시 블록형` and `완전 황폐형` spaces without replacing the base visual system

### Camera and Navigation

- the outdoor scene should move toward a scrolling map with the camera following the player
- the player should feel that they are moving through a neighborhood rather than hopping between isolated rooms
- the first pass must still keep entry points and walkable routes obvious

## Asset Strategy

### Chosen Approach

Use a mixed CC0 asset set.

- character and simple props: `Kenney top-down pixel assets`
- roads, sidewalks, buildings, and neighborhood surfaces: `CC0 city tiles`

This was chosen because it gives the best balance between:

- commercial-license safety
- automatic download feasibility
- speed of integration
- neighborhood ruin tone
- readable gameplay space

### License Standard

Only assets with an explicit license compatible with commercial release should be used.

Required checks:

- commercial use allowed
- modification allowed
- packaging inside a shipped game allowed
- attribution requirement is explicit

Current preferred standard:

- `CC0` first

### First Integration Goal

The first outdoor art pass only needs enough assets to support:

- a visible player character
- recognizable building shapes and entrances
- readable roads and sidewalks
- a few large obstacle classes
- enough surface variety to feel like a ruined neighborhood

## First Playable Scope

### Player

- replace the triangle marker with a pixel-art player sprite
- facing or animation can remain minimal in the first pass
- the player must remain easy to track against the environment

### Buildings

- replace flat color building markers with simple pixel-art building silhouettes or tiles
- each current building should remain readable by category:
  - mart
  - apartment
  - clinic
  - office
- entry points should be visually obvious

### Ground and Layout

- introduce roads, sidewalks, curb lines, small lots, and small debris patterns
- the layout should read as a damaged but still recognizable living district
- the map should not try to simulate a full city yet

### Obstacles and Collision

The first pass should support only large, readable collision objects:

- building outer walls
- parked or abandoned vehicles
- barricades
- large rubble piles

Small decorative clutter should stay low-cost in the first pass.

- some pieces may be visual only
- some pieces may be slow-down surfaces later
- they should not overwhelm basic route readability now

## Technical Direction

### Integration Model

- keep outdoor art data-driven where practical
- keep the current building data as the source of semantic building identity
- layer visuals on top of existing building metadata instead of replacing the metadata model
- allow future map chunks to swap in different tile themes without changing the movement/controller layer

### Collision Philosophy

- collisions should support clear route planning first
- players should understand why they are blocked
- walls and large props should define route shape
- collision density should stay moderate in the first pass

### Map Growth

- the prototype should move toward a larger scrolling map
- the first art pass does not need full chunk streaming yet
- but the scene layout should not assume a tiny single-screen arena forever

## Risks and Controls

### Risk: art mismatch between packs

Control:

- prefer matching scale first
- adapt palette and usage patterns before looking for more packs
- if needed, use one pack for ground and another only for focal sprites

### Risk: too much detail hurts readability

Control:

- prioritize path readability, entry readability, and obstacle readability
- keep decorative clutter secondary
- test from normal play zoom, not only from editor view

### Risk: scope explosion into full open world art

Control:

- treat this as a `first neighborhood slice`
- implement only enough art to prove the outdoor loop
- postpone biome diversity and large-area world dressing until after basic outdoor gameplay decisions are stable

## Verification Plan

The first outdoor art pass should be considered successful when:

1. the player sprite is readable during movement
2. building types are distinguishable at a glance
3. entrances are easy to find
4. major obstacles clearly define walkable space
5. the scene feels more like a ruined neighborhood than a debug playground
6. the current outdoor loop remains playable without losing clarity
