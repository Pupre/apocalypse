# apocalypse

Pre-production repository for a mobile hybrid survival roguelike.

## Current Focus

- Keep the approved game design and Godot architecture in one repository
- Build toward a playable Android-first prototype in Godot
- Keep the Linux and Windows development environments aligned

## Repository Status

This repository currently stores pre-production project documents and setup guides. See [Documentation Guide](docs/README.md) for the document workflow.

## Core Premise

- Outdoor gameplay is real-time, top-down, and high-risk
- Indoor gameplay is text-driven, lower-risk, and decision-heavy
- Both layers share the same in-game day clock
- Survival depends on time, fatigue, supplies, an outside exposure resource, and relocation choices

## Implementation Baseline

- Engine: `Godot 4.4.1`
- Language: `GDScript`
- Primary target: `Android`
- Secondary target: `iOS` later
- Technical reference: [Godot Technical Architecture](docs/specs/godot-technical-architecture.md)
- Setup reference: [Godot Android Development Setup](docs/setup/godot-android-development-setup.md)

## Repository Layout

- [Documentation Guide](docs/README.md): documentation rules and lifecycle notes
- `docs/drafts/`: in-progress design drafts
- `docs/specs/`: approved design documents referenced by the documentation guide
- `docs/setup/`: local environment and tool setup guides
