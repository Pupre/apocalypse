# Mode Transition Presentation Design

- Status: approved
- Created: 2026-03-31
- Last updated: 2026-03-31
- Scope: prototype transition feel between outdoor and indoor play

## Purpose

Improve the perceived separation between outdoor real-time play and indoor text-adventure play without changing the current runtime architecture.

## Problem Statement

The current prototype already swaps the active mode scene inside `run_shell`, but the transition can still feel like an indoor UI panel is being layered on top of the outdoor scene.

The main causes are:

- the shared HUD remains visually identical across both modes
- scene changes happen instantly with no masking or handoff
- the indoor panel does not yet establish a strong enough "reading space" identity

## Fixed Direction

The project keeps the current shell-based structure.

- `run_shell` remains the persistent owner of the active run
- `ModeHost` continues to swap between outdoor and indoor mode scenes
- the shared HUD remains present across both modes

This work is presentation polish, not an architectural rewrite.

## Recommended Approach

Adopt a lightweight presentation layer around the existing scene swap.

### 1. Fade-Masked Mode Switching

- Add a short fade-out/fade-in transition around outdoor-to-indoor and indoor-to-outdoor scene swaps
- Default timing should be fast enough to feel responsive, around `0.25s` per half-transition
- The fade should fully mask the moment the mode scene is replaced

### 2. Shared HUD, Mode-Specific Feel

- Keep one shared HUD instance for run-critical information such as time, fatigue, hunger, and carry load
- Allow the HUD presentation to shift by mode rather than duplicating state displays in each scene
- Outdoor presentation should feel more tactical and active
- Indoor presentation should feel calmer, flatter, and more readable

### 3. Stronger Indoor Reading Space

- Increase the visual separation of the indoor panel from the shell background
- Use stronger margins, a more deliberate panel surface, and calmer composition
- The indoor screen should read as a dedicated text-adventure scene, not a temporary popup

## Interaction Rules

### Outdoor to Indoor

1. Player requests building entry
2. Fade-out begins
3. Outdoor mode scene is replaced with indoor mode scene while the screen is masked
4. Indoor HUD presentation is applied
5. Fade-in reveals the indoor scene

### Indoor to Outdoor

1. Player exits the building
2. Fade-out begins
3. Indoor mode scene is replaced with outdoor mode scene while the screen is masked
4. Outdoor HUD presentation is restored
5. Fade-in reveals the outdoor scene

## UI Intent by Mode

### Outdoor

- preserve immediate readability while moving
- keep action hints and exposure feedback clearly visible
- feel like active field traversal

### Indoor

- reduce the sense of gameplay noise
- keep the run-state HUD available but visually secondary
- prioritize text, clues, action buttons, and result feedback

## Out of Scope

This polish pass does not include:

- changing the shared run-state architecture
- adding full-screen cinematic transitions
- adding new audio systems
- redesigning the gameplay rules of indoor or outdoor modes

## Acceptance Criteria

- Entering a building no longer feels like stacking a new panel on top of the outdoor scene
- Returning outside also reads as a full mode change
- Shared run-state information remains accessible in both modes
- The implementation stays compatible with the current `run_shell` and `ModeHost` structure

