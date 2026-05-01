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
- `noise` now has a first deterministic threshold loop at 3/6/9. Each crossed threshold resolves once and adds a short danger beat such as waiting, cold seepage, fatigue, or minor injury.
- The frost overlay is now visual-feedback infrastructure; future cold/story beats can reuse the same asset strategy instead of relying only on flat screen tint.

## Follow-up Change: Indoor Noise Escalation

After the first pressure pass, `noise` was connected to gameplay consequences rather than remaining a passive status number.

- Thresholds currently resolve at noise 3, 6, and 9.
- Only one unresolved threshold resolves per action, which keeps escalation readable and prevents one loud action from stacking every penalty at once.
- The first threshold adds a forced pause and fatigue.
- The second threshold adds a longer pause, fatigue, and exposure loss.
- The third threshold adds exposure loss, fatigue, a small injury, and a stronger warning message.

## Follow-up Change: Practical Recipe Links

The item and crafting pool already had a strong base, so this pass focused on believable missing links among items already present in the current building set.

- `medical_tape + sterile_gauze_roll -> pressure_bandage`
- `shop_towel_bundle + duct_tape -> draft_blocker`
- `tarp_sheet + duct_tape -> window_cover_patch`
- `hand_warmer_pack + scarf -> hand_warmer_wrap`
- `disinfectant_bottle + shop_towel_bundle -> solvent_wipes`

These are intentionally ordinary survival improvisations: medical dressing, draft blocking, broken-opening patching, pocket warmth, and cleaning/disinfection.

## Follow-up Change: Outdoor Hazard Zones

The first block now has terrain-driven outdoor risks in addition to cold and pursuit.

- `black_ice` zones can cause a small injury, exposure loss, and fatigue.
- `wind_gap` zones cost exposure and fatigue as the survivor crosses exposed building gaps.
- Hazard decals render on the outdoor ground layer so risky surfaces have a visible cue.
- Hazard feedback temporarily replaces the generic movement hint, keeping the result readable without opening a modal.
