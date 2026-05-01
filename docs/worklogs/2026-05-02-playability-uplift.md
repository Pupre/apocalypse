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

## Follow-up Change: Branching Indoor Resolution

The mart staff-gate event now has a quieter tool-based path if the survivor has a screwdriver.

- Brute force is faster, noisy, injures the survivor slightly, and can trigger noise escalation.
- Using a screwdriver takes longer, costs effort, but avoids injury and stays quiet.
- Once the gate is opened, the alternate path is removed through `forbidden_flag_ids`.

This is the first pass at making indoor exploration feel like practical problem solving rather than repeated generic search actions.

## Follow-up Change: Improvised Indoor Access

The branching-resolution pattern now applies beyond the mart.

- Garage service pit can be searched quickly and risk a cut, or searched carefully with work gloves to avoid injury.
- Warehouse deep storage can now be reached with the original shutter key or by bracing the shutter with pliers and steel wire.
- Indoor requirements now support `any_of` blocks, so access rules can express "key or improvised setup" without duplicating zones.
- Indoor action outcomes can consume specific inventory items, letting reusable tools and spent materials behave differently.

This moves indoor play closer to the intended survival-planning fantasy: what you brought changes what risks you can avoid, what doors you can open, and what materials you lose.

## Follow-up Change: Wearable Warmth Gear

Several warmth items now function as actual equipment rather than only crafting ingredients or flavor text.

- Scarves, face wraps, sock layers, glove liners, insoles, and thick sock bundles have equipment slots.
- Wearable warmth gear now applies `equip_effects.outdoor_exposure_drain_multiplier`, so it reduces outdoor cold drain while equipped.
- Added `neck`, `face`, `feet_layer`, and `hands_layer` equipment rows so shoes, socks, gloves, and liners can coexist more realistically.
- Inventory detail text now surfaces the outdoor cold reduction percentage.

This makes "do I grab the food, the bag, or the warm clothing?" a more concrete survival decision instead of only a roleplay distinction.
