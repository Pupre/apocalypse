# Compact UI Devkit v2 Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the currently-applied v1 UI skin on the visible portrait surfaces with `frozen_ui_compact_devkit_v2`.

**Architecture:** Keep the current portrait UI structure and swap only the surface assets and sizing rules. Update the UI kit resolver to understand the new manifest shape, then apply the compact HUD, indoor, sheet, and overlay assets to the existing scenes and scripts.

**Tech Stack:** Godot 4.4, GDScript, `ui_manifest.json`-driven stylebox loading, existing portrait HUD / indoor / sheet / overlay scenes.

---

### Task 1: Lock the compact resolver contract

**Files:**
- Create: `game/tests/unit/test_ui_kit_resolver.gd`
- Modify: `game/scripts/ui/ui_kit_resolver.gd`

- [ ] Add a failing resolver test for `frozen_ui_compact_devkit_v2`
- [ ] Run it and confirm it fails against the current v1-only resolver
- [ ] Update the resolver root and manifest parsing for the new `assets[] + nine_slice` shape
- [ ] Re-run the resolver test until it passes

### Task 2: Apply compact HUD assets

**Files:**
- Modify: `game/scripts/run/hud_presenter.gd`
- Modify: `game/scripts/ui/survival_gauge_strip.gd`
- Modify: `game/tests/unit/test_hud_presenter.gd`

- [ ] Add failing HUD expectations for compact header/gauge/button styling
- [ ] Run the HUD test and confirm failure
- [ ] Apply `hud_header_chip_compact`, `hud_gauge_strip_compact`, `hud_icon_button_compact_*`, and compact gauge assets
- [ ] Re-run the HUD test until it passes

### Task 3: Apply compact indoor and sheet assets

**Files:**
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/ui/survival_sheet.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/unit/test_survival_sheet.gd`

- [ ] Add failing tests for compact indoor cards / action rows / sheet assets
- [ ] Run the indoor and sheet tests and confirm failure
- [ ] Apply the compact indoor and sheet assets without changing interaction behavior
- [ ] Re-run the indoor and sheet tests until they pass

### Task 4: Apply compact overlay assets and verify smoke

**Files:**
- Modify: `game/scripts/outdoor/outdoor_map_overlay.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] Add a failing smoke expectation for compact map overlay assets
- [ ] Run the smoke test and confirm failure
- [ ] Apply the compact overlay assets
- [ ] Re-run the smoke test and headless boot until they pass
