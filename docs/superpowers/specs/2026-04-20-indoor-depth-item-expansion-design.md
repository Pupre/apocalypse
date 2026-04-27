# Indoor Depth and Item Expansion Design

- Date: 2026-04-20
- Status: Draft
- Extends: `2026-04-17-outdoor-3x3-authored-slice-design.md`

## Goal

Shift the next major content pass away from map radius and into building depth.

This pass should make the authored city feel less like a shell by:

- deepening four anchor buildings into small site-sized adventures
- lifting the rest of the existing building set out of the one-zone placeholder pattern
- expanding the item compendium with many more building-appropriate finds
- expanding crafting with both new and existing items, without forcing every new item to exist only as crafting fodder
- recording all newly added buildings and items in a separate art-request ledger in addition to the canonical game data

## Why This Comes Before More Map Growth

The city is now large enough to expose the next real problem: content thinness.

Right now too many buildings still read as:

- enter
- see one zone
- press search
- leave

If map radius keeps growing faster than building depth, the game will feel wider but hollower. This pass therefore prioritizes authored indoor density, site identity, and item ecology before the next large outdoor expansion.

## Scope

### In Scope

- deepen four anchor buildings:
  - `mart_01`
  - `hardware_01`
  - `apartment_01`
  - one logistics site built from `warehouse_01` and/or `garage_01`
- move the anchor buildings toward a reusable `tier 3` indoor site model
- lift the remaining existing buildings out of pure one-zone shells
- add a substantial new item set for living spaces, storage spaces, food spaces, maintenance spaces, and document/key spaces
- add new crafted items, intermediates, and cross-recipes that connect new and old items
- add new notes, keys, and site-specific finds where needed
- add outdoor-facing entry briefings so buildings can communicate access state, route hints, and site identity before entry
- maintain a separate resource-request ledger for newly added items and buildings

### Out of Scope

- another authored outdoor slice expansion
- world-scale map item reveal system
- full rebalance of every existing recipe and every existing loot table
- turning every building into a multi-floor dungeon immediately
- replacing the authored `2-ingredient` crafting combination model

## Building Depth Model

All indoor sites should be treated as extensible authored zone graphs rather than fixed one-shot shells.

### Shared Structure

Each building should be understood as some subset of:

- `entry zone`
- `core zones`
- `gates`
- `reward zones`
- `return/re-entry memory`

Where useful, a site can also include:

- `stairs or floor transition`
- `basement or service route`
- `locked side room`
- `shortcut or re-entry bypass`

### Depth Tiers

- `tier 1`
  - one-zone shell
  - minimal description
  - one search loop
- `tier 2`
  - `2-3` zones
  - at least one gate, branch, or locked inner room
  - enough identity that the site no longer feels disposable
- `tier 3`
  - `4-7` zones
  - multi-floor, basement, service route, or major locked section
  - site-specific item ecology
  - keys, notes, route memory, and stronger story texture

This pass should push the four anchor buildings to `tier 3` and push the remaining existing building set at least toward `tier 2` behavior where feasible.

## Anchor Building Set

### Mart

Role:

- living-goods hub
- broad early-game provisioning site
- familiar public space that becomes more private and rewarding deeper inside

Expected structure:

- entrance frontage
- main shelf floor
- cold-storage or food holding area
- employee space
- rear loading/storage
- optional locked stock room or small office

Expected feel:

- easy to enter
- not trivial to fully clear
- better finds move toward the rear and staff-only sections

### Hardware Store

Role:

- repair, sealing, fastening, fuel-adjacent support, improvised infrastructure

Expected structure:

- front retail floor
- tool wall / parts aisles
- workbench or cut station
- locked material room
- rear receiving area

Expected feel:

- more about parts and problem-solving than simple loot
- should seed both direct utility and future crafting chains

### Apartment

Role:

- memory-heavy living site
- personal belongings, domestic survival, keys, notes, layered room identity

Expected structure:

- lobby or building entrance
- corridor / first living unit
- stairwell
- upper unit(s)
- optional rooftop, basement utility room, or boiler/service room

Expected feel:

- room-by-room human traces
- stronger narrative texture than the commercial buildings
- good place for notes, keys, fiber goods, hygiene items, and domestic heat improvisation

### Warehouse / Garage Logistics Site

Role:

- large-resource, large-risk, large-lock site
- fuel, bulk storage, metal, containers, vehicle-adjacent material

Expected structure:

- front yard / shutter entrance
- work floor
- storage stacks
- locked shutter or fenced inner zone
- optional maintenance pit or service sub-area

Expected feel:

- worse access, better payoff
- a place where big containers, fuel-adjacent items, structural materials, and awkward heavy finds make sense

## Existing Building Uplift Policy

The rest of the city cannot stay as throwaway shells.

This pass should therefore give every pre-existing shallow building at least one of:

- a second or third zone
- a locked inner room
- a short branch
- a site-specific note, key, or clue
- a second-stage search target that is spatially distinct from the entry zone

Success does not require all of them to become equally deep. It requires that they no longer all read as identical filler.

## Item Compendium Expansion

This pass is not only a crafting-material pass. It is an item-compendium thickening pass.

New items should include a broad mix of:

- direct-use consumables
- equipment and tools
- keys, documents, and personal objects
- crafting materials
- crafting intermediates
- crafted outcomes

Important constraint:

- not every new item must become part of crafting
- some items should simply make the world feel more lived-in and specific
- some items should mainly be there because they make sense in a mart, apartment, hardware store, or logistics site

Examples of acceptable non-crafting-heavy additions:

- snacks or packaged foods
- domestic odds and ends
- personal effects
- site-specific records or notes
- low-value but world-thickening supplies

The goal is not to turn every object into a recipe input. The goal is to make the item dictionary feel like a believable frozen-city ecology.

## Crafting Expansion Model

Crafting remains authored in `game/data/crafting_combinations.json` with explicit two-item combinations.

That model should remain intact.

What changes in this pass is the shape of the graph built on top of it.

### Desired Crafting Behavior

- new items should sometimes combine with existing items
- new items should sometimes combine with each other
- some crafted outputs should unlock additional second-stage combinations
- not every new item needs to participate in all three patterns

The rule is flexibility, not uniformity.

The system should demonstrate that:

- new item families can plug into old recipes and tools
- old items remain relevant when new content arrives
- the crafting graph can deepen without forcing every object into a recipe

### Maximum Complexity For This Pass

Support chains up to roughly `3` authored steps where it makes sense, but do not turn the game into a dense factory sim.

Examples of good outcomes:

- raw household or shop finds becoming a useful intermediate
- that intermediate combining with an old item to create a stronger survival tool
- a domestic or logistics-site find combining with a known item to produce a more interesting heating, storage, repair, or hygiene outcome

## Item Ecology By Anchor Building

### Mart

Primary item families:

- shelf foods
- packaged snacks
- drink mixes
- containers
- bags and wraps
- household consumables
- modest warmth-adjacent daily-use items

This is the best place to thicken the compendium with believable low-drama items that still matter.

### Hardware Store

Primary item families:

- fasteners
- sealants
- tapes
- brackets
- hose, valve, fitting, and wire-adjacent pieces
- repair helpers
- improvised assembly parts

This is the best anchor for new intermediates and cross-recipes with existing tools and containers.

### Apartment

Primary item families:

- cloth and bedding variants
- hygiene products
- personal notes
- keys
- household tools
- domestic food and drink leftovers
- small comfort items

This is the best anchor for making the compendium feel human rather than purely systemic.

### Warehouse / Garage

Primary item families:

- bulk containers
- metal pieces
- hose and line materials
- maintenance goods
- vehicle-adjacent supplies
- fuel-adjacent storage or handling objects
- dirty work materials

This is the best anchor for heavier, awkward, or more technical finds.

## Outdoor Entry Briefing Changes

The outdoor interaction layer should no longer only act as a generic enter prompt.

For buildings touched by this pass, the outdoor-facing briefing should be able to communicate:

- site identity
- whether the building is straightforward, partially blocked, or gated
- whether there is a known locked section, upper floor, basement, or service route
- whether the site has been partially explored already

This does not need a full redesign of outdoor UX, but the player should stop approaching buildings as identical black boxes.

## Resource Request Ledger Requirement

Every new building and every new item added in this pass must be captured in two places:

### Canonical Data

- `game/data/buildings.json`
- `game/data/items.json`
- `game/data/crafting_combinations.json`
- the relevant indoor event JSON files

### Separate Art / Resource Request Ledger

Implementation must also create and maintain a separate document for newly introduced content in this pass.

That ledger should include, at minimum:

- item or building id
- player-facing name
- category / role
- short visual description
- notes for requested icon, building art, prop art, or special object art

This document exists so content expansion can be handed to resource generation cleanly without mixing request-oriented notes into the canonical gameplay data files.

## Data and Authoring Expectations

This pass should grow the authored indoor event set rather than replace the model.

Expected authoring changes include:

- more zones per anchor site
- more site-local event ids
- more zone transitions and gates
- more building-specific keys and notes
- more loot pools tied to site identity
- more recipes and more item rows

The system should remain authored and explicit. No procedural indoor generation is needed.

## Risks

### Risk: Anchor Buildings Become Good, Everything Else Still Feels Fake

Mitigation:

- require minimum uplift for the remaining existing buildings
- treat shell-only sites as failures unless they are explicitly marked for later follow-up

### Risk: New Items Feel Like Disconnected Junk

Mitigation:

- add non-crafting items intentionally, not randomly
- tie each item cluster to believable site identity
- ensure some, but not all, new items connect into the crafting graph

### Risk: Crafting Expansion Becomes Too Rigid

Mitigation:

- do not enforce a rule that every new item must support every combination pattern
- prefer believable authored relationships over abstract systemic purity

### Risk: Scope Blow-Up

Mitigation:

- focus deep bespoke writing on the four anchor buildings
- apply lighter but meaningful uplift to the rest
- keep the crafting model explicit and authored

## Success Criteria

This pass is successful when:

- the four anchor buildings feel materially deeper than current shells
- the rest of the current building set no longer feels uniformly disposable
- the item compendium becomes noticeably broader, not just more craft-material-heavy
- old and new items coexist in a more expandable recipe graph
- the player can feel that buildings now have identity, route logic, and internal depth
- the project gains a clean resource-request ledger for newly introduced buildings and items
