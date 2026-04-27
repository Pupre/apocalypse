# Toast Feedback System Design

- Status: active
- Date: 2026-04-20

## Goal

Add a small shared toast system that gives immediate short-form feedback without replacing the existing result text surfaces.

The target is simple:

- short actions should feel responsive
- indoor and outdoor should use the same toast behavior
- the screen should not fill with stacked notifications

## Problem

The game already generates many short feedback messages:

- item pickup
- bag full
- craft success or failure
- note/recipe discovery
- short danger or condition warnings

Right now those messages mostly live inside existing labels, result cards, or inventory detail text.

That causes two visible problems:

- feedback is easy to miss because it is buried inside larger UI surfaces
- reactions feel slower than the action that caused them

The user intent is explicit:

- add toast-level immediacy
- keep current result text for now
- do not overcomplicate the screen with stacked notifications

## Core Principle

Toast is for immediate reaction, not for history.

- toast = fast, short, disposable
- result text = retained context inside the current screen

These two layers should coexist rather than replace each other in this pass.

## Chosen Behavior

### 1. Single Shared Toast

The game uses one shared toast surface for both indoor and outdoor flows.

- one toast presenter
- one active toast at a time
- same rendering logic everywhere

This keeps the behavior predictable and avoids duplicated UI logic.

### 2. One Visible Toast At A Time

Toasts do not stack.

- only one toast is visible at once
- a new toast replaces the previous toast immediately
- if the same message is shown again, the display timer refreshes instead of creating a duplicate

This is the right mobile-first behavior because screen space is limited and stacked toasts would quickly feel noisy.

### 3. Automatic Dismissal

Toasts appear briefly and then disappear on their own.

Target behavior:

- default lifetime around `1.8s` to `2.4s`
- no manual dismissal required
- no queue UI exposed to the player

This is intentionally lightweight.

### 4. Three Toast Types

This pass supports exactly three types:

- `info`
- `success`
- `warning`

These map directly to the available micro-feedback pack and are enough for the current gameplay language.

Examples:

- `info`: neutral discovery or read feedback
- `success`: crafted item, item pickup, successful equip/use result
- `warning`: bag full, blocked action, worsening cold/risk

## Placement

Toast should sit directly below the top ribbon / HUD area.

- visible enough to read immediately
- not covering the center of the world or the indoor action list
- consistent between indoor and outdoor

This placement makes the toast feel like a global reaction layer rather than a local card.

## Relationship To Existing UI

### Keep Existing Result Text

Current result/feedback text in indoor cards, inventory detail, and related UI remains in place for now.

This pass does not remove or replace existing message surfaces.

Instead:

- toast gives the immediate reaction
- existing result text remains as contextual history inside the current screen

The user will evaluate the feel of this overlap later. That decision is intentionally deferred.

### Do Not Turn Toast Into A Status Chip

This spec does not add persistent status chips yet.

The feedback micro pack includes status-chip art, but that should not be forced into the UI until there is a real persistent-state use case.

This pass is toast-only.

## Trigger Scope

The following event families should be toast-eligible in this pass:

- indoor loot pickup
- outdoor bag actions with immediate feedback
- crafting result
- recipe/note knowledge gain
- blocked or warning-grade interaction feedback

Longer descriptive text should remain in existing cards and not be copied wholesale into toast.

Toast text should stay short.

## Data / API Shape

The implementation should normalize toast requests into a compact shared shape:

- `type`
- `message`
- optional `duration`

The system should stay presentation-focused and should not create a new gameplay rule layer.

## Out Of Scope

Not part of this pass:

- stacked toast queues
- persistent status chips
- message history log
- replacing indoor result cards
- replacing bag/status labels
- sound design or vibration hooks

## Testing Requirements

Implementation should verify at least:

- only one toast is visible at a time
- a new toast replaces the old one
- same-message replay refreshes the timer
- toast auto-hides after duration
- indoor and outdoor can both trigger the shared toast
- existing result text remains intact

