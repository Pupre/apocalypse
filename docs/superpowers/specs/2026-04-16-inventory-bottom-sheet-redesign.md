# Inventory Bottom Sheet Redesign

- Status: active
- Date: 2026-04-16

## Goal

Replace the current always-split inventory/detail presentation with a stronger mobile-first bag surface:

- the bag opens to a list-first view
- item detail appears as a bottom detail sheet only after selection
- crafting remains contextual inside the detail sheet
- indoor and outdoor should converge on the same bag interaction model

## Problem

The current `SurvivalSheet` still spends too much vertical space on detail all the time.

That creates three concrete problems:

- the player cannot scan the bag quickly enough on a portrait screen
- the list feels cramped and scroll-heavy even when the bag contains only a modest number of items
- the bag stops feeling like the primary surface because the detail card dominates the composition

The user intent is explicit:

- the bag itself should be the main thing
- detail should appear when needed, not occupy the base layout permanently
- the game should stop feeling like it is always forcing the player to read a secondary panel

## Core Principle

The default state of the inventory UI should optimize for browsing, not inspection.

- browsing is the default
- inspection is contextual
- crafting is secondary to the bag

The bag should feel like a fast, readable inventory list first, and only then a place for detailed decisions.

## Chosen Structure

### 1. List-First Base State

When the bag opens, the primary surface is the item list.

- the list fills most of the vertical space
- the player can immediately scroll and scan items
- no large persistent detail card competes for space

This is the default state for both indoor and outdoor use.

### 2. Detail As A Bottom Sheet

When the player selects an item, a bottom detail sheet rises over the lower portion of the bag.

- the list stays visible behind it
- the player still feels anchored in the bag
- closing detail returns focus to the list rather than leaving empty unused space
- the region physically covered by the detail sheet should be treated as blocked, not as still-usable visible list space
- items hidden under the detail sheet are not expected to be readable or directly selectable until they are scrolled back into the exposed list area

The detail sheet is a contextual overlay, not a permanent region.

### 3. Crafting Stays Inside Detail

Crafting should continue to be initiated from the selected item detail.

- `조합 시작` remains a secondary action inside the detail sheet
- crafting mode still anchors on one selected item
- compatible hints in easy mode still work
- failed combinations remain allowed

This keeps the previously approved contextual crafting flow while putting it inside a more readable bag surface.

### 4. Codex Stays In The Same Surface For Now

In this pass, codex stays inside the same shared `SurvivalSheet` rather than becoming a separate screen.

This is a scope-control choice.

- the bag redesign should solve browsing first
- codex can stay as a secondary tab or secondary mode inside the same sheet
- the visual hierarchy must make the bag feel primary even when codex remains attached

The redesign should not over-solve codex navigation in the same pass.

## Layout Rules

### Base Bag View

- header remains compact
- the item list becomes the dominant surface
- list rows should be dense enough to browse quickly, but still legible
- the player should not need to scroll because of wasted detail space

### Detail Sheet

- opens only when an item is selected
- occupies the lower portion of the screen, not the entire sheet
- can be dismissed explicitly
- should prioritize the selected item’s name, description, and current actions
- should use an opaque, solid panel treatment rather than a translucent card that visually mixes with the list below
- should own input in the area it covers so the player only interacts with the still-visible list region above it

### Action Hierarchy

Inside detail:

- primary actions remain direct item actions such as `사용`, `장착`, `읽는다`, `버린다`
- `조합 시작` remains secondary
- crafting mode can alter the detail sheet state, but should not replace the bag-first layout

## Indoor / Outdoor Convergence

The redesigned bag should be shared.

- indoor should keep using `SurvivalSheet`
- outdoor should stop depending on the separate `CraftingSheet` / `CodexPanel` pair for bag-like interactions
- outdoor should open the same `SurvivalSheet` from HUD-level controls

This does not require indoor and outdoor to expose identical chrome, but it does require the actual bag interaction grammar to be the same.

## Expected Flow

### Browse

1. player opens bag
2. list dominates the screen
3. player scrolls or taps an item

### Inspect

1. bottom detail sheet rises
2. player reads item description and actions
3. player either acts, starts crafting, or closes detail

### Craft

1. player chooses `조합 시작`
2. bag remains the main surface
3. player selects another item
4. detail sheet updates to the current contextual craft state
5. success swaps the detail sheet to the crafted result
6. failure leaves the current item and feedback in place

## Out Of Scope

Not in this pass:

- redesigning codex information architecture beyond preserving it inside the same sheet
- replacing the indoor minimap
- replacing the full outdoor map
- changing item rules, recipe logic, or inventory data model
- adding save/load behavior

## Testing Requirements

Implementation should verify at least:

- the bag opens to a list-dominant state
- detail is not permanently occupying the main layout before item selection
- selecting an item opens the bottom detail sheet
- closing detail returns to a list-first state
- contextual crafting still works from detail
- indoor still uses the redesigned `SurvivalSheet`
- outdoor can open the same redesigned `SurvivalSheet`

## Replacement Note

This spec supersedes the current always-visible inventory/detail split inside `SurvivalSheet` as the player-facing target.

The contextual crafting rules from `2026-04-09-contextual-crafting-ui-design.md` still apply, but they must now live inside a stronger list-first inventory presentation.
