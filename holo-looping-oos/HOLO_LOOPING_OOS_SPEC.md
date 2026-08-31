# ═══════════════════════════════════════════════════════════════
# [HOLO LOOPING OoS 1.0] Microkernel Boot & Architecture Specification
# Real Linux-Based Gaming Operating System for Shine Loop Console
# Sub-division of Holo Entertainment by Coki Studios
# ═══════════════════════════════════════════════════════════════

## 1. Overview & Kernel Architecture
Holo Looping OoS is a real low-latency Linux-based gaming operating system designed specifically for the **Shine Loop Console**. It bridges raw Linux hardware (GPU, Audio, Gamepad) directly to the **Looping Compile Engine** without the overhead of heavy desktop environments like GNOME or X11.

```
+-------------------------------------------------------------+
|               SHINE LOOP DASHBOARD & GAME RUNTIME           |
|                (Looping Compile .loop Language)             |
+-------------------------------------------------------------+
|          LOOPING ENGINE RUNTIME & VULKAN COMPOSITOR         |
|               (Gamescope / Low Latency 60Hz-120Hz)          |
+-------------------------------------------------------------+
|            HOLO LOOPING SYSTEM DAEMONS & DRIVERS            |
|         - shineloop-input (HID Gamepad Subsystem)           |
|         - shineloop-audio (ALSA Direct Hardware Tone/Synth) |
|         - shineloop-scheduler (Real-Time Process Priority)  |
+-------------------------------------------------------------+
|               LINUX KERNEL 6.6+ LTS (Gaming Zen)            |
+-------------------------------------------------------------+
```

---

## 2. Kernel System Calls (Syscalls) in Looping Language
Developers writing `.loop` applications can directly invoke operating system functions:

### 2.1 Low-level Hardware Calls (`syscall`)
```loop
# Allocate direct video frame buffer
syscall allocate_vram with args "1280x720@60"

# Sync input state from Shine Loop Gamepad
syscall sync_gamepad_state with args "port_0"
```

### 2.2 Multitasking & Process Scheduler (`spawn process`)
```loop
# Spawn background audio synthesizer
spawn process "audio_synth_daemon" with priority 1

# Spawn network multiplayer sync loop
spawn process "coki_net_sync" with priority 5
```

### 2.3 Audio Hardware Synthesizer (`play tone`)
```loop
# Play jump acoustic wave (587Hz for 80ms)
play tone at 587 Hz for 80 ms

# Play collect coin chime (880Hz for 120ms)
play tone at 880 Hz for 120 ms
```

---

## 3. Fast-Boot Systemd Services
Holo Looping OoS boots in under 3.5 seconds directly into the `dashboard.loop` via systemd:

- `rootfs/etc/systemd/system/shineloop.service`
- `rootfs/usr/local/bin/shineloop-session` (Gamescope Compositor)

---

## 4. How to Build & Test the OS
1. **Run OS Simulator on Mac/Linux**:
   ```bash
   ./bin/looping --gui holo-looping-oos/dashboard.loop
   ```
2. **Build Bootable Distribution Tree**:
   ```bash
   ./holo-looping-oos/build_iso.sh
   ```
