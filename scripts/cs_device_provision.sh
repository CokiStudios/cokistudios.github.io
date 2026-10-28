#!/bin/zsh
#
#  scripts/cs_device_provision.sh
#  Coki Studios MDM & Device Provisioning Utility (zsh native)
#  Extracts Hardware ECID, UDID, Serial, registers to MDM Worker & preserves SHSH Blobs
#

set -e

MDM_API="https://cokistudios.com/api/mdm"
SUPABASE_URL="https://cmkumxprmmhuinxfppxl.supabase.co/rest/v1"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${CYAN}    COKI STUDIOS — APROVISIONAMIENTO MDM & ECID/SHSH ${NC}"
    echo -e "${CYAN}======================================================${NC}"
}

usage() {
    echo -e "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --detect               Detecta dispositivos Apple conectados por USB o el Mac local"
    echo "  --register             Registra el dispositivo detectado en el MDM de Coki Studios"
    echo "  --user <email>         Asigna el dispositivo al correo de un tester/colaborador"
    echo "  --notes <texto>        Notas o destino del dispositivo (ej. 'Tester Forkar Beta')"
    echo "  --save-blob <path>     Sube un archivo .shsh2 o ticket plist al servidor para el ECID"
    echo "  --request-tss          Solicita a Apple TSS (gs.apple.com) un ticket en vivo para el ECID"
    echo "  --download-profile     Descarga el perfil .mobileconfig de supervisión de Coki Studios"
    echo "  --list                 Lista los dispositivos supervisados registrados en Supabase/Edge"
    echo ""
    exit 1
}

# 1. Función de Detección de Dispositivo
detect_hardware() {
    echo -e "${BLUE}[*] Buscando dispositivos Apple conectados vía USB...${NC}"

    FOUND_DEVICE=false
    DEVICE_ECID=""
    DEVICE_UDID=""
    DEVICE_SERIAL=""
    DEVICE_MODEL=""
    DEVICE_OS=""
    DEVICE_BUILD=""
    DEVICE_BOARD=""
    DEVICE_CHIP=""

    # 1. Verificar si cfgutil de Apple Configurator está disponible
    CFGUTIL_BIN=""
    if command -v cfgutil >/dev/null 2>&1; then
        CFGUTIL_BIN="cfgutil"
    elif [[ -x "/Applications/Apple Configurator.app/Contents/MacOS/cfgutil" ]]; then
        CFGUTIL_BIN="/Applications/Apple Configurator.app/Contents/MacOS/cfgutil"
    fi

    if [[ -n "$CFGUTIL_BIN" ]]; then
        CFG_OUTPUT=$("$CFGUTIL_BIN" list 2>/dev/null || true)
        if [[ -n "$CFG_OUTPUT" && "$CFG_OUTPUT" =~ "Type:" ]]; then
            FOUND_DEVICE=true
            echo -e "${GREEN}[+] Detectado dispositivo mediante Apple Configurator (cfgutil)...${NC}"
            DEVICE_MODEL=$(echo "$CFG_OUTPUT" | grep -o 'Type: [^ ]*' | awk '{print $2}')
            DEVICE_ECID=$(echo "$CFG_OUTPUT" | grep -o 'ECID: [^ ]*' | awk '{print $2}')
            DEVICE_UDID=$(echo "$CFG_OUTPUT" | grep -o 'UDID: [^ ]*' | awk '{print $2}')
            
            # Obtener detalles adicionales en una sola llamada rápida
            GET_ALL=$("$CFGUTIL_BIN" get firmwareVersion buildVersion serialNumber isSupervised 2>/dev/null || true)
            DEVICE_OS=$(echo "$GET_ALL" | grep -A 1 "firmwareVersion:" | tail -n 1 | tr -d '[:space:]')
            DEVICE_BUILD=$(echo "$GET_ALL" | grep -A 1 "buildVersion:" | tail -n 1 | tr -d '[:space:]')
            DEVICE_SERIAL=$(echo "$GET_ALL" | grep -A 1 "serialNumber:" | tail -n 1 | tr -d '[:space:]')
            IS_SUPERVISED=$(echo "$GET_ALL" | grep -A 1 "isSupervised:" | tail -n 1 | tr -d '[:space:]')
        fi
    fi

    # 2. Verificar si ideviceinfo está instalado
    if [[ "$FOUND_DEVICE" = false ]] && command -v ideviceinfo >/dev/null 2>&1; then
        echo -e "${GREEN}[+] Usando libimobiledevice (ideviceinfo)...${NC}"
        DEVICE_UDID=$(ideviceinfo -k UniqueDeviceID 2>/dev/null || true)
        if [[ -n "$DEVICE_UDID" ]]; then
            FOUND_DEVICE=true
            DEVICE_ECID=$(ideviceinfo -k UniqueChipID 2>/dev/null || true)
            DEVICE_SERIAL=$(ideviceinfo -k SerialNumber 2>/dev/null || true)
            DEVICE_MODEL=$(ideviceinfo -k ProductType 2>/dev/null || true)
            DEVICE_OS=$(ideviceinfo -k ProductVersion 2>/dev/null || true)
            DEVICE_BUILD=$(ideviceinfo -k BuildVersion 2>/dev/null || true)
            DEVICE_BOARD=$(ideviceinfo -k HardwareModel 2>/dev/null || true)
            DEVICE_CHIP=$(ideviceinfo -k ChipID 2>/dev/null || true)
        fi
    fi

    # 2. Si no hay iOS por ideviceinfo, buscar descriptors USB de iOS en ioreg
    if [[ "$FOUND_DEVICE" = false ]]; then
        USB_IOS=$(ioreg -p IOUSB -l -w 0 | grep -E "idVendor.*1452" -A 10 | grep -E "kUSBSerialNumberString" | head -n 1 | awk -F'"' '{print $4}' || true)
        if [[ -n "$USB_IOS" && "$USB_IOS" =~ "-" ]]; then
            FOUND_DEVICE=true
            DEVICE_UDID="$USB_IOS"
            # Format: <ChipID>-<ECID>
            DEVICE_CHIP="0x$(echo "$USB_IOS" | cut -d'-' -f1)"
            DEVICE_ECID="0x$(echo "$USB_IOS" | cut -d'-' -f2)"
            DEVICE_MODEL="iOS Device (USB Attached)"
            echo -e "${GREEN}[+] Detectado dispositivo iOS vía USB Serial Descriptor: ${DEVICE_UDID}${NC}"
        fi
    fi

    # 3. Si no se detectó dispositivo externo, usar el Mac local (Apple Silicon / T2)
    if [[ "$FOUND_DEVICE" = false ]]; then
        echo -e "${YELLOW}[i] No se detectó iPhone/iPad por USB. Detectando hardware del Mac local...${NC}"
        HW_INFO=$(system_profiler SPHardwareDataType 2>/dev/null)
        PROV_UDID=$(echo "$HW_INFO" | grep "Provisioning UDID:" | awk '{print $3}' || true)
        SYS_SERIAL=$(echo "$HW_INFO" | grep "Serial Number (system):" | awk '{print $4}' || true)
        SYS_MODEL=$(echo "$HW_INFO" | grep "Model Identifier:" | awk '{print $3}' || true)
        SYS_CHIP=$(echo "$HW_INFO" | grep "Chip:" | awk -F': ' '{print $2}' || true)

        if [[ -n "$PROV_UDID" ]]; then
            FOUND_DEVICE=true
            DEVICE_UDID="$PROV_UDID"
            DEVICE_SERIAL="$SYS_SERIAL"
            DEVICE_MODEL="$SYS_MODEL ($SYS_CHIP)"
            # Apple Silicon UDID contains ChipID and ECID
            if [[ "$PROV_UDID" =~ "-" ]]; then
                DEVICE_CHIP="0x$(echo "$PROV_UDID" | cut -d'-' -f1)"
                DEVICE_ECID="0x$(echo "$PROV_UDID" | cut -d'-' -f2)"
            fi
            DEVICE_OS=$(sw_vers -productVersion 2>/dev/null || true)
            DEVICE_BUILD=$(sw_vers -buildVersion 2>/dev/null || true)
        fi
    fi

    if [[ "$FOUND_DEVICE" = true ]]; then
        echo -e "${GREEN}✓ Hardware Detectado:${NC}"
        echo -e "  • ${CYAN}ECID (Exclusive Chip ID):${NC} ${DEVICE_ECID:-'No reportado'}"
        echo -e "  • ${CYAN}UDID:${NC}                    ${DEVICE_UDID:-'No reportado'}"
        echo -e "  • ${CYAN}Serial Number:${NC}           ${DEVICE_SERIAL:-'No reportado'}"
        echo -e "  • ${CYAN}Modelo:${NC}                  ${DEVICE_MODEL:-'No reportado'}"
        echo -e "  • ${CYAN}Chip / Board:${NC}            ${DEVICE_CHIP:-''} / ${DEVICE_BOARD:-''}"
        echo -e "  • ${CYAN}OS / Build:${NC}              ${DEVICE_OS:-''} (${DEVICE_BUILD:-''})"
    else
        echo -e "${RED}[!] No se pudo extraer la información del dispositivo.${NC}"
        exit 1
    fi
}

# 2. Registrar en MDM Worker
register_device() {
    detect_hardware

    USER_EMAIL="${1:-dev@cokistudios.com}"
    NOTES_TEXT="${2:-Dispositivo de pruebas Coki Studios}"

    echo ""
    echo -e "${BLUE}[*] Registrando dispositivo en Coki Studios MDM Edge (${MDM_API}/devices/register)...${NC}"

    JSON_PAYLOAD=$(cat <<EOF
{
  "ecid": "${DEVICE_ECID}",
  "udid": "${DEVICE_UDID}",
  "serial_number": "${DEVICE_SERIAL}",
  "device_name": "${DEVICE_MODEL}",
  "model": "${DEVICE_MODEL}",
  "board_config": "${DEVICE_BOARD}",
  "chip_id": "${DEVICE_CHIP}",
  "os_version": "${DEVICE_OS}",
  "build_version": "${DEVICE_BUILD}",
  "is_supervised": true,
  "assigned_user_email": "${USER_EMAIL}",
  "notes": "${NOTES_TEXT}"
}
EOF
)

    RESP=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" \
        "${MDM_API}/devices/register" || true)

    if [[ -z "$RESP" || "$RESP" =~ "404" ]]; then
        # Respaldo directo a Supabase
        RESP=$(curl -s -X POST \
            -H "apikey: ${SUPABASE_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_KEY}" \
            -H "Content-Type: application/json" \
            -H "Prefer: return=representation,resolution=merge-duplicates" \
            -d "$JSON_PAYLOAD" \
            "${SUPABASE_URL}/managed_devices?on_conflict=ecid")
        echo -e "${GREEN}✓ Dispositivo registrado exitosamente en la Bóveda Supabase de Coki Studios:${NC}"
        echo "$RESP" | jq -C . 2>/dev/null || echo "$RESP"
    else
        echo -e "${GREEN}Respuesta del Servidor:${NC}"
        echo "$RESP" | grep -o '"message":[^,}]*' || echo "$RESP"
    fi
}

# 3. Guardar SHSH Blob
save_blob() {
    FILE_PATH="$1"
    if [[ ! -f "$FILE_PATH" ]]; then
        echo -e "${RED}[!] Archivo no encontrado: $FILE_PATH${NC}"
        exit 1
    fi

    detect_hardware

    echo -e "${BLUE}[*] Leyendo y codificando ticket SHSH (${FILE_PATH})...${NC}"
    BLOB_CONTENT=$(cat "$FILE_PATH")

    JSON_PAYLOAD=$(cat <<EOF
{
  "ecid": "${DEVICE_ECID}",
  "ios_version": "${DEVICE_OS:-'18.1'}",
  "build_id": "${DEVICE_BUILD:-'22B83'}",
  "board_config": "${DEVICE_BOARD:-'d73ap'}",
  "generator": "0x1111111111111111",
  "blob_format": "shsh2",
  "blob_payload": $(echo "$BLOB_CONTENT" | sed 's/\\/\\\\/g' | jq -Rs . 2>/dev/null || echo "\"$BLOB_CONTENT\"")
}
EOF
)

    echo -e "${BLUE}[*] Subiendo a Coki Studios Vault (${MDM_API}/blobs/save)...${NC}"
    RESP=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" \
        "${MDM_API}/blobs/save")

    echo -e "${GREEN}Resultado:${NC} $RESP"
}

# 4. Solicitar TSS directo a Apple
request_tss() {
    detect_hardware

    echo -e "${BLUE}[*] Enviando solicitud de firma TSS a Apple (gs.apple.com) para ECID ${DEVICE_ECID}...${NC}"

    JSON_PAYLOAD=$(cat <<EOF
{
  "ecid": "${DEVICE_ECID}",
  "board_config": "${DEVICE_BOARD:-'0x0e'}",
  "chip_id": "${DEVICE_CHIP:-'0x8120'}",
  "build_id": "${DEVICE_BUILD:-'live'}",
  "ios_version": "${DEVICE_OS:-'current'}"
}
EOF
)

    RESP=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" \
        "${MDM_API}/blobs/request-tss")

    echo -e "${GREEN}Resultado TSS:${NC} $RESP"
}

# 5. Descargar Perfiles .mobileconfig
download_profile() {
    SUPERVISED_FILE="CokiStudios-Supervised.mobileconfig"
    ENROLL_FILE="CokiStudios-Enrollment.mobileconfig"

    echo -e "${BLUE}[*] Descargando perfiles oficiales de Coki Studios...${NC}"
    curl -s -o "$SUPERVISED_FILE" "${MDM_API}/profile/supervised"
    curl -s -o "$ENROLL_FILE" "${MDM_API}/enroll"

    echo -e "${GREEN}✓ Perfiles listos en:${NC}"
    echo -e "   1. ${CYAN}$(pwd)/${SUPERVISED_FILE}${NC} (Perfil de Restricciones & Supervisión Directa - Recomendado para Apple Configurator)"
    echo -e "   2. ${CYAN}$(pwd)/${ENROLL_FILE}${NC} (Perfil de Enrolamiento MDM con Certificado de Identidad)"
    echo ""
    echo -e "${YELLOW}[i] Instrucciones para Apple Configurator (ej. iPad 3 / iOS 9):${NC}"
    echo -e "   1. En Apple Configurator, selecciona tu iPad y pulsa 'Preparar' (Prepare)."
    echo -e "   2. Elige 'Configuración manual', marca 'Supervisar dispositivos' y selecciona 'No inscribirse en MDM'."
    echo -e "   3. Una vez supervisado, arrastra '${SUPERVISED_FILE}' sobre el iPad."
    echo -e "   4. ¡El iPad quedará bloqueado y supervisado sin error 0x6!"
}

# 6. Listar Dispositivos Registrados
list_devices() {
    echo -e "${BLUE}[*] Consultando flota de dispositivos supervisados en Supabase...${NC}"
    curl -s -H "apikey: ${SUPABASE_KEY}" -H "Authorization: Bearer ${SUPABASE_KEY}" "${SUPABASE_URL}/managed_devices?order=created_at.desc&select=ecid,udid,model,device_name,os_version,is_supervised,notes" | jq -C . 2>/dev/null || curl -s -H "apikey: ${SUPABASE_KEY}" -H "Authorization: Bearer ${SUPABASE_KEY}" "${SUPABASE_URL}/managed_devices?select=ecid,udid,model,os_version"
}

# Main Execution Flow
print_banner

if [[ $# -eq 0 ]]; then
    usage
fi

ASSIGNED_USER="dev@cokistudios.com"
NOTES_ARG="Dispositivo de pruebas Coki Studios"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --detect)
            detect_hardware
            shift
            ;;
        --register)
            register_device "$ASSIGNED_USER" "$NOTES_ARG"
            shift
            ;;
        --user)
            ASSIGNED_USER="$2"
            shift 2
            ;;
        --notes)
            NOTES_ARG="$2"
            shift 2
            ;;
        --save-blob)
            save_blob "$2"
            shift 2
            ;;
        --request-tss)
            request_tss
            shift
            ;;
        --download-profile)
            download_profile
            shift
            ;;
        --list)
            list_devices
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}[!] Opción desconocida: $1${NC}"
            usage
            ;;
    esac
done
