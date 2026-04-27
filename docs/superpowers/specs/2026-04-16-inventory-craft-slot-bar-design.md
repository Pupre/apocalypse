# Inventory Craft Slot Bar Design

- Status: active
- Date: 2026-04-16

## Goal

Replace the current lightweight craft-status text inside the bag with a clearer craft-state presentation that still keeps the bag as the main surface.

The new presentation should:

- keep the inventory list as the primary UI
- add an explicit craft state card only after `조합 시작`
- show `재료 1` and `재료 2` as concrete item slots
- preserve the current detail sheet so item descriptions and actions remain available
- require an explicit `조합` confirmation instead of auto-crafting

## Problem

The current bag-first crafting flow is directionally correct, but the state expression is too weak.

Right now the UI effectively reduces craft mode to a short text status such as `조합 중: 식용유`.

That creates three concrete problems:

- the player cannot see craft state at a glance
- the bag does not clearly communicate which item is locked as the first material
- the interface feels like hidden mode state instead of visible inventory manipulation

The user intent is explicit:

- crafting should still happen inside the bag
- the bag should not turn back into a separate dedicated crafting screen
- but the current craft state should be represented more concretely than plain text

## Core Principle

Crafting state should be visible, but crafting interaction should remain subordinate to the bag.

- the bag remains the primary screen
- the craft card is a temporary layer on top of the bag
- the craft card shows state, not a separate dedicated crafting screen
- selecting materials still happens through the normal bag list and detail flow

The design should make crafting feel more explicit without making it the new main surface.

## Chosen Structure

### 1. Craft Card Appears Only In Craft Mode

The bag opens normally in browse/inspect mode.

When the player taps `조합 시작` from item detail:

- a separate craft card appears above the inventory list, inside the same bag shell
- `재료 1` is filled with the item that initiated crafting
- `재료 2` is shown as empty until the player chooses another item
- the rest of the bag remains intact below it

Outside craft mode, this card is absent.

### 2. Material 1 Is Fixed, Material 2 Is Contextual

Craft mode begins from a selected item.

- the selected item becomes `재료 1`
- subsequent list selections automatically target `재료 2`
- selecting a different candidate item replaces `재료 2` immediately

This removes unnecessary micro-steps.

The player does not manually pick which slot to fill after crafting has started.

### 3. The Detail Sheet Remains Alive

The item detail bottom sheet still matters during craft mode.

- selecting a candidate item still opens or updates detail
- the player can continue reading description and actions
- the detail sheet remains the place where the explicit `조합` confirmation lives

The craft card shows state.

The detail sheet still carries inspection and action context.

### 4. Craft Completion Requires Explicit Confirmation

Selecting a second item should not auto-complete the recipe.

Instead:

1. `재료 1` is fixed
2. `재료 2` is selected or replaced from the list
3. the player presses `조합`
4. only then is the craft attempt resolved

This preserves the deliberate feel the user asked for.

### 5. No Result Preview

The craft card should not become a recipe spoiler UI.

- no explicit result slot
- no pre-emptive success/failure wording
- no “허탕 조합” phrasing before the attempt resolves

The UI should stay neutral:

- `조합 시작`
- `조합`
- `취소`

## Layout Rules

### Craft Card

- appears above the list, inside the same bag surface, as an additional panel rather than inline text
- shows `재료 1`, `재료 2`, and compact `조합` / `취소` controls
- should be visually distinct from the base bag surface
- should read as a temporary auxiliary window layered onto the bag, not as a header status strip
- should not consume so much height that the list stops being the main surface

### Inventory List During Craft Mode

- remains scrollable
- remains the main browsing surface
- easy-mode compatibility hints can still highlight likely `재료 2` candidates
- non-highlighted items remain selectable so failed attempts are still possible

### Detail Sheet During Craft Mode

- continues to show the currently selected candidate item
- remains the place where description is read
- should make it obvious that the player is choosing or replacing `재료 2`
- should continue to cover and own the lower portion of the list so the player only scrolls and selects from the visible exposed list area

## Expected Flow

### Start Craft

1. player opens bag
2. player selects an item
3. player taps `조합 시작`
4. craft card appears
5. selected item is locked into `재료 1`

### Select Candidate

1. player browses the same bag list
2. tapping another item assigns it to `재료 2`
3. tapping a different item replaces `재료 2`
4. detail updates to the newly selected candidate

### Confirm

1. player presses `조합`
2. craft attempt resolves
3. success swaps the detail sheet to the resulting item
4. failure preserves bag context and shows feedback without destroying the current bag-first layout

### Cancel

1. player presses `취소`
2. craft card disappears
3. bag returns to normal inspect/browse state

## Indoor / Outdoor Behavior

The same craft card behavior should apply anywhere the shared bag opens.

- indoor uses the same bag-first craft presentation
- outdoor uses the same bag-first craft presentation
- no mode-specific slot UI forks

This is a shared `SurvivalSheet` behavior, not an indoor-only or outdoor-only variation.

## Out Of Scope

Not in this pass:

- recipe logic changes
- adding result previews
- adding more than two material slots
- redesigning codex information architecture
- replacing the outdoor full-map stack
- changing save/load behavior

## Testing Requirements

Implementation should verify at least:

- `조합 시작` causes the craft card to appear
- `재료 1` is populated from the initiating item
- selecting another item fills `재료 2`
- selecting a different item replaces `재료 2`
- the list remains the main bag surface during craft mode
- `조합` must be pressed explicitly to resolve the attempt
- canceling exits craft mode cleanly
- indoor and outdoor shared bag flows both use the same craft bar behavior

## Relationship To Existing Specs

This spec extends `2026-04-16-inventory-bottom-sheet-redesign.md`.

That document defines the bag as a list-first surface with bottom detail.

This document defines how contextual crafting should be expressed inside that redesigned bag.

It also refines the player-facing presentation of the contextual crafting rules from `2026-04-09-contextual-crafting-ui-design.md` without changing the core gameplay intent:

- bag remains primary
- failed attempts remain allowed
- easy mode may hint, but not restrict
