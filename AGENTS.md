# AGENTS.md

Short routing guide for this repository.

This file is a navigator, not a spec archive. Read the smallest set of docs needed to understand the current direction, then work from there.

## Working Style

- Keep changes focused and local.
- Prefer the active docs over older background material.
- Do not duplicate long design text here.
- If documents disagree, follow the higher-priority, more current source below.
- Use `docs/` as the durable project memory.
- When touching a system, clean up directly related dead code, obsolete paths, temporary scaffolding, and duplicated flows as part of the same work.
- Do not leave nearby junk code behind if it will distort future implementation patterns.

## Document Priority

Read documents in this order when multiple sources exist:

This is the default order. Task entry points below can override it when a task is setup-first, especially Android or export work.

1. `docs/superpowers/specs/`
   - Active feature design
   - Current source of truth for new feature behavior
2. `docs/superpowers/plans/`
   - Active implementation plans
   - Current source of truth for execution order and next steps
3. `docs/CURRENT_STATE.md`
   - Current project state and near-term priorities
   - Read this first when you need to know what is happening now
4. `docs/specs/`
   - Long-lived background design
   - Useful context, but not the first place to resolve active work
5. `docs/handoffs/` and `docs/worklogs/`
   - Historical context
   - Use for reconstruction, not for current direction
6. `docs/setup/`
   - Environment setup and local tooling
   - Use when a task depends on machine or export configuration

## Task Entry Points

### UI/UX Changes

- Start with `docs/superpowers/specs/` for the active UI direction.
- Check `docs/CURRENT_STATE.md` for current priorities and any temporary UI decisions.
- Use `docs/specs/` only for background patterns or older design constraints.

### Survival / Inventory / Crafting

- Start with the active survival or crafting spec in `docs/superpowers/specs/`.
- Then read the matching plan in `docs/superpowers/plans/`.
- Check `docs/CURRENT_STATE.md` for what is currently being tuned or deferred.

### Android / Export

- Start with `docs/setup/` for environment, device, and export setup.
- This is an explicit setup-first exception to the general reading order above.
- Check `docs/CURRENT_STATE.md` for current platform priorities.
- Use `docs/specs/` only if a platform decision depends on the baseline architecture.

### Session Recovery / Current-State Checks

- Start with `docs/CURRENT_STATE.md`.
- Then read the latest active spec and plan if you need implementation detail.
- Use `docs/handoffs/` and `docs/worklogs/` only to recover history.

## Current Direction Reference

- `docs/CURRENT_STATE.md` owns the current product direction and near-term priorities.
- `docs/INDEX.md` owns the active document inventory.
- Keep this file focused on routing and reading order, not live state.

## Doc Update Rules

- New feature specs go in `docs/superpowers/specs/`.
- New implementation plans go in `docs/superpowers/plans/`.
- Update `docs/INDEX.md` whenever you add or retire an active doc.
- Update `docs/CURRENT_STATE.md` when active direction or priorities shift.
- Do not mirror live direction here when `docs/CURRENT_STATE.md` already says it.

## Practical Defaults

- If you need the current truth, read the active spec and plan first.
- If you need the active doc list, trust `docs/INDEX.md`.
- If you need the current direction, trust `docs/CURRENT_STATE.md`.
- If you need why a system exists, read `docs/specs/`.
- If you need setup or export steps, read `docs/setup/`.
- If you need recovery context, read handoffs and worklogs last.
- Keep this file short and routing-first.
