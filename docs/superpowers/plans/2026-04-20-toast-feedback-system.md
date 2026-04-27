# Toast Feedback System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one shared toast presenter for indoor and outdoor that shows short info/success/warning feedback below the HUD, auto-hides, replaces older toasts, and keeps existing result text intact.

**Architecture:** Add a dedicated `ToastPresenter` `CanvasLayer` to `RunShell`, keep it presentation-only, and route short-form feedback into it from the existing `RunController` and `IndoorMode` flows. Reuse the already-loaded `feedback` assets from `frozen_ui_master_bundle_v1` and keep toast behavior intentionally narrow: one visible toast, replace-on-new-message, refresh timer on same-message replay.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `RunShell` / `RunController` / `IndoorMode` / `UiKitResolver`, headless Godot tests

---

## File Map

### Create

- `game/scenes/shared/toast_presenter.tscn`
- `game/scripts/ui/toast_presenter.gd`
- `game/tests/unit/test_toast_presenter.gd`

### Modify

- `game/scenes/run/run_shell.tscn`
- `game/scripts/run/run_controller.gd`
- `game/scripts/indoor/indoor_mode.gd`
- `game/tests/unit/test_indoor_mode.gd`
- `game/tests/unit/test_run_controller_live_transition.gd`
- `game/tests/smoke/test_first_playable_loop.gd`
- `docs/INDEX.md`
- `docs/CURRENT_STATE.md`

### Responsibilities

- `game/scenes/shared/toast_presenter.tscn`
  - Own the toast layer directly below the HUD with one reusable compact panel and one message label.
- `game/scripts/ui/toast_presenter.gd`
  - Render one toast at a time, choose `info/success/warning` skin, refresh timers, and auto-hide.
- `game/scenes/run/run_shell.tscn`
  - Mount the shared toast presenter once so both indoor and outdoor can use it.
- `game/scripts/run/run_controller.gd`
  - Route outdoor bag/craft/read/equip/drop feedback into toast and forward indoor toast requests from the active mode.
- `game/scripts/indoor/indoor_mode.gd`
  - Emit short toast requests for indoor actions and crafting while keeping the existing result text unchanged.
- tests
  - Lock one-toast behavior, timer refresh behavior, indoor/outdoor trigger wiring, and smoke-level visibility of the shared presenter.

### Implementation Note

- Keep the pass narrow. Do not add a queue, message history, or persistent status chips.
- Keep the existing result labels/cards untouched. Toast is additive in this pass.
- Keep the user’s existing preference in mind: no micro-commit churn during implementation. Verify continuously and make one wrap-up commit only after the whole pass is stable.

---

### Task 1: Lock The Shared Toast Presenter Contract

**Files:**
- Create: `game/scenes/shared/toast_presenter.tscn`
- Create: `game/scripts/ui/toast_presenter.gd`
- Create: `game/tests/unit/test_toast_presenter.gd`
- Test: `game/tests/unit/test_toast_presenter.gd`

- [ ] **Step 1: Write the failing toast presenter test**

Create `game/tests/unit/test_toast_presenter.gd` with a focused lifecycle test:

```gdscript
extends "res://tests/support/test_case.gd"

const TOAST_SCENE_PATH := "res://scenes/shared/toast_presenter.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var toast_scene := load(TOAST_SCENE_PATH) as PackedScene
	if not assert_true(toast_scene != null, "Toast presenter scene should load."):
		return

	var toast := toast_scene.instantiate() as CanvasLayer
	if not assert_true(toast != null, "Toast presenter should instantiate as a CanvasLayer."):
		return

	root.add_child(toast)
	var shell := toast.get_node_or_null("ToastShell") as Control
	var message_label := toast.get_node_or_null("ToastShell/Margin/MessageLabel") as Label
	if not assert_true(shell != null and message_label != null, "Toast presenter should expose a shell and message label."):
		toast.free()
		return

	assert_true(not shell.visible, "Toast should start hidden.")

	toast.show_toast("success", "붕대 챙겼다.", 0.4)
	assert_true(shell.visible, "Toast should become visible when shown.")
	assert_eq(message_label.text, "붕대 챙겼다.", "Toast should render the requested message.")

	toast.show_toast("success", "붕대 챙겼다.", 0.4)
	assert_eq(message_label.text, "붕대 챙겼다.", "Showing the same toast should refresh rather than duplicate.")

	toast.show_toast("warning", "가방이 가득 찼다.", 0.4)
	assert_eq(message_label.text, "가방이 가득 찼다.", "New toast messages should replace the previous toast immediately.")

	await get_tree().create_timer(0.6).timeout
	assert_true(not shell.visible, "Toast should auto-hide after its duration elapses.")

	toast.free()
	pass_test("TOAST_PRESENTER_OK")
```

- [ ] **Step 2: Run the new test and confirm failure**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_toast_presenter.gd
```

Expected:

- failure because `toast_presenter.tscn` does not exist yet

- [ ] **Step 3: Create the toast presenter scene**

Create `game/scenes/shared/toast_presenter.tscn` with this structure:

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/toast_presenter.gd" id="1"]

[node name="ToastPresenter" type="CanvasLayer"]
script = ExtResource("1")

[node name="ToastShell" type="PanelContainer" parent="."]
visible = false
anchor_left = 0.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 0.0
offset_left = 24.0
offset_top = 84.0
offset_right = -24.0
offset_bottom = 120.0
mouse_filter = 2

[node name="Margin" type="MarginContainer" parent="ToastShell"]
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 10

[node name="MessageLabel" type="Label" parent="ToastShell/Margin"]
autowrap_mode = 3
text = ""
```

- [ ] **Step 4: Write the minimal toast presenter logic**

Create `game/scripts/ui/toast_presenter.gd`:

```gdscript
extends CanvasLayer

const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const TEXT_COLOR := Color(0.96, 0.98, 1.0, 0.98)
const OUTLINE_COLOR := Color(0.04, 0.06, 0.09, 0.94)
const DEFAULT_DURATION := 2.0

var _ui_kit_resolver = UiKitResolver.new()
var _toast_shell: PanelContainer = null
var _message_label: Label = null
var _message := ""
var _type := "info"
var _remaining := 0.0


func _ready() -> void:
	_toast_shell = get_node_or_null("ToastShell") as PanelContainer
	_message_label = get_node_or_null("ToastShell/Margin/MessageLabel") as Label
	_apply_text_style()
	_apply_shell_skin()
	_hide_toast()


func show_toast(toast_type: String, message: String, duration: float = DEFAULT_DURATION) -> void:
	if _toast_shell == null or _message_label == null or message.is_empty():
		return
	_type = toast_type if toast_type in ["info", "success", "warning"] else "info"
	_message = message
	_remaining = max(0.1, duration)
	_message_label.text = _message
	_apply_shell_skin()
	_toast_shell.visible = true


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining = max(0.0, _remaining - delta)
	if _remaining <= 0.0:
		_hide_toast()


func _apply_shell_skin() -> void:
	if _toast_shell == null:
		return
	var path := "feedback/toast_info.png"
	if _type == "success":
		path = "feedback/toast_success.png"
	elif _type == "warning":
		path = "feedback/toast_warning.png"
	_ui_kit_resolver.apply_panel(_toast_shell, path)


func _apply_text_style() -> void:
	if _message_label == null:
		return
	_message_label.add_theme_color_override("font_color", TEXT_COLOR)
	_message_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	_message_label.add_theme_constant_override("outline_size", 2)
	_message_label.add_theme_font_size_override("font_size", 14)


func _hide_toast() -> void:
	_remaining = 0.0
	if _toast_shell != null:
		_toast_shell.visible = false
```

- [ ] **Step 5: Re-run the toast test and confirm it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_toast_presenter.gd
```

Expected:

- `TOAST_PRESENTER_OK`

---

### Task 2: Mount The Shared Toast In RunShell And Wire Outdoor Feedback

**Files:**
- Modify: `game/scenes/run/run_shell.tscn`
- Modify: `game/scripts/run/run_controller.gd`
- Modify: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`

- [ ] **Step 1: Add a failing controller test for the mounted toast**

In `game/tests/unit/test_run_controller_live_transition.gd`, after the shell starts, assert that a shared toast presenter exists:

```gdscript
	var toast_presenter := run_shell.get_node_or_null("ToastPresenter") as CanvasLayer
	if not assert_true(toast_presenter != null, "RunShell should mount a shared ToastPresenter."):
		bootstrap.free()
		return
	var toast_shell := toast_presenter.get_node_or_null("ToastShell") as Control
	assert_true(toast_shell != null and not toast_shell.visible, "Toast shell should exist and start hidden.")
```

Then after one outdoor bag action that already generates feedback, assert toast text updates:

```gdscript
	var toast_label := toast_presenter.get_node_or_null("ToastShell/Margin/MessageLabel") as Label
	if not assert_true(toast_label != null, "Toast presenter should expose a message label."):
		bootstrap.free()
		return
	assert_true(toast_label.text.find("버렸다") != -1 or toast_label.text.find("장착") != -1 or toast_label.text.find("익혔다") != -1, "Outdoor inventory feedback should push a short toast message.")
```

- [ ] **Step 2: Run the controller test and confirm failure**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
```

Expected:

- failure because `RunShell` has no `ToastPresenter`

- [ ] **Step 3: Mount the toast presenter in `RunShell`**

Add the shared scene to `game/scenes/run/run_shell.tscn`:

```tscn
[ext_resource type="PackedScene" path="res://scenes/shared/toast_presenter.tscn" id="5"]

[node name="ToastPresenter" parent="." instance=ExtResource("5")]
```

- [ ] **Step 4: Route outdoor feedback through the presenter**

In `game/scripts/run/run_controller.gd`, cache the toast node and add a helper:

```gdscript
var _toast_presenter: CanvasLayer = null

func _show_toast(toast_type: String, message: String, duration: float = 2.0) -> void:
	if _toast_presenter != null and _toast_presenter.has_method("show_toast") and not message.is_empty():
		_toast_presenter.show_toast(toast_type, message, duration)
```

Populate it in `start_run()`:

```gdscript
	_toast_presenter = get_node_or_null("ToastPresenter") as CanvasLayer
```

Then after the existing `_outdoor_inventory_feedback_message` assignments in:

- `_on_crafting_applied`
- `_on_survival_sheet_action_requested`

call:

```gdscript
	_show_toast("success", _outdoor_inventory_feedback_message)
```

and for blocked/neutral paths use:

```gdscript
	_show_toast("warning", _outdoor_inventory_feedback_message)
```

Use the same message text already being stored so result labels stay unchanged.

- [ ] **Step 5: Re-run the controller test and confirm it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
```

Expected:

- `RUN_CONTROLLER_LIVE_TRANSITION_OK`

---

### Task 3: Wire Indoor Actions Into The Shared Toast Without Removing Result Text

**Files:**
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Add a failing indoor test for toast emission**

In `game/tests/unit/test_indoor_mode.gd`, connect to a new `toast_requested` signal:

```gdscript
	var seen_toasts: Array[Dictionary] = []
	if not assert_true(indoor_mode.has_signal("toast_requested"), "Indoor mode should expose a toast_requested signal for the shared toast layer."):
		indoor_mode.free()
		return
	indoor_mode.toast_requested.connect(func(toast_type: String, message: String, duration: float) -> void:
		seen_toasts.append({
			"type": toast_type,
			"message": message,
			"duration": duration,
		})
	)
```

After one action that changes `ResultLabel`, assert toast emission:

```gdscript
	assert_true(not seen_toasts.is_empty(), "Indoor interactions should emit a toast alongside the existing result text.")
	assert_true(String(seen_toasts.back().get("message", "")).length() > 0, "Indoor toast messages should carry the same short feedback text.")
```

- [ ] **Step 2: Run the indoor test and confirm failure**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected:

- failure because `toast_requested` does not exist yet

- [ ] **Step 3: Add a signal and helper in `IndoorMode`**

At the top of `game/scripts/indoor/indoor_mode.gd`:

```gdscript
signal toast_requested(toast_type: String, message: String, duration: float)
```

Add a helper:

```gdscript
func _emit_feedback_toast(message: String, toast_type: String = "info", duration: float = 2.0) -> void:
	if message.is_empty():
		return
	toast_requested.emit(toast_type, message, duration)
```

After every place that updates `_result_label.text` from a fresh action/craft result, also emit toast:

```gdscript
	var feedback := String(_director.get_feedback_message())
	_result_label.text = feedback
	_emit_feedback_toast(feedback, "info")
```

For crafting:

```gdscript
	var feedback := _formatted_craft_feedback(outcome)
	_director.set_feedback_message(feedback)
	_result_label.text = feedback
	_emit_feedback_toast(feedback, "success")
```

Keep the existing `_result_label` update exactly as-is. Toast is additive.

- [ ] **Step 4: Forward indoor toast requests through `RunController`**

In `game/scripts/run/run_controller.gd`, when wiring the indoor mode in `_show_indoor_mode()`:

```gdscript
	if indoor_mode.has_signal("toast_requested"):
		indoor_mode.toast_requested.connect(Callable(self, "_on_mode_toast_requested"))
```

Add the forwarder:

```gdscript
func _on_mode_toast_requested(toast_type: String, message: String, duration: float = 2.0) -> void:
	_show_toast(toast_type, message, duration)
```

- [ ] **Step 5: Re-run the indoor test and confirm it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected:

- `INDOOR_MODE_OK`

---

### Task 4: Verify Shared Presentation And Keep Routing Docs Current

**Files:**
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`
- Test: `game/tests/unit/test_toast_presenter.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Extend the smoke test with a mounted toast assertion**

In `game/tests/smoke/test_first_playable_loop.gd`, after the shell boots:

```gdscript
	var toast_presenter := run_shell.get_node_or_null("ToastPresenter") as CanvasLayer
	if not assert_true(toast_presenter != null, "The playable loop should mount the shared toast presenter."):
		bootstrap.free()
		return
```

- [ ] **Step 2: Keep docs routing aligned**

Update:

- `docs/INDEX.md`
- `docs/CURRENT_STATE.md`

Add the new plan to the active plans list and keep the immediate priorities wording aligned with the now-approved toast work.

- [ ] **Step 3: Run the complete focused verification set**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_toast_presenter.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `TOAST_PRESENTER_OK`
- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `INDOOR_MODE_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Final wrap-up commit after the entire pass is stable**

Run:

```bash
git add docs/INDEX.md docs/CURRENT_STATE.md docs/superpowers/plans/2026-04-20-toast-feedback-system.md game/scenes/run/run_shell.tscn game/scenes/shared/toast_presenter.tscn game/scripts/run/run_controller.gd game/scripts/indoor/indoor_mode.gd game/scripts/ui/toast_presenter.gd game/tests/unit/test_toast_presenter.gd game/tests/unit/test_run_controller_live_transition.gd game/tests/unit/test_indoor_mode.gd game/tests/smoke/test_first_playable_loop.gd
git commit -m "feat: add shared toast feedback layer"
```

---

## Self-Review

- Spec coverage: the plan covers one shared presenter, one-visible-toast replacement behavior, auto-hide, type-based rendering, shared indoor/outdoor wiring, and retention of existing result text.
- Placeholder scan: no `TODO`/`TBD` placeholders remain.
- Type consistency: the new public interface stays narrow and consistent: `show_toast(type, message, duration)` and `toast_requested(type, message, duration)`.
