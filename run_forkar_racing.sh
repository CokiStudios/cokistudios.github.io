#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🏎️ RUN FORKAR RACING 3D (CSID & Looping Dynamic Engine)
# Coki Studios & Holo Entertainment
# ═══════════════════════════════════════════════════════════════

set -e
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$ROOT_DIR/sample_loop_projects/forkar_racing_3d.loop"

echo "=========================================================="
echo "🏎️  Launching Forkar Racing 3D"
echo "   Identity: Coki Studios ID (CSID) Real-Time Validation"
echo "   Engine: 100% Looping Native + Dynamic Python PyLoop Kernel"
echo "   Target UI: XUI Direct-to-Vulkan 240Hz / Shine APU"
echo "=========================================================="

if [ "$1" == "--gui" ] || [ "$1" == "-g" ]; then
    echo "🖥️  Opening Forkar Racing 3D in Loop OS GUI mode..."
    looping --gui "$SCRIPT_PATH"
else
    looping "$SCRIPT_PATH"
fi
