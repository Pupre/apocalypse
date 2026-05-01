# 2026-05-02 Playability Uplift

## Context

This pass starts the longer autonomous quality push after the carry-weight, heat-source, quantity-supply, and outdoor pressure baseline.

The target game fantasy is a grounded disaster-progression survival simulation: the player should feel the pressure of practical choices over time, such as whether to move fast or bring a bag, whether food beats fuel right now, and how much risk a search is worth before conditions worsen.

## Operating Direction

- Improve playable quality, not only isolated feature count.
- Use generated assets when an authored visual moment needs them.
- Keep decisions grounded in realistic survival pressure.
- Prefer local commits at stable checkpoints.
- Document tradeoffs instead of stopping for minor design questions.

## Implemented

- Added a generated, transparent frost-crystal screen overlay:
  - `resources/ui/master/feedback/frost_screen_overlay.png`
  - generated from a black-background image prompt, then converted to alpha.
  - wired through `ui_kit_resolver.gd` and `outdoor_mode.tscn`.
- Split cold feedback into two layers:
  - a subtle blue readability tint
  - a stronger image-backed edge frost overlay when exposure falls.
- Added authored indoor pressure outcomes:
  - `outcomes.pressure` can now affect exposure, fatigue, health, noise, feedback text, and one-time pressure ids.
  - pressure state persists in indoor site memory.
  - current-zone status rows now show accumulated noise as `소란 N`.
- Authored first pressure beats:
  - mart freezer row and cold storage reduce exposure.
  - forcing the mart staff gate adds noise, fatigue, and a small injury.
  - garage service pit can injure the survivor.
  - warehouse shutter/deep storage add noise and physical strain.
- Restored mart office knowledge-note placement for early heat and cooking discovery.
- Updated stale tests so they reflect the current kg-based carry UI and support non-loot search actions that create pressure, clues, flags, or unlocks.

## Verification

- `res://tests/unit/test_inventory_weight_model.gd`
- `res://tests/unit/test_heat_source_rules.gd`
- `res://tests/unit/test_supply_source_selection.gd`
- `res://tests/unit/test_indoor_pressure_outcomes.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_loot_tables.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_indoor_site_memory.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## Review Notes

- Indoor pressure is intentionally deterministic for now. This keeps tests stable and makes authored risks legible before adding probabilistic hazards.
- `noise` currently has display and memory support, but no global consequence loop yet. It is ready to drive future indoor danger escalation.
- The frost overlay is now visual-feedback infrastructure; future cold/story beats can reuse the same asset strategy instead of relying only on flat screen tint.
