# Portrait Phase 1 Shell Design

## Goal

Turn the current game into a believable portrait-first build in one visible pass.

Phase 1 does not fully redesign every gameplay system. It changes the presentation shell so the game immediately reads as a vertical mobile game when launched:

- project boots in portrait proportions
- outdoor exploration uses a portrait-biased camera and compact HUD
- indoor reading/action flow becomes a one-column portrait layout
- the previously added `SurvivalSheet` remains the main inventory / craft / codex surface

The target outcome is not "final mobile UI polish." The target outcome is "the whole game no longer feels like a landscape prototype."


## Scope

### In Scope

- portrait project window baseline
- outdoor HUD reframing for portrait
- outdoor camera reframing for portrait
- indoor main layout reframing for portrait
- preserving the current survival systems, crafting, codex, indoor memory, and persistence
- updating tests that currently lock old landscape assumptions

### Out of Scope

- touch controls
- final outdoor world art pass
- full outdoor world geometry redesign
- final survival balance tuning
- replacing keyboard dev controls
- removing every leftover legacy scene node in this cycle


## Design Choice

This phase uses the previously recommended `World-First Portrait` direction.

That means:

- outdoor still prioritizes movement through the world
- indoor still prioritizes readable text and clear actions
- portrait adaptation is achieved by reframing the camera and UI, not by converting the game into a menu-first node map

The alternative `reader-first` direction would weaken the long-distance survival feeling too early. The `fixed dock` direction would preserve implementation convenience but keep too much landscape UI energy on screen.


## Portrait Baseline

The game becomes portrait-only for this phase.

### Window Baseline

- canonical layout target: `720 x 1280`
- stretch policy must preserve a stable portrait composition on desktop during development and on mobile later
- UI margins must assume narrow width and tall vertical rhythm

This is a composition target, not a promise that every future export will use exactly that pixel size.


## Outdoor Design

### Camera

Outdoor remains a continuous player-centered world view, but the camera stops behaving like a centered landscape camera.

- the player sits below center rather than in the middle
- more space is shown in the forward travel direction
- lateral awareness is preserved with modest framing rather than a wide HUD-free landscape strip

The intended feeling is:

- you see enough ahead to commit to movement
- you do not see the whole road at once
- distance still feels dangerous because the world remains continuous

### HUD

The current large right-side status box is replaced by a portrait-friendly compact shell.

- status becomes a shallow top cluster rather than a tall side slab
- the HUD must read as overlay UI, never as world signage
- critical survival values stay visible at a glance
- craft / codex access remains available outdoors, but the controls must no longer dominate the upper corner

The HUD must feel like a mobile survival ribbon, not a desktop debug panel.

### World Framing

Phase 1 does not rebuild the outdoor world into a different traversal model.

Instead:

- the same world remains continuous
- building markers, vehicles, and obstacles stay functional
- the road presentation may be visually compressed or repositioned to better support portrait framing

If the outdoor view still feels too horizontally authored after camera and HUD changes, the next phase can revisit world geometry. That is explicitly not required to finish this phase.


## Indoor Design

Indoor becomes a true one-column portrait surface.

### Main Screen Structure

The indoor main screen is reordered into a vertical stack:

1. top status strip
2. current location strip
3. reading / feedback card
4. compact inline minimap card
5. action list

The old side-by-side `ContextRow` composition is removed from the main reading surface.

### Reading Surface

The summary and result text stay central, and they must no longer compete with a side minimap column.

- summary text remains the primary narrative block
- result feedback remains directly under it
- both must breathe in portrait proportions

### Inline Minimap

The minimap remains visible indoors, but it becomes a compact secondary card in the vertical flow instead of sharing horizontal space with the reading card.

### SurvivalSheet

The existing `SurvivalSheet` stays the main bottom-sheet interaction surface for:

- inventory
- crafting
- codex

This phase does not replace it again. Instead, the indoor main layout is rebuilt around it.


## Interaction Rules

### Outdoor

- movement remains direct and continuous
- building entry remains contextual
- craft / codex entry remains available

### Indoor

- actions remain in the main vertical list
- bag opens `SurvivalSheet`
- crafted results still return into readable item detail inside the sheet
- main indoor result text must still reflect important craft feedback


## Visual Direction

The game must read as a tense mobile survival game rather than a stretched desktop prototype.

### Layout Character

- denser top framing
- stronger vertical spacing rhythm
- fewer side-by-side surfaces
- clearer hierarchy between world, reading, and overlays

### Tone

- keep the existing cold, worn, practical mood
- do not introduce bright arcade styling
- do not overdecorate the screen with chrome


## Technical Boundaries

Phase 1 prefers adaptation over replacement.

- keep `RunState`, `IndoorDirector`, `OutdoorController`, and `SurvivalSheet`
- modify scene structure and presentation logic around them
- avoid rewriting gameplay rules unless the portrait shell forces a small supporting change

This is a shell refactor with interaction cleanup, not a system reboot.


## Testing Strategy

The implementation must update verification around the new portrait contract.

### Expected Test Areas

- HUD presenter portrait positioning expectations
- indoor mode portrait layout expectations
- smoke loop expectations around indoor bag / codex / craft flow
- regression that outdoor craft / codex still work

Tests should prove:

- the project still boots and transitions between outdoor and indoor
- indoor portrait interactions still work
- outdoor shared crafting still works
- the new framing does not break survival-state updates


## Success Criteria

Phase 1 is successful when all of the following are true:

- launching the game immediately feels portrait-authored
- outdoor HUD no longer reads like a world-attached landscape block
- indoor main screen no longer relies on horizontal split composition
- indoor `SurvivalSheet` flow still works
- survival and crafting regressions remain green


## Risks

### Risk 1: Outdoor loses too much side visibility

Mitigation:

- use camera offset first
- only apply modest zoom/framing changes in this phase

### Risk 2: Indoor becomes too stacked and cramped

Mitigation:

- keep the inline minimap compact
- preserve readable action spacing
- push secondary interaction into `SurvivalSheet`

### Risk 3: Landscape-era tests block the refactor

Mitigation:

- treat old layout assertions as contract updates, not sacred truth
- preserve gameplay behavior while changing screen structure


## Phase Boundary

If this phase lands cleanly, the next portrait phase should focus on:

- outdoor world composition polish
- touch-first control affordances
- final cleanup of leftover legacy layout nodes
