# Outdoor Visual Refresh Handoff

## Branch

- `playtest-mart-indoor-content`

## Scope Completed

- Downloaded and verified outdoor CC0 asset packs from official sources
- Added outdoor third-party asset manifest
- Reworked outdoor scene structure toward `Ground / Buildings / Obstacles / PlayerSprite`
- Temporarily tested borrowed outdoor art, then removed it from the active scene after playtest feedback
- Restored the live scene to neutral placeholder geometry while keeping the new scene structure

## Important Files

- `game/scenes/outdoor/outdoor_mode.tscn`
- `game/scripts/outdoor/outdoor_controller.gd`
- `game/tests/unit/test_outdoor_controller.gd`
- `game/assets/outdoor/third_party/THIRD_PARTY_ASSETS.md`

## Key Technical Notes

- The scene now expects the following visible nodes to exist:
  - `Ground`
  - `Buildings`
  - `Obstacles`
  - `PlayerSprite`
- Vendored outdoor CC0 art is kept on disk and documented, but not currently used by the active scene.
- This is intentional pending user-supplied visual direction.

## Remaining Follow-Ups

- Replace more abstract building markers with richer building-specific visuals
- Add real obstacle collision beyond the current simple blocked rectangles
- Apply user-approved outdoor references instead of generic borrowed CC0 art
- Expand outdoor HUD readability once the external threat layer gets denser
- Build dedicated outdoor item-use interactions once the user wants survival consumption outside the indoor sheet flow
- Add future stat-check systems on top of the new fatigue/survival model
- Consider adding `tests/run_all.gd` so the regression command can become a single stable entry point

## Verification

- Re-run `test_outdoor_controller.gd` after any outdoor scene structure changes
- Re-run the full smoke/unit regression set before pushing

## Survival Stats Status

- first-pass survival stats are live:
  - `허기`
  - `갈증`
  - `체력`
  - `피로`
- `갈증` drains faster than `허기`
- zero `허기` or zero `갈증` now causes ongoing `체력` loss
- indoor HUD and item sheets now expose readable stages plus exact item deltas where needed
- safe indoor zones can now offer `휴식` and `취침`
- indoor item consumption now costs time
- high fatigue now:
  - increases indoor action time
  - reduces outdoor movement speed
