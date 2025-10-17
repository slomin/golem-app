# Mobile MCP Workflow

## Quick Reference
- Check available devices first: `mobile_list_available_devices`.
- Avoid unnecessary rebuilds. If the simulator already has the app running, interact directly with MCP tools.
- List installed apps per device to confirm bundle IDs: `mobile_list_apps` (e.g., `Golem App` → `app.golem.client.golemApp`).
- Launch only if needed: `mobile_launch_app`. Skip when the app is already in the foreground to save time.

## Typical Interaction Loop
1. **Inspect** the current UI:
   - `mobile_list_elements_on_screen` for the accessibility tree (preferred).
   - `mobile_take_screenshot` if coordinates are needed or the hierarchy is sparse.
2. **Interact** with controls:
   - Tap buttons: `mobile_click_on_screen_at_coordinates` using element bounds (center = `x + width/2`, `y + height/2`).
   - Type text: `mobile_type_keys`, optionally `submit: true` for Return.
   - Sliders/scroll: `mobile_swipe_on_screen` with direction and optional `distance`/`x`/`y`.
   - Long press or double tap using the corresponding tools if a context menu is required.
3. **Validate state changes**:
   - Re-run `mobile_list_elements_on_screen` to confirm text/value updates (e.g., slider label changed to `48 t/s`).
   - Capture logs or screenshots when useful (`mobile_take_screenshot`).

## Testing Discipline
- Run `flutter test` after changes (widget test suite now covers the slider behavior).
- Use MCP to do quick smoke checks without rebuilding, mirroring manual QA steps on both Android (`emulator-5554`) and iOS (`iPhone 16 Pro sim_01`).
- Apple Foundation Model flows require real iOS hardware to produce live tokens; when unavailable, expect the fallback fake LLM. Keep the physical device handy (e.g., iPhone 15 Pro Max) and drive it through MCP once the bridge is wired.
- Record coordinates or accessibility labels as you explore so future MCP sessions can reuse them.
