# Outdoor Visual Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder outdoor scene with a readable top-down pixel-art neighborhood slice using commercially safe CC0 assets while preserving current movement and building-entry gameplay.

**Architecture:** Keep existing outdoor gameplay state and building metadata intact, then layer visuals on top through scene nodes and controller updates. Use a mixed CC0 asset strategy: pixel-art character and prop sprites plus readable city/neighborhood ground tiles, with collisions staying simple and large-object focused.

**Tech Stack:** Godot 4, GDScript, JSON building metadata, CC0 pixel-art assets, headless Godot tests

---

### Task 1: Vendor Approved Outdoor Asset Set

**Files:**
- Create: `game/assets/outdoor/third_party/...`
- Create: `game/assets/outdoor/third_party/THIRD_PARTY_ASSETS.md`
- Modify: `docs/worklogs/2026-04-01-indoor-prototype-iteration.md`
- Modify: `docs/handoffs/2026-04-01-indoor-prototype-iteration.md`

- [ ] **Step 1: Write the failing artifact check**

Document the expected first-pass asset set in `game/assets/outdoor/third_party/THIRD_PARTY_ASSETS.md`:

```md
# Third-Party Outdoor Assets

## Required in this pass

- player sprite sheet
- neighborhood/city ground tiles
- simple building exterior tiles
- large obstacle sprites or tiles
```

- [ ] **Step 2: Verify the asset set is missing**

Run:

```bash
test -f /home/muhyeon_shin/packages/apocalypse/game/assets/outdoor/third_party/THIRD_PARTY_ASSETS.md
```

Expected: non-zero exit status because the outdoor asset manifest does not exist yet.

- [ ] **Step 3: Add vendored assets and manifest**

Create the third-party manifest with:

- source URL
- exact vendored subset
- license
- commercial-use note
- download date

Use only the specific files needed for this pass instead of committing full packs where possible.

- [ ] **Step 4: Verify the manifest exists**

Run:

```bash
test -f /home/muhyeon_shin/packages/apocalypse/game/assets/outdoor/third_party/THIRD_PARTY_ASSETS.md
```

Expected: zero exit status.

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/assets/outdoor/third_party \
  docs/worklogs/2026-04-01-indoor-prototype-iteration.md \
  docs/handoffs/2026-04-01-indoor-prototype-iteration.md
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: vendor outdoor cc0 art assets"
```

### Task 2: Replace Placeholder Outdoor Scene Layout

**Files:**
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Write the failing scene-layout test expectation**

Extend `game/tests/unit/test_outdoor_controller.gd` so it asserts the scene now exposes:

- ground host node
- obstacle host node
- building art host node
- sprite-based player node

Use explicit node lookups instead of loose tree assumptions.

- [ ] **Step 2: Run the outdoor controller test to verify it fails**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_outdoor_controller.gd
```

Expected: FAIL because the new visual nodes are not present yet.

- [ ] **Step 3: Add the minimal outdoor scene structure**

Update `game/scenes/outdoor/outdoor_mode.tscn` so the outdoor scene contains:

- `Ground` node for tile or sprite floor dressing
- `Buildings` node for building visuals
- `Obstacles` node for collision visuals
- `PlayerSprite` under the player marker path or a dedicated visual child

Keep the current status panel alive.

- [ ] **Step 4: Update controller caching and sync**

Modify `game/scripts/outdoor/outdoor_controller.gd` so it caches and updates the new nodes without changing current gameplay semantics:

- player visual remains aligned to player position
- building visuals are created from building metadata
- existing hint/exposure UI still updates

- [ ] **Step 5: Run the outdoor controller test to verify it passes**

Run the same command from Step 2.

Expected: `OUTDOOR_CONTROLLER_OK`

- [ ] **Step 6: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/outdoor/outdoor_mode.tscn \
  game/scripts/outdoor/outdoor_controller.gd \
  game/tests/unit/test_outdoor_controller.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add outdoor visual scene structure"
```

### Task 3: Build the First Neighborhood Slice

**Files:**
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/data/buildings.json`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write the failing neighborhood-layout assertions**

Add test expectations that:

- the outdoor scene creates readable building visuals for all current buildings
- the player starts on a walkable road/sidewalk zone
- at least one non-building obstacle visual exists

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_outdoor_controller.gd
```

Expected: FAIL because the neighborhood dressing and obstacle visuals are not present yet.

- [ ] **Step 3: Add the first outdoor art pass**

Use the vendored assets to create:

- basic road and sidewalk ground visuals
- simple neighborhood building exteriors at each current building position
- a few large obstacles such as car, barricade, or rubble

Do not add dense clutter. Keep the walkable routes obvious.

- [ ] **Step 4: Keep current building entry semantics**

Ensure building positions used for visuals still map to the same entry radius and nearest-building logic already used by gameplay.

- [ ] **Step 5: Run tests to verify pass**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_outdoor_controller.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `OUTDOOR_CONTROLLER_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 6: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/data/buildings.json \
  game/scripts/outdoor/outdoor_controller.gd \
  game/tests/unit/test_outdoor_controller.gd \
  game/tests/smoke/test_first_playable_loop.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add outdoor neighborhood art pass"
```

### Task 4: Add Readable Outdoor Character Presentation

**Files:**
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Write the failing player-visual assertion**

Update `game/tests/unit/test_outdoor_controller.gd` so it checks:

- the outdoor scene uses a sprite-based player visual
- the visual follows the same world position as the gameplay marker

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_outdoor_controller.gd
```

Expected: FAIL because the player is still only represented by the old placeholder marker.

- [ ] **Step 3: Add the pixel-art player visual**

Integrate the chosen player sprite with minimal animation needs:

- one idle or neutral frame is enough for this pass
- preserve the current gameplay position source
- keep the player readable against the new ground colors

- [ ] **Step 4: Run the test to verify it passes**

Run the same command from Step 2.

Expected: `OUTDOOR_CONTROLLER_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/outdoor/outdoor_mode.tscn \
  game/scripts/outdoor/outdoor_controller.gd \
  game/tests/unit/test_outdoor_controller.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add outdoor player sprite presentation"
```

### Task 5: Full Verification and Playtest Notes

**Files:**
- Modify: `docs/worklogs/2026-04-01-indoor-prototype-iteration.md`
- Modify: `docs/handoffs/2026-04-01-indoor-prototype-iteration.md`

- [ ] **Step 1: Run the full headless regression suite**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
GODOT=/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64
for test in \
  res://tests/unit/test_content_library.gd \
  res://tests/unit/test_run_models.gd \
  res://tests/unit/test_outdoor_controller.gd \
  res://tests/unit/test_indoor_zone_graph.gd \
  res://tests/unit/test_indoor_director.gd \
  res://tests/unit/test_indoor_actions.gd \
  res://tests/unit/test_indoor_mode.gd \
  res://tests/unit/test_indoor_minimap.gd \
  res://tests/unit/test_survivor_creator.gd \
  res://tests/unit/test_run_controller_live_transition.gd \
  res://tests/smoke/test_first_playable_loop.gd
do
  echo RUN:$test
  "$GODOT" --headless --path /home/muhyeon_shin/packages/apocalypse/game -s "$test" || exit 1
done
```

Expected: all tests end in `*_OK`.

- [ ] **Step 2: Update worklog and handoff**

Record:

- exact asset sources used
- what part of the outdoor scene changed
- what still remains placeholder
- any playtest notes the next session should verify visually

- [ ] **Step 3: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  docs/worklogs/2026-04-01-indoor-prototype-iteration.md \
  docs/handoffs/2026-04-01-indoor-prototype-iteration.md
git -C /home/muhyeon_shin/packages/apocalypse commit -m "docs: record outdoor visual refresh verification"
```
