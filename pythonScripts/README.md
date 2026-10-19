# Python Scripts

Standalone Python utilities deployed to `~/Projects/PythonScripts`.

---

## 📑 Index

- [Required Packages](#-required-packages)
- [Structure](#-structure)
- [Setup & Execution](#-setup--execution)
- [Permissions](#-permissions)

---

## 📦 Required Packages

These scripts target Debian-based systems and install their dependencies into a
project-local virtual environment:

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

---

## 📂 Structure

- `Projects/PythonScripts/DS1WeaponSwap/swapDS1.py`: intercepts Xbox 360 controller
  input and replays a key sequence to swap weapons in DS1.
- `Projects/PythonScripts/DS1WeaponSwap/requirements.txt`: Python dependencies.

After stowing, these files live at `~/Projects/PythonScripts/DS1WeaponSwap/`.

---

## 🚀 Setup & Execution

1. Create the shared directory and symlink the package with GNU Stow:

   ```bash
   mkdir -p ~/Projects
   cd ~/.dotfiles
   stow pythonScripts
   ```

2. Create a virtual environment next to the script:

   ```bash
   python3 -m venv ~/Projects/PythonScripts/DS1WeaponSwap/.venv
   ```

3. Install the Python dependencies into that environment:

   ```bash
   ~/Projects/PythonScripts/DS1WeaponSwap/.venv/bin/pip install \
     -r ~/Projects/PythonScripts/DS1WeaponSwap/requirements.txt
   ```

4. Run the script with the environment's interpreter:

   ```bash
   ~/Projects/PythonScripts/DS1WeaponSwap/.venv/bin/python3 \
     ~/Projects/PythonScripts/DS1WeaponSwap/swapDS1.py
   ```

   Alternatively, activate the environment first and use plain `python3`:

   ```bash
   source ~/Projects/PythonScripts/DS1WeaponSwap/.venv/bin/activate
   python3 ~/Projects/PythonScripts/DS1WeaponSwap/swapDS1.py
   ```

The virtual environment lives at `~/Projects/PythonScripts/DS1WeaponSwap/.venv`.
It is listed in this module's `.gitignore`, so it never dirties the repository —
it sits inside the stowed directory but stays untracked. To rebuild it from
scratch, delete that `.venv` directory and repeat steps 2–3.

---

## 🔑 Permissions

`swapDS1.py` reads the controller's `/dev/input/event*` device and emits synthetic
key events through `/dev/uinput`. Both are root-owned by default, so either run the
script with `sudo`:

```bash
sudo ~/Projects/PythonScripts/DS1WeaponSwap/.venv/bin/python3 \
  ~/Projects/PythonScripts/DS1WeaponSwap/swapDS1.py
```

or add your user to the `input` group and grant write access to `/dev/uinput` with a
udev rule. Without one of these, the script starts but cannot create the virtual
keyboard.

Invoking the environment's interpreter by its absolute path (as above) works fine
under `sudo`, which otherwise resets the shell environment — so there is no need to
activate the virtual environment first.
