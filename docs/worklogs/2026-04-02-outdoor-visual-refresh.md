# 2026-04-02 Outdoor Visual Refresh

## Context

The outdoor prototype was mechanically functional, but it still looked like placeholder geometry: a player triangle, abstract building squares, and no environmental set dressing.

The current goal is not final art polish. It is to make the outdoor layer read like a real game space while keeping commercial-use-safe asset sourcing and maintaining the existing playtest branch workflow.

## User Feedback Driving This Iteration

- Replace the abstract outdoor placeholder visuals with something that feels like a real top-down game.
- Prioritize readability over atmosphere for the first pass.
- Use pixel art.
- Target a lived-in ruined neighborhood first, while keeping the long-term world direction open for city blocks and harsher wasteland regions later.
- Prefer automatic asset download if licenses can be verified.

## Decisions

- Use CC0 assets only for this first outdoor pass.
- Mix `Kenney Top Down Shooter` for the player sprite with `OpenGameArt 12x12 City Tiles - Top Down` for the neighborhood backdrop and vehicle props.
- Keep the world feeling like a single large scrolling space.
- Make the scene structure explicit: `Ground`, `Buildings`, `Obstacles`, `PlayerSprite`.
- Keep building interaction readable with stylized entrance markers over a more illustrative backdrop.

## Implementation Notes

- Initial direct download URLs were wrong and returned HTML error pages instead of zip files.
- The correct downloadable files were re-derived from the official asset pages and then verified with `file` and `unzip -l`.
- Godot headless could not consume these PNGs as scene `ext_resource` textures without import metadata.
- The fix was to load outdoor PNG textures at runtime with `Image.load()` plus `ImageTexture.create_from_image()`, which avoids brittle import-state coupling in tests.
- The first visual slice now includes:
  - a neighborhood mockup backdrop
  - visible obstacle props
  - a proper survivor sprite
  - camera-follow outdoor movement
  - styled building entrance markers

## Benefits

- Outdoor playtests now read more like a real game, not just a systems prototype.
- Third-party asset provenance is recorded in-repo.
- The outdoor scene now has a clearer structure for future collision, chunking, and environment expansion work.

## Follow-up Change

After a live playtest, the borrowed neighborhood backdrop and external vehicle/character art were judged to be directionally wrong for the apocalypse tone. The active outdoor scene was therefore pulled back to neutral placeholders:

- no borrowed backdrop in the live scene
- no borrowed outdoor character sprite in the live scene
- no borrowed vehicle sprites in the live scene

The vendored CC0 files remain in the repository as reviewed references, but they are no longer active. The live outdoor scene now uses simple geometric placeholder visuals until user-provided art direction or reference images arrive.
