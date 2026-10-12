# Running a Proton Game's OpenGL through Zink on the NVIDIA dGPU (Optimus laptop)

**Date:** 2026-09-27
**System:** Optimus laptop — Intel iGPU drives the display, NVIDIA dGPU is the PRIME render-offload source.
**Goal:** Force a Steam/Proton game that uses **OpenGL** to render through **Zink** (Mesa's OpenGL-on-Vulkan driver) on the **NVIDIA** card.

---

## Problem

Originally used this Steam launch option:

```
mangohud __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=mesa MESA_LOADER_DRIVER_OVERRIDE=zink %command%
```

The game opened, but rendered on the **Intel iGPU**. Running the same variables against a native app worked:

```
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=mesa MESA_LOADER_DRIVER_OVERRIDE=zink glxgears
```

…which correctly rendered on the NVIDIA GPU. So the same environment worked for a native app but not for a Proton game.

---

## Root cause

`__NV_PRIME_RENDER_OFFLOAD=1` does **not** select a GPU by itself. It only arms driver-specific mechanisms:

- **OpenGL (GLX/EGL):** it makes **NVIDIA's** GLX/EGL vendor library the offload source. Here that path is deliberately bypassed, because `__GLX_VENDOR_LIBRARY_NAME=mesa` forces GLVND to load **Mesa's** GLX vendor instead.
- **Vulkan:** it enables NVIDIA's implicit layer `VK_LAYER_NV_optimus`, which reorders the Vulkan physical-device list so NVIDIA is enumerated **first**.

**Zink is an OpenGL driver that runs on top of Vulkan**, so which card is used is decided by **which Vulkan device Zink picks** — not by the GLX vendor.

NVIDIA's documentation states:

> "The `__NV_PRIME_RENDER_OFFLOAD` environment variable causes the special Vulkan layer `VK_LAYER_NV_optimus` to be loaded… The `VK_LAYER_NV_optimus` layer causes the GPUs to be sorted such that the NVIDIA GPUs are enumerated first."

### Why the native command worked

On the host, everything is direct:

1. `__GLX_VENDOR_LIBRARY_NAME=mesa` → GLVND loads Mesa's GLX vendor lib.
2. `MESA_LOADER_DRIVER_OVERRIDE=zink` → Mesa's GLX uses the Zink Gallium driver.
3. Zink enumerates Vulkan devices; `__NV_PRIME_RENDER_OFFLOAD=1` loads `VK_LAYER_NV_optimus`, pushing NVIDIA to the front.
4. Zink picks device 0 → **NVIDIA**.

### Why the Proton game didn't

Proton runs the game inside the **Steam Linux Runtime / pressure-vessel container**. That container rewrites the Vulkan loader configuration for the game process:

- it overrides `VK_DRIVER_FILES` / `VK_ICD_FILENAMES` and `VK_IMPLICIT_LAYER_PATH` with container-internal paths, and
- it drops / ignores `VK_ADD_IMPLICIT_LAYER_PATH`.

The practical result: NVIDIA's implicit layer (`nvidia_layers.json` → `VK_LAYER_NV_optimus`) commonly does **not** get loaded inside the container (not visible, or the loader rejects it — a known packaging bug, e.g. Ubuntu #1862563). So `__NV_PRIME_RENDER_OFFLOAD=1` becomes a **silent no-op for Vulkan device ordering** inside the game.

Meanwhile Mesa's own `VK_LAYER_MESA_device_select` layer is still active, and it defaults to the **display-connected GPU** — the Intel iGPU. Zink then takes the first device it is handed and renders on Intel.

Valve acknowledges this class of problem in the Steam Linux Runtime docs:

> "The mechanism for selecting the correct Vulkan driver and GPU on Linux is not fully settled, and **the container can interfere with this, resulting in the wrong GPU or driver being selected**."

Note: because the game still opened, Zink *was* initializing successfully — just on Intel's Vulkan driver (ANV) instead of NVIDIA's.

Also worth knowing: **MangoHud was not involved.** Its wrapper ends with `exec env ... "$@"`, so `mangohud VAR=value %command%` does set those variables correctly; the env ordering was fine. The bug reproduced with and without `mangohud`.

---

## Fix

Do **not** rely on NVIDIA's layer inside the container. Instead, ask **Mesa's** device-select layer (which *is* present in the container) to put the NVIDIA GPU first.

### 1. Find the NVIDIA PCI IDs

```bash
lspci -nn | grep -Ei 'vga|3d'
# e.g.  01:00.0 VGA compatible controller: NVIDIA Corporation ... [10de:25a0]
#       00:02.0 VGA compatible controller: Intel Corporation ... [8086:xxxx]
```

Format is `vendor:device` in hex. NVIDIA vendor ID is always `10de`.

### 2. Select the device via Mesa

Either of these (`!` exposes *only* that GPU to the app):

```bash
DRI_PRIME=10de:25a0          # or DRI_PRIME=1  (first non-default GPU)
MESA_VK_DEVICE_SELECT=10de:25a0
DRI_PRIME=10de:25a0!         # force, expose only this GPU
```

`DRI_PRIME` and `MESA_VK_DEVICE_SELECT` apply to **OpenGL and Vulkan**; the Vulkan side is implemented by `VK_LAYER_MESA_device_select`.

### 3. Working Steam launch options

```
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=mesa MESA_LOADER_DRIVER_OVERRIDE=zink DRI_PRIME=10de:25a0 __VK_LAYER_NV_optimus=NVIDIA_only mangohud %command%
```

`__VK_LAYER_NV_optimus=NVIDIA_only` is harmless if the layer is missing, and definitive if it does load. Replace `10de:25a0` with your own `vendor:device`.

### 4. Dependency

The layer implementing `DRI_PRIME` / `MESA_VK_DEVICE_SELECT` for Vulkan must be installed (32-bit too, for 32-bit Proton games):

- **Arch:** `vulkan-mesa-layers` + `lib32-vulkan-mesa-layers`
- **Debian/Ubuntu:** provided by `mesa-vulkan-drivers`

---

## Verification

```bash
# Which Vulkan devices exist, and which is selected
MESA_VK_DEVICE_SELECT=list MESA_VK_DEVICE_SELECT_DEBUG=1 vulkaninfo --summary

# Is Zink the GL driver, and on which GPU?
DRI_PRIME=10de:25a0 MESA_LOADER_DRIVER_OVERRIDE=zink __GLX_VENDOR_LIBRARY_NAME=mesa \
  glxinfo -B | grep -E 'OpenGL vendor|OpenGL renderer'

# While the game runs: confirm NVIDIA is actually busy
nvidia-smi pmon -c 1
```

MangoHud should also report the NVIDIA GPU name and `OpenGL` as the API.

---

## Fallbacks

- **Set the variables on Steam itself** — launch Steam from a terminal with them exported, or use the desktop's *"Run with dedicated GPU" / "Launch using Discrete Graphics Card"* action on Steam. This applies them to the whole session, including the container.
- **Hide the Intel Vulkan ICD (nuclear).** Because the container symlinks host ICD files, renaming the Intel Vulkan ICD removes it inside the container too:
  ```bash
  sudo mv /usr/share/vulkan/icd.d/intel_icd.x86_64.json /usr/share/vulkan/icd.d/intel_icd.x86_64.json.disabled
  sudo mv /usr/share/vulkan/icd.d/intel_icd.i686.json   /usr/share/vulkan/icd.d/intel_icd.i686.json.disabled
  ```
  Effective but global — restore it afterwards.
- **If the game is actually DirectX (not OpenGL).** Then `MESA_LOADER_DRIVER_OVERRIDE=zink` does nothing and DXVK/VKD3D drives Vulkan directly. The same `DRI_PRIME` / `MESA_VK_DEVICE_SELECT` fix applies at the Vulkan level, or use `DXVK_FILTER_DEVICE_NAME="<NVIDIA model>"` (name from `vulkaninfo`).

---

## Key takeaways

- `__NV_PRIME_RENDER_OFFLOAD` is an **NVIDIA driver** mechanism; with Zink the GPU is chosen by the **Vulkan** device Zink picks.
- Outside a container, NVIDIA's `VK_LAYER_NV_optimus` handles that ordering; inside Proton's container it often doesn't load.
- Use **Mesa's** device selection (`DRI_PRIME` / `MESA_VK_DEVICE_SELECT`) instead — it is present inside the container and survives the pressure-vessel environment rewrite.

---

## References

- NVIDIA — *PRIME Render Offload* — https://download.nvidia.com/XFree86/Linux-x86_64/550.54.14/README/primerenderoffload.html
- Mesa — *Environment Variables* (`DRI_PRIME`, `MESA_VK_DEVICE_SELECT`) — https://docs.mesa3d.org/envvars.html
- ValveSoftware — *Steam Linux Runtime known issues: Multiple-GPU systems* — https://github.com/ValveSoftware/steam-runtime/blob/master/doc/steamlinuxruntime-known-issues.md
- Frank Zhao — *Steam NVIDIA GPU Selection on Dual-GPU Linux* — https://frankzhao.net/homelab/steam-nvidia-gpu-selection-on-dual-gpu-linux
- ArchWiki — *PRIME* — https://wiki.archlinux.org/title/PRIME
