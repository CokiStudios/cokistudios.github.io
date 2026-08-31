#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# [HOLO LOOPING OoS] VirtualBox Automated VM Creator & Launcher
# Target Hardware: Shine Loop Console Emulation
# ═══════════════════════════════════════════════════════════════

set -e

VM_NAME="ShineLoop-HoloLoopingOoS"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OOS_DIR="$ROOT_DIR/holo-looping-oos"
VBOX="/usr/local/bin/vboxmanage"

echo "----------------------------------------------------------------------"
echo "[VIRTUALBOX] Configuring Shine Loop Gaming Virtual Machine..."
echo "VM Name: $VM_NAME"
echo "Engine:  Holo Looping OoS 1.0 (Linux Core)"
echo "----------------------------------------------------------------------"

# 1. Unregister previous VM if exists
if $VBOX list vms | grep -q "\"$VM_NAME\""; then
    echo "[VM] Removing existing $VM_NAME instance..."
    $VBOX controlvm "$VM_NAME" poweroff 2>/dev/null || true
    sleep 1
    $VBOX unregistervm "$VM_NAME" --delete || true
fi

# 2. Create New Virtual Machine
echo "[VM 1/4] Creating VM definition..."
$VBOX createvm --name "$VM_NAME" --ostype "Linux_64" --register

# 3. Configure Hardware Specs (Optimized for Shine Loop Low-Latency Gaming)
echo "[VM 2/4] Setting Hardware Specs (2GB RAM, 2 VCPUs, 128MB VRAM, VMSVGA)..."
$VBOX modifyvm "$VM_NAME" \
    --memory 2048 \
    --cpus 2 \
    --vram 128 \
    --graphicscontroller vmsvga \
    --accelerate3d on \
    --audio-enabled on \
    --audio-driver coreaudio \
    --boot1 dvd \
    --boot2 disk \
    --nic1 nat

# 4. Storage Controller
echo "[VM 3/4] Attaching SATA Controller..."
$VBOX storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci --bootable on

# 5. Launch Summary
echo "----------------------------------------------------------------------"
echo "[SUCCESS] Virtual Machine '$VM_NAME' is registered in VirtualBox!"
echo ""
echo "To start the VM via GUI, open VirtualBox and click 'Start'."
echo "Or start headlessly / windowed via CLI with:"
echo "  vboxmanage startvm \"$VM_NAME\""
echo "----------------------------------------------------------------------"
