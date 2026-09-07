# Controller Macros

Input mapping and button swap scripts for gaming controllers (e.g., DualShock / DS1) using Python.

---

## 📦 Required Packages

To run the controller macro scripts on Debian-based systems:

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

---

## 📂 Structure

- `ControllerMacros/DS1/swapDS1.py`: Python script to intercept and swap controller button mappings.
- `ControllerMacros/DS1/requirements.txt`: Python package dependencies for controller input interception.

---

## 🚀 Setup & Execution

1. Symlink with GNU Stow:
   ```bash
   cd ~/.dotfiles
   stow controllerMacros
   ```

2. Install Python dependencies:
   ```bash
   pip install -r ~/ControllerMacros/DS1/requirements.txt
   ```

3. Run the script:
   ```bash
   python3 ~/ControllerMacros/DS1/swapDS1.py
   ```
