# Python Scripts

Standalone Python utilities deployed to `~/Projects/PythonScripts`.

---

## 📑 Index

- [Required Packages](#-required-packages)
- [Structure](#-structure)
- [Setup & Execution](#-setup--execution)
  - [DS1 Weapon Swap](#-ds1-weapon-swap)
  - [PDF to CSV](#-pdf-to-csv)
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
- `Projects/PythonScripts/pdf-to-csv/convert.py`: batch-extracts tables from PDF
  files and exports them as semicolon-separated CSV files.
- `Projects/PythonScripts/pdf-to-csv/requirements.txt`: Python dependencies.

After stowing, these files live under `~/Projects/PythonScripts/`.

---

## 🚀 Setup & Execution

1. Create the shared directory and symlink the package with GNU Stow:

   ```bash
   mkdir -p ~/Projects
   cd ~/.dotfiles
   stow pythonScripts
   ```

2. Create a virtual environment next to the script you want to run:

   ```bash
   python3 -m venv ~/Projects/PythonScripts/DS1WeaponSwap/.venv
   python3 -m venv ~/Projects/PythonScripts/pdf-to-csv/.venv
   ```

3. Install the Python dependencies into each environment:

   ```bash
   ~/Projects/PythonScripts/DS1WeaponSwap/.venv/bin/pip install \
     -r ~/Projects/PythonScripts/DS1WeaponSwap/requirements.txt

   ~/Projects/PythonScripts/pdf-to-csv/.venv/bin/pip install \
     -r ~/Projects/PythonScripts/pdf-to-csv/requirements.txt
   ```

The virtual environments live inside the stowed directories but are listed in
this module's `.gitignore`, so they never dirty the repository. To rebuild one,
delete its `.venv` directory and repeat the steps above.

### 🎮 DS1 Weapon Swap

1. Run the script with the environment's interpreter:

   ```bash
   ~/Projects/PythonScripts/DS1WeaponSwap/.venv/bin/python3 \
     ~/Projects/PythonScripts/DS1WeaponSwap/swapDS1.py
   ```

   Alternatively, activate the environment first and use plain `python3`:

   ```bash
   source ~/Projects/PythonScripts/DS1WeaponSwap/.venv/bin/activate
   python3 ~/Projects/PythonScripts/DS1WeaponSwap/swapDS1.py
   ```

### 📄 PDF to CSV

1. Drop the `.pdf` files to parse into `~/Projects/PythonScripts/pdf-to-csv/input/`.

2. Run the extractor from its project directory:

   ```bash
   cd ~/Projects/PythonScripts/pdf-to-csv
   .venv/bin/python3 convert.py
   ```

   Each `input/<name>.pdf` produces `output/<name>.csv`. Folders are created by
   the stowed package; generated CSVs stay untracked by Git.

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

`pdf-to-csv/convert.py` needs no elevated permissions; it only reads PDFs from
`input/` and writes CSVs to `output/`.
