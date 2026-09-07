import evdev
import sys
import time


def find_xbox360_device():
    # First pass: look for explicit Xbox mentions
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
        except Exception:
            continue
        name = (dev.name or '').lower()
        if 'xbox' in name or 'x-box' in name or 'xbox 360' in name or 'xbox360' in name:
            return path, dev

    # Second pass: accept any device that looks like a controller/gamepad
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
        except Exception:
            continue
        name = (dev.name or '').lower()
        if 'controller' in name or 'gamepad' in name or 'joystick' in name:
            return path, dev

    return None, None


device_path, device = find_xbox360_device()
if device is None:
    print('Could not automatically find an Xbox 360 controller.')
    print('Available input devices:')
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            print(f" - {dev.path}: {dev.name}")
        except Exception:
            print(f" - {path}: <unreadable device>")
    print('\nIf your controller is listed above, you can set `device_path` manually.')
    sys.exit(1)

print(f"Listening on {device.name} ({device_path})")

# Button codes (may vary by controller)
# Keep the existing numeric codes for compatibility; these map to typical Xbox mappings
L1 = evdev.ecodes.BTN_TL
A  = evdev.ecodes.BTN_A
Y  = evdev.ecodes.BTN_Y

# Sequence: each entry is (button_code, hold_seconds, gap_after_seconds)
SWAP_SEQUENCE = [
    (evdev.ecodes.KEY_ESC, 0.10, 0.10),
    (evdev.ecodes.KEY_RIGHT, 0.05, 0.05),
    (evdev.ecodes.KEY_E, 0.05, 0.05),
    (evdev.ecodes.KEY_E, 0.05, 0.05),
    (evdev.ecodes.KEY_DOWN, 0.05, 0.05),
    (evdev.ecodes.KEY_E, 0.05, 0.05),
    (evdev.ecodes.KEY_ESC, 0.05, 0.00),
]


def run_swap_sequence():
    # Build capability set for UInput
    keys = {evdev.ecodes.EV_KEY: [k for k, _, _ in SWAP_SEQUENCE]}
    try:
        ui = evdev.UInput(keys, name="swapDS1-controller")
    except Exception as e:
        print(f"Failed to create UInput device for keyboard events: {e}")
        return

    for key_code, hold, gap in SWAP_SEQUENCE:
        ui.write(evdev.ecodes.EV_KEY, key_code, 1)
        ui.syn()
        time.sleep(hold)
        ui.write(evdev.ecodes.EV_KEY, key_code, 0)
        ui.syn()
        if gap:
            time.sleep(gap)

    ui.close()


# Second sequence: same as SWAP_SEQUENCE but use D-Pad Up instead of Down.
NEW_SEQUENCE = [
    (evdev.ecodes.KEY_ESC, 0.10, 0.10),
    (evdev.ecodes.KEY_RIGHT, 0.05, 0.05),
    (evdev.ecodes.KEY_E, 0.05, 0.05),
    (evdev.ecodes.KEY_E, 0.05, 0.05),
    (evdev.ecodes.KEY_UP, 0.05, 0.05),
    (evdev.ecodes.KEY_E, 0.05, 0.05),
    (evdev.ecodes.KEY_ESC, 0.05, 0.00),
]


def run_new_sequence():
    keys = {evdev.ecodes.EV_KEY: [k for k, _, _ in NEW_SEQUENCE]}
    try:
        ui = evdev.UInput(keys, name="swapDS1-controller-up")
    except Exception as e:
        print(f"Failed to create UInput device for controller-up events: {e}")
        return

    for btn_code, hold, gap in NEW_SEQUENCE:
        ui.write(evdev.ecodes.EV_KEY, btn_code, 1)
        ui.syn()
        time.sleep(hold)
        ui.write(evdev.ecodes.EV_KEY, btn_code, 0)
        ui.syn()
        if gap:
            time.sleep(gap)

    ui.close()

pressed = set()

try:
    for event in device.read_loop():
        if event.type == evdev.ecodes.EV_KEY:
            if event.value == 1:  # Key down
                pressed.add(event.code)
            elif event.value == 0:  # Key up
                pressed.discard(event.code)

            if L1 in pressed and A in pressed:
                print("L1 + A detected! Running Down swap sequence...")
                run_swap_sequence()
                pressed.clear()

            # L1 + Y triggers the alternate sequence (uses D-Pad Up instead of Down)
            if L1 in pressed and Y in pressed:
                print("L1 + Y detected! Running Up swap sequence...")
                run_new_sequence()
                pressed.clear()
except KeyboardInterrupt:
    print('\nExiting on user interrupt')
