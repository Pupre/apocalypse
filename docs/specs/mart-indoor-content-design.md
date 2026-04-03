# Mart Indoor Content Design

- Status: approved
- Created: 2026-04-01
- Last updated: 2026-04-01
- Scope: first deep indoor building design for the prototype

## Purpose

Define the first full indoor content pattern for the prototype by turning the current simple mart event into a connected, replayable building exploration structure.

This document fixes the content grammar for one building deeply enough that the same approach can later be reused for apartments, hospitals, and offices.

## Design Role

The mart is the prototype's reference indoor building.

- It should establish the indoor content standard before more building types are added
- It should emphasize scavenging and resource judgment first
- It should support indirect clues, locked progression, and human encounter events
- It should stay flexible enough to absorb future story decisions without rewriting the system

## Core Goals

1. Make indoor exploration feel like navigating a real connected space rather than picking flat menu cards
2. Make the player's main indoor question "what is worth my time and risk right now?"
3. Let the building gradually open through clues, keys, tools, and forced-entry choices
4. Make human encounters part of survival judgment rather than a separate dialogue system
5. Keep the structure data-driven so new content can be added without rewriting core logic

## Fixed Direction

### Building Profile

- Building type: `2-floor medium neighborhood mart`
- Floor 1: customer-facing retail floor
- Floor 2: staff-only back-of-house floor

### Floor Tone

- Floor 1 should feel safer, more readable, and more reliable for normal survival supplies
- Floor 2 should feel more valuable, more human, and more unsettling
- The emotional shift when moving from Floor 1 to Floor 2 should be immediate

### Access Philosophy

- The player should not begin with free access to every important area
- Core progression should come from finding routes, clues, keys, tools, and forced-entry options
- The building should reward both careful planning and risky improvisation

## Exploration Model

### Connected Zone Structure

The mart uses a connected zone map, not a flat action list.

- The player can only move to zones connected to the current zone
- The building should feel spatial rather than abstract
- Route choice should matter because time and danger costs differ by path

### Time Costs

Initial prototype values:

- first-time zone entry: `30 minutes`
- revisiting a previously explored adjacent zone: `10 minutes`

These numbers are balance placeholders and are expected to change during playtesting.

### Player-Facing Structure

The player should experience the building as:

1. enter the current zone
2. read visible clues and tension signs
3. pick a zone action or move to a connected zone
4. spend time and possibly generate noise or risk
5. unlock new information, new routes, or new consequences

## Zone Layout

### Floor 1 Zones

- `mart_entrance`
  - the opening orientation space
  - little direct loot
  - introduces the tone of how recently the mart was searched

- `checkout`
  - early low-risk search area
  - source of small supplies and back-of-house hints

- `food_aisle`
  - reliable normal survival resource zone
  - mostly food and water

- `household_goods`
  - operations and utility zone
  - likely source of bags, tape, batteries, and pry tools

- `cold_storage`
  - mixed-value supply zone
  - possible drinks and food, but quality is uncertain

- `back_hall`
  - transition space between public and private areas
  - strong place for human traces and ambush tension

- `staff_corridor_gate`
  - first hard gate into the staff layer
  - first major decision between clean access and forced entry

### Floor 1 Connections

- `mart_entrance -> checkout`
- `mart_entrance -> food_aisle`
- `checkout -> staff_corridor_gate`
- `food_aisle -> household_goods`
- `food_aisle -> cold_storage`
- `household_goods -> back_hall`
- `cold_storage -> back_hall`
- `back_hall -> staff_corridor_gate`

### Floor 2 Zones

- `stair_landing`
  - the first unsettling staff-floor space
  - establishes that someone may have remained here recently

- `break_room`
  - best place for human traces and weakly friendly encounters

- `office`
  - clue, key, memo, and management-information zone

- `warehouse`
  - high-value supply zone
  - likely place for guarded resources or hostile encounters

- `locked_storage`
  - the mart's strongest temptation zone
  - late-access high-risk room for special rewards or future story payload

### Floor 2 Connections

- `staff_corridor_gate -> stair_landing`
- `stair_landing -> break_room`
- `stair_landing -> office`
- `stair_landing -> warehouse`
- `warehouse -> locked_storage`

## Information and Clue Design

### Clue Style

The mart should use indirect clues as the default.

Examples:

- "The drawer is closed, but it does not look hastily forced open."
- "Only one hook on the staff key board is empty."
- "A blanket in the break room has not fully lost its warmth."
- "Drag marks lead deeper into the rear hall."

Direct clues should exist, but only occasionally.

Examples:

- an explicit note about a storage key
- a labeled office key ring
- a marked staff notice about restricted access

### Clue Function

Clues should do real gameplay work.

- reveal likely reward type
- hint at human presence
- suggest whether a route is worth pushing
- reveal that a different zone should be revisited later
- foreshadow locked or dangerous content

## Event Grammar

### Chosen Approach

The building uses a node-linked indoor event grammar.

Each zone exposes events through a common structure rather than hardcoded building-specific logic.

### Required Event Fields

- `zone`
  - where the event belongs
- `hint`
  - what the player notices before committing
- `options`
  - what the player can do
- `requirements`
  - key, tool, clue, flag, or other gating condition
- `costs`
  - time, fatigue, noise, or durability cost
- `risks`
  - ambush, loss, failure, or escalation possibility
- `outcomes`
  - loot, clue reveal, state change, unlocked route, or triggered follow-up
- `next`
  - optional follow-up event or newly available route

### Why This Grammar

This one grammar can support:

- ordinary searching
- locked doors
- forced entry
- human encounters
- noise consequences
- recovery choices

It also keeps the content extensible when the story becomes more specific later.

## Event Type Families

### 1. Basic Search

The most common event type.

- search a drawer
- check a lower shelf
- inspect a damaged fridge
- open a locker

Primary purpose:

- generate ordinary survival resources
- reveal clues
- consume time in a readable way

### 2. Access and Opening

Used for gates, doors, blocked areas, and back-of-house progression.

- use a key
- use a tool
- force a shutter
- break a window

Primary purpose:

- convert space into progression
- create meaningful tradeoffs between safe and noisy routes

### 3. Human Encounter

Human encounter is an event type, not a full NPC simulation.

Examples:

- a cautious survivor hiding near the counter
- a weak trader in the break room
- a fake trade that turns into a trap
- the player choosing to strike first

Core options should usually include:

- approach carefully
- offer trade
- back away
- strike first

Primary purpose:

- make other humans part of resource and risk judgment
- broaden the survival tone without needing a full relationship system yet

### 4. Noise Reaction

Used as the delayed consequence layer for forced entry and rough scavenging.

- breaking glass
- forcing a gate
- dragging heavy goods

Primary purpose:

- turn reckless efficiency into downstream risk
- change how later events in nearby zones resolve

### 5. Recovery and Reset

A smaller event type for pacing control.

- sit briefly in the break room
- repack inventory
- consume found food immediately

Primary purpose:

- let the player stabilize before pushing deeper
- make indoor time management less one-note

## Human Encounter Rules

### Current Prototype Scope

Human encounters should ship first as strong standalone events.

- They may be helpful
- They may offer barter
- They may flee
- They may deceive the player
- They may attack
- The player may also choose to act aggressively first

### Future Expansion Path

Some encounter outcomes may later be upgraded into persistent returning characters or relationship threads.

The first mart implementation should leave room for that, but it should not require persistent NPC systems yet.

## Risk Structure

### Primary Risk

The mart's main threat should be other survivors and human traces.

The tension should come from:

- who searched here before
- who might still be here
- whether an encounter is worth the risk

### Secondary Risk

Noise escalation.

Forced entry and rough handling should make later encounters or ambushes more likely.

### Light Environmental Risk

Use environmental danger sparingly.

Examples:

- broken glass
- slippery fridge runoff
- clutter that slows movement or search efficiency

Environmental risk supports the atmosphere but should not overshadow the human threat layer in this building.

## Story Flexibility

This design must stay compatible with future narrative decisions.

- The mart's space layout is fixed independently from the apocalypse cause
- Clues should be written so they can later be tuned toward nuclear fallout, spores, dangerous lifeforms, or another finalized premise
- Human encounter events should be able to absorb later story tags without changing their base structure
- Resource items should allow future mechanical fields such as hunger value, spoilage, or contamination without changing the building format

The system is intentionally designed so story detail can be layered in later instead of requiring a rewrite.

## Implementation Guidance

The first implementation pass should separate:

- reusable indoor system rules
- building structure data
- zone data
- event data
- runtime zone state

Nothing about the mart should require hardcoded one-off logic that blocks later building additions.

The mart is the first deep building, not a special case.

## Out of Scope

This spec does not yet define:

- the full hospital, apartment, or office content sets
- a persistent NPC relationship system
- combat resolution rules
- hunger as a finalized mechanic
- the finalized apocalypse story premise

## Acceptance Criteria

- The mart can no longer be represented as one flat indoor event card
- The player moves through connected zones with different costs and different risk profiles
- Floor 1 provides mostly reliable baseline resources
- Floor 2 provides more tension, more human traces, and more valuable opportunities
- At least one meaningful clean-access vs forced-entry decision exists
- Human encounters fit inside the same event grammar as other indoor content
- The design remains data-driven enough to support future building expansion and future story integration
