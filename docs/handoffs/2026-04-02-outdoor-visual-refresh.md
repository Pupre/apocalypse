# Outdoor Visual Refresh Handoff

## Branch

- `playtest-mart-indoor-content`

## Scope Completed

- Downloaded and verified outdoor CC0 asset packs from official sources
- Added outdoor third-party asset manifest
- Reworked outdoor scene structure toward `Ground / Buildings / Obstacles / PlayerSprite`
- Replaced the player triangle with a survivor sprite
- Added a lived-in neighborhood backdrop and vehicle props
- Made the outdoor controller load textures at runtime for headless-test stability

## Important Files

- `game/scenes/outdoor/outdoor_mode.tscn`
- `game/scripts/outdoor/outdoor_controller.gd`
- `game/tests/unit/test_outdoor_controller.gd`
- `game/assets/outdoor/third_party/THIRD_PARTY_ASSETS.md`

## Key Technical Notes

- Outdoor PNGs are loaded at runtime instead of scene `ext_resource` import references.
- This was necessary because headless Godot tests were failing on missing imported texture metadata.
- The scene now expects the following visible nodes to exist:
  - `Ground`
  - `Buildings`
  - `Obstacles`
  - `PlayerSprite`

## Remaining Follow-Ups

- Replace more abstract building markers with richer building-specific visuals
- Add real obstacle collision beyond the current simple blocked rectangles
- Build the first proper tile-based neighborhood slice instead of relying mostly on the mockup backdrop
- Expand outdoor HUD readability once the external threat layer gets denser

## Verification

- Re-run `test_outdoor_controller.gd` after any outdoor scene structure changes
- Re-run the full smoke/unit regression set before pushing
