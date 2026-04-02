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

## Verification

- Re-run `test_outdoor_controller.gd` after any outdoor scene structure changes
- Re-run the full smoke/unit regression set before pushing
