# Context Routing Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a short `AGENTS.md`, a repository-wide `docs/INDEX.md`, a `docs/CURRENT_STATE.md` snapshot, and a thinner `docs/README.md` so agents can find the right context quickly without replacing the existing document tree.

**Architecture:** Keep the existing `docs/` folders in place and add a thin routing layer above them. `AGENTS.md` becomes the repo entry point, `docs/INDEX.md` becomes the document hub, `docs/CURRENT_STATE.md` becomes the session-to-session state snapshot, and `docs/README.md` becomes a brief pointer into the new system instead of carrying a stale document list itself.

**Tech Stack:** Markdown documentation, existing `docs/` tree, repository root guidance files

---

## File Map

### Create

- `AGENTS.md`
- `docs/INDEX.md`
- `docs/CURRENT_STATE.md`

### Modify

- `docs/README.md`

### Responsibilities

- `AGENTS.md`
  - Keep the repo entry contract short
  - Define document priority and task-type routing
  - Point agents to the correct files without embedding large specs
- `docs/INDEX.md`
  - Act as the document hub
  - Group docs into current, active, background, history, and setup
  - Route new documents into the right place
- `docs/CURRENT_STATE.md`
  - Capture the project’s current game direction, implemented systems, active specs, active plans, and immediate next work
- `docs/README.md`
  - Become a lightweight guide that points to `INDEX.md` and explains the high-level document lifecycle without trying to enumerate everything itself

---

### Task 1: Lock The Routing Contract In Docs Tests

**Files:**
- Modify: `docs/README.md`
- Create: `AGENTS.md`
- Create: `docs/INDEX.md`
- Create: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Write the routing contract checklist directly into the plan and use it as the acceptance gate**

The documentation change has no existing automated test harness, so the contract must be explicit and mechanically checkable. The implementation is only complete if all of these are true:

```text
AGENTS.md
- exists at repository root
- stays short and routing-oriented
- names docs/superpowers/specs and docs/superpowers/plans as active
- names docs/specs as background
- gives task-type entry points for UI/UX, survival/crafting, Android/export, and current-state checks

docs/INDEX.md
- exists
- contains Current / Active Specs / Active Plans / Background / History / Setup sections
- links to the latest active crafting/UI/portrait specs and plans
- explains how to classify new documents

docs/CURRENT_STATE.md
- exists
- states portrait-first direction
- states bag-first / contextual crafting direction
- summarizes implemented systems already in main
- calls out current active spec/plan files
- names current or next priorities

docs/README.md
- no longer tries to be the full document inventory
- points readers to docs/INDEX.md
- still explains high-level doc lifecycle
```

- [ ] **Step 2: Verify the current repo fails that contract before writing**

Run:

```bash
test -f AGENTS.md && echo AGENTS_EXISTS || echo AGENTS_MISSING
test -f docs/INDEX.md && echo INDEX_EXISTS || echo INDEX_MISSING
test -f docs/CURRENT_STATE.md && echo CURRENT_EXISTS || echo CURRENT_MISSING
sed -n '1,220p' docs/README.md
```

Expected:

- `AGENTS_MISSING`
- `INDEX_MISSING`
- `CURRENT_MISSING`
- `docs/README.md` still contains the old direct inventory list

- [ ] **Step 3: Re-run the same checks after implementation and verify they pass**

Use the same commands from Step 2.

Expected:

- `AGENTS_EXISTS`
- `INDEX_EXISTS`
- `CURRENT_EXISTS`
- `docs/README.md` now routes to `INDEX.md` instead of trying to be the full directory listing

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md docs/INDEX.md docs/CURRENT_STATE.md docs/README.md
git commit -m "docs: add context routing entrypoints"
```

---

### Task 2: Write The Short Root `AGENTS.md`

**Files:**
- Create: `AGENTS.md`

- [ ] **Step 1: Write the file with a short routing-first structure**

Create `AGENTS.md` with sections like these:

```md
# AGENTS

## Working Style

- Prefer finishing coherent chunks of work before proposing a commit.
- Run focused tests before claiming anything is fixed.
- Do not treat this file as a full design document. Use it as a map.

## Document Priority

1. `docs/superpowers/specs/` for active feature design
2. `docs/superpowers/plans/` for active implementation plans
3. `docs/CURRENT_STATE.md` for current project state and near-term priorities
4. `docs/specs/` for long-lived background design
5. `docs/handoffs/` and `docs/worklogs/` for historical context
6. `docs/setup/` for environment setup

## Start Here By Task Type

- UI/UX changes:
  - `docs/CURRENT_STATE.md`
  - latest relevant file in `docs/superpowers/specs/`
  - latest relevant file in `docs/superpowers/plans/`
- Survival, inventory, crafting:
  - `docs/CURRENT_STATE.md`
  - `docs/specs/knowledge-driven-crafting-design.md`
  - latest relevant `docs/superpowers/specs/` and `plans/`
- Android/export:
  - `docs/setup/godot-android-development-setup.md`
  - `docs/CURRENT_STATE.md`
- Session recovery / “what is going on here?”:
  - `docs/CURRENT_STATE.md`
  - `docs/INDEX.md`

## Current Direction

- Portrait-first mobile game
- Bag-first inventory flow
- Contextual crafting inside the bag
- Outdoor play should preserve continuous travel risk

## Updating The Docs

- New feature specs go in `docs/superpowers/specs/`
- New implementation plans go in `docs/superpowers/plans/`
- Update `docs/INDEX.md` whenever adding a new active doc
- Update `docs/CURRENT_STATE.md` when active direction or priorities shift
```

Keep the final file concise. Do not duplicate long explanations from the deeper docs.

- [ ] **Step 2: Sanity-check the file length and coverage**

Run:

```bash
wc -l AGENTS.md
sed -n '1,220p' AGENTS.md
```

Expected:

- roughly `80-120` lines
- clearly routes readers to other docs instead of trying to replace them

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add repository agents guide"
```

---

### Task 3: Build `docs/INDEX.md` As The Hub

**Files:**
- Create: `docs/INDEX.md`

- [ ] **Step 1: Write the document hub with explicit sections**

Create `docs/INDEX.md` with these major sections and example link patterns:

```md
# Documentation Index

## Current

- [Current State](CURRENT_STATE.md): quickest snapshot of active direction, current implementation state, and next priorities
- [AGENTS](../AGENTS.md): short repo entrypoint and reading order

## Active Specs

- [Crafting Codex + Lighter Design](superpowers/specs/2026-04-06-crafting-codex-lighter-design.md)
- [Indoor Portrait Survival Sheet Design](superpowers/specs/2026-04-07-indoor-portrait-survival-sheet-design.md)
- [Portrait Phase 1 Shell Design](superpowers/specs/2026-04-07-portrait-phase1-shell-design.md)
- [Contextual Crafting UI Design](superpowers/specs/2026-04-09-contextual-crafting-ui-design.md)
- [Context Routing Docs Design](superpowers/specs/2026-04-10-context-routing-docs-design.md)

## Active Plans

- [Crafting Codex + Lighter Plan](superpowers/plans/2026-04-06-crafting-codex-lighter.md)
- [Indoor Portrait Survival Sheet Plan](superpowers/plans/2026-04-07-indoor-portrait-survival-sheet.md)
- [Portrait Phase 1 Shell Plan](superpowers/plans/2026-04-07-portrait-phase1-shell.md)
- [Contextual Crafting UI Plan](superpowers/plans/2026-04-09-contextual-crafting-ui.md)
- [Context Routing Docs Plan](superpowers/plans/2026-04-10-context-routing-docs.md)

## Background

- [Core Gameplay Design](specs/core-gameplay-design.md)
- [Godot Technical Architecture](specs/godot-technical-architecture.md)
- [Knowledge-Driven Crafting Design](specs/knowledge-driven-crafting-design.md)
- other long-lived background docs

## History

- `handoffs/`
- `worklogs/`

## Setup

- [Godot Android Development Setup](setup/godot-android-development-setup.md)

## Adding New Docs

- Put active feature specs in `docs/superpowers/specs/`
- Put active implementation plans in `docs/superpowers/plans/`
- Put long-lived background design in `docs/specs/`
- Update this file whenever adding a new active document
```

The actual final text can be tighter, but it must preserve the sectioning and routing logic from the spec.

- [ ] **Step 2: Verify every linked file actually exists**

Run:

```bash
rg -n "\\]\\(" docs/INDEX.md
```

Then manually compare each linked path against `docs/` contents before moving on.

- [ ] **Step 3: Commit**

```bash
git add docs/INDEX.md
git commit -m "docs: add repository documentation index"
```

---

### Task 4: Write `docs/CURRENT_STATE.md` And Thin `docs/README.md`

**Files:**
- Create: `docs/CURRENT_STATE.md`
- Modify: `docs/README.md`

- [ ] **Step 1: Write the current-state snapshot**

Create `docs/CURRENT_STATE.md` with sections like these:

```md
# Current State

- Status: active
- Last updated: 2026-04-10

## Product Direction

- Portrait-first mobile presentation
- Outdoor: continuous travel risk and long-distance survival pressure
- Indoor: text-heavy, decision-driven interaction
- Bag-first inventory; crafting is a contextual sub-flow

## Implemented Baseline

- life-world item and recipe expansion
- building-specific random indoor loot
- shared crafting sheet baseline
- warmth system
- indoor site memory and drop/re-entry persistence
- crafting codex, note-based unlocks, lighter charges/tool requirements
- portrait phase 1 shell and indoor survival sheet work

## Active Specs

- list the current active specs with links

## Active Plans

- list the current active plans with links

## Immediate Priorities

- finish contextual crafting UI polish
- continue portrait-first indoor/outdoor layout polish
- maintain Android-first build path

## Temporary Development Conditions

- note any temporary dev-only starter items or testing shortcuts that are still live
```

The file should be concise, current, and obviously more time-sensitive than the longer specs.

- [ ] **Step 2: Rewrite `docs/README.md` so it routes instead of enumerating**

Replace the stale direct inventory in `docs/README.md` with a slimmer structure such as:

```md
# Project Documentation

This repository uses a routing-first documentation model.

## Start Here

- [Documentation Index](INDEX.md): full document map and navigation hub
- [Current State](CURRENT_STATE.md): fastest way to understand what is active right now
- [AGENTS](../AGENTS.md): short repository guidance for coding agents

## Document Roles

- `specs/`: long-lived background design
- `superpowers/specs/`: active feature design
- `superpowers/plans/`: active implementation plans
- `handoffs/`, `worklogs/`: historical context
- `setup/`: local environment references

## Lifecycle

- Drafts start in `drafts/`
- Active feature design lives in `superpowers/specs/`
- Active implementation planning lives in `superpowers/plans/`
- Long-lived background design stays in `specs/`
- Update `INDEX.md` whenever a new active document is added
```

Do not keep the old “Current Documents” block that tries to be the live inventory itself.

- [ ] **Step 3: Run the routing verification checks**

Run:

```bash
test -f AGENTS.md && echo AGENTS_EXISTS || echo AGENTS_MISSING
test -f docs/INDEX.md && echo INDEX_EXISTS || echo INDEX_MISSING
test -f docs/CURRENT_STATE.md && echo CURRENT_EXISTS || echo CURRENT_MISSING
sed -n '1,220p' docs/README.md
```

Expected:

- all three files exist
- `docs/README.md` points to the new routing docs
- the old direct inventory list is gone

- [ ] **Step 4: Commit**

```bash
git add docs/CURRENT_STATE.md docs/README.md
git commit -m "docs: add current-state routing layer"
```

---

## Self-Review

- Spec coverage:
  - `AGENTS.md` as short router is covered in Task 2.
  - `docs/INDEX.md` as hub is covered in Task 3.
  - `docs/CURRENT_STATE.md` as snapshot is covered in Task 4.
  - `docs/README.md` thinning is covered in Task 4.
  - active vs background doc interpretation is reflected in all four tasks.
- Placeholder scan:
  - No `TODO`, `TBD`, or undefined “appropriate handling” language remains.
- Type consistency:
  - File names and section names are consistent across the plan: `AGENTS.md`, `docs/INDEX.md`, `docs/CURRENT_STATE.md`, `docs/README.md`.
