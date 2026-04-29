# Carry, Heat, and Loot Pressure Design

- Date: 2026-04-27
- Status: active
- Extends:
  - `docs/specs/core-gameplay-design.md`
  - `2026-04-20-indoor-depth-item-expansion-design.md`

## Goal

Push the game closer to the intended disaster-preparedness fantasy by making outdoor trips, hauling choices, and high-value scavenging runs feel materially constrained.

This pass is not about adding more map radius first.

It is about making the player ask:

- what can I actually carry back
- how long can I stay outside
- do I have the means to recover heat if I push deeper
- should I take immediate calories, future fuel, better hauling gear, or camp equipment

## Player Fantasy

The target fantasy is not just “survive the cold.”

It is:

- supplies exist in meaningful quantity
- I cannot take everything
- what I choose to carry now changes what I can survive later
- a distant building may be reachable, but the real question is whether I can return or establish heat there

This is a planning-and-prioritization survival game, not a generic loot vacuum.

## Problem

The current prototype still flattens several important survival judgments.

### Carrying Is Too Abstract

The existing carry model is still close to a count/bulk limit.

That weakens the difference between:

- a bottle of water
- a heavy fuel container
- a compact snack
- a portable heat device

The player should feel those as different hauling decisions.

### Outdoor Exposure Is Not Yet Strong Enough

If the player can stay outside too casually, then:

- warmth gear feels optional
- fuel feels optional
- route planning feels soft
- “just hit another building” becomes too easy

The game stops feeling like a cold disaster run.

### Large Supply Sites Feel Unrealistically Thin

Places like marts, hardware stores, and warehouses should not feel like they contain exactly one of everything.

The player should not be told:

- there was only one chocolate bar
- there was only one can
- there was only one screwdriver in a hardware store

Instead, some sites should present real stock volume, while still forcing selective hauling.

## Scope

### In Scope

- replace the current carry limit baseline with a weight-based carry model
- define overburden states and their gameplay effects
- make bags and hauling gear modify weight thresholds rather than just abstract capacity
- define the heat recovery rule:
  - outdoors loses heat
  - indoors stops heat loss
  - real recovery requires heat
- define portable and fixed heat source classes
- add quantity-bearing supply sources for large-stock sites such as marts, hardware stores, and warehouses
- preserve individual-item pickup for keys, notes, rare tools, and one-off finds
- prepare but do not yet implement partial-consumption logic

### Out of Scope

- full rebalance of every existing item
- full outdoor level redesign across the whole city
- food splitting / partial drinking / fuel partial drain for every candidate item
- permanent settlement simulation
- a full logistics/vehicle hauling system

## Core Principle

The game should force prioritization through three intersecting pressures:

1. weight
2. heat
3. time

If one of those is weak, the scavenging fantasy becomes flatter.

## Carry Model

### Replace Count-Style Carrying With Total Weight

Every item should expose a gameplay-facing `weight`.

Inventory state should be evaluated against total carried weight, not only how many item rows are present.

### Carry States

The player’s current load is expressed through three bands:

- `적정`
- `과중`
- `과적`

### 적정

- baseline movement
- baseline fatigue behavior
- no hauling penalties

### 과중

- movement slows
- fatigue rises faster
- outdoor trips become riskier because time and heat loss both become less favorable

This is the state where the player can still keep looting, but should feel increasing pressure.

### 과적

- the player may still move
- the player may still try to return with what they already chose
- the player may not pick up additional items

This is important.

`과적` does not mean total immobility.

It means:

- the bag is full
- hands and pockets are effectively full
- the player has already committed to an overloaded carry-out

This preserves the fantasy of dragging too much home while still stopping infinite greed.

### Weight Presentation

UI should expose:

- `current weight / max supported weight`
- the current load band
- individual item weight in item rows and/or detail

The player should be able to do rough mental math.

The game should not hide this behind invisible formulas.

## Bags and Hauling Gear

Bags should not only increase a single top-line max number.

They should affect the hauling model more meaningfully.

### Bag Effects

A better bag can:

- increase maximum supported weight
- push back the start of `과중`
- push back the start of `과적`

This gives bags real strategic value.

They are not just “more slots.”

They change the radius and ambition of scavenging runs.

## Heat and Recovery Model

### Outdoor Rule

Outdoors causes heat loss.

This remains the main spatial survival pressure.

### Indoor Rule

Going indoors should stop further heat loss.

But it should not restore body heat by itself.

This distinction is critical.

Indoor spaces are shelter, not automatic recovery.

### Recovery Rule

Meaningful heat recovery requires an actual heat source.

This makes warmth equipment, fuel, and setup decisions matter.

## Heat Source Requirements

A usable heat setup should require three elements:

1. ignition tool
2. fuel
3. setup base

The player should not be able to produce meaningful warming “from empty air.”

### Ignition

Examples:

- lighter
- matches

### Fuel

Examples:

- paper fuel
- oil
- gas
- burnable scavenged material

### Setup Base

Examples:

- portable burner
- improvised can brazier
- small stove
- existing fixed building heater

## Heat Source Classes

### Fixed Heat Sources

Some indoor sites should include fixed, non-removable heating points:

- stove
- heater
- brazier
- boiler-linked warming area
- fireplace-like equivalent where appropriate

These are part of the site’s value and are not portable.

### Portable Heat Devices

Portable heat devices should be recoverable.

Examples:

- burner
- can brazier
- compact stove

They are allowed to be packed back up without forcing a “wait until cold” simulation.

That realism detail is intentionally abstracted away.

The meaningful cost is weight, not cooldown babysitting.

Portable heat devices should therefore:

- be recoverable
- be relatively heavy
- compete directly with food, water, fuel, and tools in carry planning

This creates a strong decision:

- travel light and rely on return
- or haul heat infrastructure and create a new temporary warming point deeper in the city

## Temporary Base Pressure

This spec supports two valid play patterns:

- raid and return
- carry enough setup to establish a new temporary camp

The player is not forced into one loop.

What matters is that the tradeoff is sharp enough to be interesting.

## Quantity-Bearing Supply Sources

### Why

Large-stock sites should not pretend they had only one unit of a common supply.

This is especially important for:

- marts
- convenience-stock style spaces
- hardware stores
- warehouses / storage sites

### What Changes

Some loot nodes become quantity-bearing supply sources rather than single-object reward rolls.

Examples:

- several cans available on a shelf
- multiple snack bars in a display
- multiple water bottles in a case
- many screwdrivers or clamps in a hardware section

The player then chooses how much to take.

### What Stays Individual

These should remain individual one-off pickups:

- keys
- notes
- rare tools
- unique crafted objects
- site-specific clues
- strong single finds

## Quantity Selection UX

The first pass should use a hybrid selection model.

Default quick options:

- `1개`
- `3개`
- `최대`
- `세부`

This keeps the common case fast while preserving deeper control when needed.

The point is not spreadsheet simulation.

The point is to let the player decide how aggressively to strip a supply source before weight and time push back.

## Partial-Use Candidate Policy

This pass does not yet implement full partial-consumption or partial-drain behavior.

However, certain items should be treated as future candidates for that system:

- bottled water
- jerrycans
- gas canisters
- cookie / cracker type food packs

These should be identified so a future pass can add partial use without restructuring the whole inventory model again.

## Relationship To Existing Content Work

This spec does not replace the current indoor depth expansion.

It gives that content a stronger survival frame.

The new building/item work remains useful, but now:

- a mart matters because stock volume and hauling choices matter
- a hardware store matters because tools and infrastructure compete with calories and fuel
- an apartment matters because shelter and domestic heat logistics matter
- a warehouse matters because large-capacity items and heavy infrastructure matter

## Recommended Implementation Order

### Phase 1

Weight and carry-state conversion:

- item weights
- total carry weight
- bag threshold bonuses
- `적정 / 과중 / 과적`
- pickup blocking in `과적`

### Phase 2

Heat pressure tightening:

- outdoor heat loss pressure
- indoor no-loss/no-recovery behavior
- heat-source-based recovery
- fixed vs portable heat source definitions

### Phase 3

Quantity-bearing supply sources:

- start with marts, hardware stores, and warehouses
- keep one-off pickups intact elsewhere
- ship fast selection UX first

### Phase 4

Optional future extension:

- partial-consumption candidates
- deeper carrying polish
- richer base relocation loops

## Success Criteria

This direction is correct when:

- the player cannot casually take everything they want
- large-stock sites feel meaningfully stocked
- warmth items, fuel, and hauling tools feel genuinely valuable
- indoor shelter stops heat decline but does not trivialize recovery
- the player naturally asks “can I get there and back?” or “can I establish heat there?”
- loot choice becomes more about future survivability than about vacuuming whatever the generator handed out
