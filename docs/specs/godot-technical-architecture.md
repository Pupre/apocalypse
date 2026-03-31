# Godot Technical Architecture

- Status: approved
- Created: 2026-03-31
- Last updated: 2026-03-31
- Scope: prototype engine baseline and runtime architecture

## Purpose

Define how the approved hybrid survival design maps into a Godot project so implementation can start without re-deciding the engine, language, or project structure.

## Fixed Technical Decisions

- Engine: Godot `4.4.1` stable
- Scripting language: `GDScript`
- Primary target: `Android`
- Secondary target: `iOS` later, after the Android prototype is stable
- Development machines: Linux and Windows must both be supported
- Prototype focus: text-based source-controlled assets wherever practical
- Out of scope for the prototype: `C#`, cloud services, online features, console targets

## Why This Stack

This project benefits from a text-first toolchain.

- Godot scenes, project settings, and scripts are source-control friendly
- `GDScript` keeps iteration fast for a systems-heavy prototype
- Android export is officially supported and already matches the team's target order
- Linux and Windows can share the same repository without special engine-side workflow hacks

## Technical Goals

1. Preserve the approved split between real-time outdoor play and text-driven indoor play
2. Keep one authoritative run state for time, fatigue, inventory, and survivor status
3. Let Codex implement most of the project through text files instead of editor-only authoring
4. Keep content data easy to diff, review, and extend
5. Start mobile-first without blocking desktop development and debugging

## Project Principles

### Text-First Development

- Prefer `.gd`, `.tscn`, `.tres`, and `.json` files that can be reviewed in Git
- Avoid workflows that require frequent hand-authoring inside the editor when a text asset will do

### Single Source of Truth

- The current run must be owned by one runtime authority
- Time, fatigue, inventory, and survivor state cannot be duplicated across UI or mode scenes

### Mode Isolation

- Outdoor and indoor gameplay should be separate runtime modules with a narrow transition boundary
- Each mode can update the same run state, but neither mode should own the overall run lifecycle

### Data-Driven Content

- Jobs, traits, buildings, loot tables, and event definitions should live in data files
- Prototype balancing should mostly change data, not engine code

### Mobile-First, Desktop-Friendly

- Core input must be abstracted through Godot actions instead of hard-coded device assumptions
- Desktop keyboard and mouse support is required for fast development iteration

## Planned Repository Layout

The repository is still docs-first. When implementation starts, the Godot project should live under a dedicated `game/` directory.

```text
game/
  project.godot
  icon.svg
  scenes/
    bootstrap/
      main.tscn
    menus/
      title_menu.tscn
      survivor_creator.tscn
    run/
      run_shell.tscn
      hud.tscn
    outdoor/
      outdoor_mode.tscn
      player.tscn
    indoor/
      indoor_mode.tscn
      event_panel.tscn
  scripts/
    autoload/
      app_router.gd
      content_library.gd
      save_repository.gd
    run/
      run_controller.gd
      run_state.gd
      time_clock.gd
      fatigue_model.gd
      inventory_model.gd
    indoor/
      indoor_director.gd
      indoor_action_resolver.gd
    outdoor/
      outdoor_controller.gd
      exposure_model.gd
  data/
    jobs.json
    traits.json
    buildings.json
    events/
      indoor/
      outdoor/
  assets/
    placeholder/
```

## Runtime Architecture

### App Layer

The boot layer should stay thin.

- `app_router.gd`: switches between title, survivor creation, and active run flow
- `content_library.gd`: loads and validates static game data
- `save_repository.gd`: reads and writes local save slots

Only cross-run services belong in autoloads.

### Run Layer

The active run should be owned by one coordinator scene.

- `run_shell.tscn`: persistent shell for HUD, modal panels, and active mode scene
- `run_controller.gd`: owns the run lifecycle and transitions between outdoor and indoor modes
- `run_state.gd`: canonical mutable run data for the current survivor

`run_state.gd` is the single source of truth for:

- current day and minute
- survivor identity, job, and traits
- fatigue, hunger, health, and the outside exposure resource
- inventory and equipped items
- current location, known buildings, and temporary base state

### Outdoor Layer

Outdoor play is a real-time scene module.

- `outdoor_mode.tscn`: map presentation, threats, interactables, and traversal loop
- `outdoor_controller.gd`: movement, time ticking, encounter timing, and map interaction
- `exposure_model.gd`: outside exposure depletion and modifiers from movement or danger

Outdoor mode must not directly decide run progression on its own. It reports meaningful outcomes back to `run_controller.gd`.

### Indoor Layer

Indoor play is a turn-resolution module.

- `indoor_mode.tscn`: text panel, choice list, risk hints, and results
- `indoor_director.gd`: building state, available actions, and scene progression
- `indoor_action_resolver.gd`: applies action costs, outcomes, and event consequences to the run state

Indoor mode is deliberately slower and more inspectable than outdoor mode.

## State and Data Model

### Canonical Time Representation

- Store time as `day_index` plus `minute_of_day`
- Indoor actions consume fixed minute costs, usually `60`
- Outdoor play advances time continuously using the approved baseline:
  - `1` real second = `1` in-game minute
- Sleep advances the same clock by the computed sleep duration

This keeps every subsystem on one shared timeline.

### Survivor State

The run state should at minimum track:

- identity seed
- job id
- selected trait ids
- current stats and derived modifiers
- fatigue value and fatigue band
- inventory contents and carry limit
- current temporary base id
- known world locations and their explored state

### Content Format

Use `JSON` for prototype gameplay data that designers or Codex will edit often.

Expected candidates:

- jobs
- traits
- loot tables
- building metadata
- indoor event definitions

Use Godot scene and resource files for:

- runtime nodes
- UI layouts
- reusable scene composition
- placeholder audiovisual assets

## Time and Fatigue Rules

The technical implementation must preserve the agreed design intent.

- Outdoor hesitation, detours, combat, and fleeing all consume shared day time
- Indoor actions consume hour-sized chunks unless a specific action says otherwise
- Sleep is optional and indoor-only
- Sleep duration depends on fatigue and survivor modifiers
- Fatigue must have immediate gameplay penalties before sleep happens

For readability, fatigue should be stored numerically but surfaced to players in bands such as:

- light
- steady
- tired
- exhausted
- critical

Any sleep UI should preview:

- estimated wake time
- expected fatigue recovery
- alarm-style wake risk if an item or trait modifies sleep

## Scene Flow

The first playable prototype should follow this scene sequence:

1. `main.tscn`
2. `title_menu.tscn`
3. `survivor_creator.tscn`
4. `run_shell.tscn`
5. transition between `outdoor_mode.tscn` and `indoor_mode.tscn` without unloading the run shell

This keeps the run HUD and shared state stable while only the active gameplay layer changes.

## Input Strategy

- Define shared Godot input actions for movement, confirm, cancel, interact, and UI navigation
- Support keyboard and mouse for development
- Add touch bindings in a way that does not change game logic code
- Keep touch layout decisions outside the first architecture boundary when possible

## Save Strategy

- Start with local save slots only
- Keep saves versioned with a lightweight schema field
- Favor human-inspectable save data during prototype development

## Prototype Scope Guardrails

The first implementation pass should include:

- Godot project bootstrap
- title flow
- survivor creation with sample jobs and traits
- shared clock
- fatigue and sleep foundation
- outdoor traversal prototype
- indoor text exploration prototype
- basic inventory and loot transfer

The first pass should not include:

- polished combat depth
- final art direction
- procedural world generation beyond what the prototype needs
- narrative campaign content
- iOS export work

## Cross-Platform Development Rules

- Keep filenames lowercase with underscores
- Never rely on case-only renames
- Do not commit machine-specific SDK paths
- Do not hard-code Linux-only or Windows-only absolute paths inside runtime code
- Keep engine version aligned across both workstations

## Success Condition

This architecture is successful when the repository can support a first playable build where one survivor can:

- be created from a job and trait combination
- spend shared time indoors and outdoors
- accumulate fatigue and sleep intentionally
- collect and move items
- enter and leave buildings cleanly
- die and end the run
