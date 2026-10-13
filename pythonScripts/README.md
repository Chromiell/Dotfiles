# Python Scripts

Standalone Python utilities deployed to `~/Project/PythonScripts`.

---

## 📦 Required Packages

These scripts target Debian-based systems:

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

---

## 📂 Structure

- `Project/PythonScripts/DS1WeaponSwap/swapDS1.py`: intercepts Xbox 360 controller
  input and replays a key sequence to swap weapons in DS1.
- `Project/PythonScripts/DS1WeaponSwap/requirements.txt`: Python dependencies.

After stowing, these files live at `~/Project/PythonScripts/DS1WeaponSwap/`.

---

## 🚀 Setup & Execution

1. Create the shared directory and symlink the package with GNU Stow:

   ```bash
   mkdir -p ~/Project
   cd ~/.dotfiles
   stow pythonScripts
   ```

2. Install the Python dependencies:

   ```bash
   pip install -r ~/Project/PythonScripts/DS1WeaponSwap/requirements.txt
   ```

3. Run the script:

   ```bash
   python3 ~/Project/PythonScripts/DS1WeaponSwap/swapDS1.py
   ```

---

## 🔑 Permissions

`swapDS1.py` reads the controller's `/dev/input/event*` device and emits synthetic
key events through `/dev/uinput`. Both are root-owned by default, so either run the
script with `sudo`:

```bash
sudo python3 ~/Project/PythonScripts/DS1WeaponSwap/swapDS1.py
```

or add your user to the `input` group and grant write access to `/dev/uinput` with a
udev rule. Without one of these, the script starts but cannot create the virtual
keyboard.
