# Portrait UI Framework Design

- Status: active
- Date: 2026-04-17

## Goal

Replace the current piecemeal portrait UI styling with one consistent mobile-first surface system that can guide both implementation and asset generation.

The target is not a one-off polish pass. The target is a stable UI grammar:

- outdoor, indoor, bag, crafting, and maps should feel like parts of one game
- new sprite generation should have a clear destination and role
- future UI work should stop reinventing panel, button, and overlay behavior surface by surface

## Problem

The game currently has several locally-improved UI surfaces, but no reliable framework above them.

That creates visible friction:

- outdoor HUD and indoor top area use different visual logic
- bag, craft, and map surfaces are improving independently instead of as one kit
- state presentation still depends too much on ad hoc labels instead of durable status surfaces
- asset generation is difficult to direct because there is no fixed inventory of UI surface categories

The user intent is explicit:

- lock the UI frame first
- then request or integrate art against that frame
- stop treating each new UI improvement as a separate local experiment

## Core Principle

The UI should be designed as a small set of reusable surface types with fixed responsibilities.

Each system must belong to one surface category:

- world
- top ribbon
- card
- sheet
- overlay

The player should learn that grammar once and reuse it everywhere.

## Surface Stack

### 1. World Layer

The lowest layer is always gameplay space.

- outdoor continuous travel
- indoor room/zone presentation

The world layer should stay visually readable and should not be permanently crowded by large floating utility panels.

### 2. Top Ribbon

The top ribbon is the one global persistent HUD grammar.

It always owns:

- current location
- clock/time
- global access buttons
- survival state gauges

This is the first major unification target.

The top ribbon should not be a loose set of labels. It should read as one compact survival instrument panel.

#### Top Ribbon Structure

Row 1:

- location
- time
- global buttons such as map and bag

Row 2:

- health gauge
- hunger gauge
- thirst gauge
- fatigue gauge
- cold/exposure gauge

Outdoor and indoor both use this grammar.

The difference is emphasis, not layout family.

### 3. Card Layer

Cards present the current local reading/decision context.

Indoor relies on this heavily:

- room summary
- result feedback
- action section lists

Outdoor uses cards sparingly:

- transient danger notifications
- urgent warnings

Cards should not replace the top ribbon or the bag. They exist for local moment-to-moment context.

### 4. Sheet Layer

Sheets are used for selective, work-like interactions.

This includes:

- bag
- item detail
- contextual crafting

The sheet layer already exists in the shared `SurvivalSheet`. This spec preserves that direction and treats it as the canonical item-management surface.

### 5. Overlay Layer

Overlays are fullscreen or near-fullscreen modal surfaces.

This includes:

- world map
- indoor structure view
- large detail inspectors

Overlays pause or strongly suspend local action where appropriate.

The map stack belongs here, not in the top ribbon and not in the bag.

## Outdoor Screen Rules

Outdoor should remain visually spacious.

### Persistent UI

- top ribbon only
- no permanent minimap
- no permanent large tactical card

### On-Demand UI

- world map from the ribbon
- bag from the ribbon
- transient warnings when danger or cold state changes

Outdoor should feel like world-first play with compact survival instrumentation above it.

## Indoor Screen Rules

Indoor is text-heavy and decision-heavy.

### Persistent UI

- same top ribbon family as outdoor
- same global buttons family
- same survival gauge language

### Main Surface

- cards for summary, result, and action sections
- bag opened as sheet
- structure view opened as overlay

Indoor should feel denser and more authored than outdoor, but still use the same surface hierarchy.

## Survival Gauge Rules

The survival gauges are now a required part of the top ribbon.

Tracked gauges:

- health
- hunger
- thirst
- fatigue
- cold/exposure

### Rendering Rules

- short horizontal bars with icon + fill
- readable at small portrait-mobile size
- distinct color families, but still one coherent kit
- cold/exposure should become the most visually stressed meter outdoors when conditions worsen

### Data Rules

The gauge system should reflect existing survival state, not create new gameplay rules.

This is a presentation upgrade, not a mechanics rewrite.

## Map Rules

The previous direction still stands:

- no always-on outdoor minimap
- map is opened from the ribbon
- fullscreen overlay
- draggable, zoomable full map
- unvisited outdoor territory stays dark
- indoor structure is revealed only after entry

The ribbon only owns the entry button, not the map itself.

## Bag Rules

The previously-approved bag-first direction remains active:

- list-first inventory
- detail as bottom sheet
- crafting as an added sheet-state above the bag

This spec does not replace the bag redesign. It provides the global framework around it.

## Asset Generation Categories

This framework defines the asset families that future sprite requests should target.

### Top Ribbon Set

- ribbon background
- gauge frames
- gauge fills
- compact utility buttons
- separators

### Card Set

- reading card background
- result card background
- section headers
- action row states

### Sheet Set

- bag background
- detail sheet background
- crafting card background
- tabs and selected row states
- action buttons

### Overlay Set

- map background
- structure background
- modal detail panels
- close controls

### Status / Utility Icon Set

- survival icons
- map / bag / structure / close
- danger / warmth / cold / movement / search / loot / lock

### FX Set

- frost overlays
- wind streak overlays
- subtle snow/noise overlays

## First Implementation Target

The first implementation target under this framework is:

1. unify the top ribbon between outdoor and indoor
2. replace label-only survival state with compact gauges
3. keep current bag and map surfaces attached to that new ribbon entry pattern

This gives the project a stable global frame before deeper art passes.

## Out Of Scope

Not part of this framework pass:

- rewriting survival mechanics
- finishing the full world map item-reveal system
- final indoor structure-map rendering
- final art polish of every panel and button
- save system design

## Testing Requirements

Implementation should verify at least:

- outdoor and indoor expose the same top ribbon structure
- both surfaces expose the same global button family for bag/map or structure access
- survival values render as gauge surfaces rather than text-only labels
- ribbon remains readable in portrait layout
- existing bag and map entry flows remain functional after the ribbon change

## Relationship To Existing Specs

This spec becomes the parent UI framework for the currently active bag and map redesign docs.

Those specs still define their local behavior:

- `2026-04-16-inventory-bottom-sheet-redesign.md`
- `2026-04-16-inventory-craft-slot-bar-design.md`
- `2026-04-15-outdoor-spatial-map-ui-design.md`

But this document defines the common visual grammar that they now live inside.
