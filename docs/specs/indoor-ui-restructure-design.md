# Indoor UI Restructure Design

- Status: approved
- Created: 2026-04-02
- Last updated: 2026-04-02
- Scope: first major indoor UI/UX restructuring for readable mobile-first play

## Purpose

Replace the current "everything visible at once" indoor layout with a cleaner reading-first interface that matches the game's actual decision loop.

The current indoor UI exposes too many simultaneous information surfaces:

- shared HUD
- current zone text
- result text
- action list
- minimap
- carried inventory
- equipped gear

This makes the screen feel noisy, forces the player to read too much before acting, and gets worse as more systems are added.

## Design Role

This design defines the indoor screen as a focused text-adventure surface rather than a dashboard.

It does **not** redesign outdoor UI.
It does **not** finalize art direction.
It does **not** add new survival rules.

Its purpose is to give the existing indoor loop a stable presentation model before more systems are layered on top.

## Core Goals

1. Make the indoor screen readable at a glance
2. Keep the player's attention on current location, current situation, and current choices
3. Remove duplicated information between the indoor screen and the shared HUD
4. Keep the design compatible with mobile play
5. Preserve minimap, inventory, and equipment access without keeping them permanently on-screen

## Design Summary

Indoor play should use a dedicated screen structure with three priorities:

1. `Where am I?`
2. `What is happening here right now?`
3. `What can I do next?`

Anything that does not directly support those three questions should move out of the main surface.

## Main Indoor Screen

The main indoor screen should contain only the following persistent sections.

### Top Bar

The top bar is the permanent indoor replacement for the currently overloaded shared HUD.

It should show:

- building name
- current zone name
- current clock label
- compact survival stat chips for:
  - `허기`
  - `갈증`
  - `체력`
  - `피로`

These should be concise and stage-based.

Examples:

- `허기: 보통`
- `갈증: 목마름`
- `체력: 안정`
- `피로: 피곤`

The top bar should feel like a compact status strip, not a large info panel.

### Main Reading Area

This is the center of the indoor screen and should stay visually dominant.

It should contain:

- current zone description
- recent result / recent action feedback

The zone description tells the player what the current place is like.
The result block tells the player what just happened.

These must remain visually separated.

The player should never have to parse old clues, unrelated inventory text, and current situation text from the same area.

### Action Area

The action area stays on the main screen, but it should only show current actionable choices.

Actions remain grouped by meaning:

- movement
- search / interaction
- discovered loot
- locked routes

The structure should still use grouped actions because this improved readability in the current prototype, but the visual emphasis should shift toward fewer, clearer blocks with more spacing and stronger section contrast.

## Information Removed From the Main Surface

The following should no longer be permanently visible on the indoor screen:

- minimap
- carried inventory list
- equipped gear list
- large status sidebars
- secondary system descriptions

These are not removed from the game. They are removed from the main reading surface.

## Minimap Presentation

The minimap should become a dedicated overlay rather than a permanently visible sidebar.

### Minimap Trigger

The indoor UI should expose a simple `구조도` button in or near the top bar.

Pressing it opens a minimap overlay.

### Minimap Overlay Rules

The minimap keeps the current discovery rules:

- visited rooms are shown
- the current room is highlighted
- immediately adjacent unknown rooms show as `?`
- locked routes remain marked as locked

But it should be shown only when the player explicitly asks for it.

This keeps navigation help available without competing with the reading surface all the time.

## Inventory and Equipment Presentation

Inventory and equipment should be merged into a single indoor inventory sheet.

### Inventory Trigger

The indoor UI should expose a `가방` button in or near the top bar.

Pressing it opens a bottom sheet or slide-up panel.

### Inventory Sheet Content

The inventory sheet should contain:

- current carry usage
- carried items
- equipped items

The sheet should support switching focus between:

- carried items
- equipped gear

This can be done as tabs, segmented buttons, or grouped sections inside the same sheet.

The key design rule is that the player should not need to visually compare two separate permanent lists to understand what is worn versus what is carried.

### Item Detail Flow

Selecting an item still opens its action panel.

That panel should continue to show:

- item name
- short description
- exact stat effects
- available actions

Examples:

- `허기 +10`
- `갈증 +30`
- `체력 +12`
- `피로 -8`
- `소요 시간 10분`

## Shared HUD Rule

The current shared HUD should not remain fully active during indoor play.

Indoor mode should either:

- hide the shared HUD entirely, or
- reduce it to a non-competing minimal layer that duplicates nothing already present in the indoor top bar

The preferred direction is:

- outdoor uses the shared HUD
- indoor uses its own dedicated status top bar

This keeps indoor and outdoor presentation aligned with their different play styles.

## Mobile-First Behavior

This redesign assumes phone play is a real target, not an afterthought.

Therefore:

- the main reading surface must stay vertically readable
- always-visible sidebars should be avoided
- optional information should live in overlays or sheets
- large touch targets matter more than dense dashboards

The indoor interface should feel like:

- read current situation
- tap a choice
- open map if needed
- open bag if needed

not:

- scan a dashboard
- compare multiple side panels
- search for the relevant text block

## Visual Hierarchy Rules

The new indoor UI must make hierarchy obvious even without final art.

Required hierarchy:

1. current zone
2. current situation text
3. available actions
4. recent result
5. optional tools such as minimap and bag

If a player has to concentrate to tell whether something is:

- status
- current room description
- result feedback
- inventory
- map

then the hierarchy is still wrong.

## Migration Guidance

The restructuring should be done without changing indoor gameplay rules.

That means:

- no change to discovery rules
- no change to action semantics
- no change to loot ownership rules
- no change to minimap visibility logic

Only presentation and UI interaction surfaces should change in this pass.

## Out of Scope

This design explicitly excludes:

- final art polish
- outdoor UI redesign
- stat rebalance
- new item systems
- deeper touch gestures
- controller support

## Expected Outcome

After this redesign:

- indoor play should feel calmer and easier to read
- the player should understand current context faster
- minimap and bag should still be accessible without flooding the screen
- future systems can be added with much less visual clutter
