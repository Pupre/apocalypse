# Godot Android Development Setup

## Purpose

Keep the Linux work machine and the Windows home machine aligned so the same Godot repository can move between both without environment drift.

## Shared Baseline

Use the same versions on both machines unless there is a deliberate upgrade.

- Godot: `4.4.1` stable
- Godot export templates: `4.4.1.stable`
- Java: `OpenJDK 17`
- Android SDK packages:
  - `platform-tools`
  - `build-tools;35.0.0`
  - `platforms;android-35`
  - `cmdline-tools;latest`
  - `cmake;3.10.2.4988404`
  - `ndk;28.1.13356709`

## Linux Workspace Status

These parts are already installed in the current Linux workspace.

- Godot binary:
  - `/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64`
- Godot export templates:
  - `/home/muhyeon_shin/.local/share/godot/export_templates/4.4.1.stable`
- Android SDK root:
  - `/home/muhyeon_shin/packages/.local-tools/android-sdk`
- Java SDK root:
  - `/usr/lib/jvm/java-17-openjdk-17.0.13.0.11-4.el9.x86_64`

## Linux Manual Steps

These still need to be done by hand because they require Godot UI access or a physical device.

1. Open Godot with the installed binary path above.
2. Set `Editor Settings > Export > Android > Java SDK Path` to:
   - `/usr/lib/jvm/java-17-openjdk-17.0.13.0.11-4.el9.x86_64`
3. Set `Editor Settings > Export > Android > Android SDK Path` to:
   - `/home/muhyeon_shin/packages/.local-tools/android-sdk`
4. Enable Android developer options on the phone.
5. Enable USB debugging on the phone.
6. Connect the phone and approve the RSA debugging prompt.

Release signing can wait until the project is ready to export a distributable build.

## Windows Home Checklist

Install these locally on the home machine.

1. `Git`
2. `Godot 4.4.1` standard build
3. matching Godot export templates for `4.4.1.stable`
4. `OpenJDK 17`
5. `Android Studio` or Android command-line tools with the shared SDK package list above

After installation on Windows:

1. Clone the same Git repository.
2. Open the project in Godot.
3. Point Godot's Android export settings at the local Windows JDK path.
4. Point Godot's Android export settings at the local Windows Android SDK path.
5. Keep the Godot version identical to the Linux machine.

## Rough Disk Budget

Use these as planning numbers, not exact guarantees.

- Godot editor: about `0.1 GB`
- Godot export templates: about `1.2 GB`
- Android SDK required packages: about `3-5 GB`
- Android Studio, if installed: roughly `8+ GB` practical disk use
- Emulator images, if added later: often `16+ GB` total footprint

## Cross-Machine Rules

- Do not commit machine-specific export settings
- Do not hard-code local absolute paths in project files
- Avoid filenames that differ only by letter case
- Upgrade Godot only when both machines can move together
- Keep Android SDK package versions aligned

## What Codex Can Handle

Codex can handle most of the repository-side work:

- project structure
- scenes and scripts
- data files
- placeholder UI
- gameplay systems
- documentation

The user still needs to handle machine-local and device-local setup:

- installing Windows-side tools
- opening Godot and setting local SDK paths
- USB debugging approval
- release keystore management
