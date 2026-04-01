# Project Documentation

This repository is docs-first during pre-production.

## Approved Documents

- `specs/`: approved design documents that define accepted parts of the project direction
- `setup/`: machine and tool setup guides for local development

## Document Lifecycle

- Approved documents live in this repository
- Draft ideas should live in `drafts/` until they are intentionally reviewed and promoted
- The current repository state is intentionally documentation-only; code and engine decisions come later
- Each approved spec should declare its status and last-updated date near the top of the file
- A draft becomes approved when it is moved from [drafts/](drafts/README.md) into `specs/`, merged into the repository, and marked with `Status: approved`
- Approved specs may exist in parallel for different scopes such as core gameplay, combat, economy, or narrative
- A spec supersedes another one only when the newer merged document explicitly says so and covers the same scope

## Current Documents

- [Core Gameplay Design](specs/core-gameplay-design.md)
- [Godot Technical Architecture](specs/godot-technical-architecture.md)
- [Mode Transition Presentation Design](specs/mode-transition-presentation-design.md)
- [Godot Android Development Setup](setup/godot-android-development-setup.md)
