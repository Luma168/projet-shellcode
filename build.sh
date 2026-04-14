#!/bin/bash
# =============================================================================
# build.sh — Compile un template ASM et extrait les bytes pour l'encodeur UwU
# =============================================================================
# Usage :
#   ./build.sh <template.s>             → compile + affiche hex
#   ./build.sh <template.s> --encode    → compile + encode en UwU (uwu_cli.py)
#   ./build.sh <template.s> --generate  → compile + génère le .bin auto-décodant
#
# Dépendances : nasm, ld, objcopy, python3 (+ uwu_cli.py dans le dossier parent)
# =============================================================================

set -e

# ── Vérifications ──────────────────────────────────────────────────────────
if [ -z "$1" ]; then
    echo "Usage: $0 <template.s> [--encode | --generate]"
    exit 1
fi

SOURCE="$1"
MODE="${2:-}"

if [ ! -f "$SOURCE" ]; then
    echo "[!] Fichier introuvable : $SOURCE"
    exit 1
fi

command -v nasm  >/dev/null 2>&1 || { echo "[!] nasm non installé (apt install nasm)"; exit 1; }
command -v ld    >/dev/null 2>&1 || { echo "[!] ld non trouvé"; exit 1; }
command -v objcopy >/dev/null 2>&1 || { echo "[!] objcopy non trouvé"; exit 1; }

# ── Chemins ────────────────────────────────────────────────────────────────
BASE=$(basename "$SOURCE" .s)
OUTDIR="/tmp/uwu_build_${BASE}"
mkdir -p "$OUTDIR"

OBJ="$OUTDIR/${BASE}.o"
ELF="$OUTDIR/${BASE}"
BIN="$OUTDIR/${BASE}.bin"

# ── Compilation ────────────────────────────────────────────────────────────
echo "[*] Compilation : $SOURCE"
nasm -f elf64 "$SOURCE" -o "$OBJ"
ld "$OBJ" -o "$ELF"
objcopy --dump-section .text="$BIN" "$ELF"

# ── Affichage des bytes ────────────────────────────────────────────────────
HEXSTR=$(xxd -p "$BIN" | tr -d '\n')
BYTECOUNT=$(wc -c < "$BIN")

echo ""
echo "╔══════════════════════════════════════════╗"
echo "  Shellcode : $BASE"
echo "  Taille    : ${BYTECOUNT} bytes"
echo "  Fichier   : $BIN"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "[+] Hex string :"
echo "    $HEXSTR"
echo ""

# Vérification null bytes
if echo "$HEXSTR" | grep -q "00"; then
    echo "[!] ATTENTION : null bytes détectés dans le shellcode !"
    echo "    → Positions :"
    echo "$HEXSTR" | sed 's/../& /g' | tr ' ' '\n' | grep -n "^00$" | awk -F: '{printf "    offset %d\n", $1-1}'
    echo ""
else
    echo "[✓] Aucun null byte détecté."
    echo ""
fi

# ── Modes optionnels ───────────────────────────────────────────────────────
CLI="$(dirname "$0")/../uwu_cli.py"

if [ "$MODE" = "--encode" ]; then
    if [ ! -f "$CLI" ]; then
        echo "[!] uwu_cli.py introuvable à : $CLI"
        echo "    Adapter le chemin si nécessaire."
        exit 1
    fi
    echo "[*] Encodage UwU..."
    python3 "$CLI" encode "$HEXSTR"

elif [ "$MODE" = "--generate" ]; then
    if [ ! -f "$CLI" ]; then
        echo "[!] uwu_cli.py introuvable à : $CLI"
        echo "    Adapter le chemin si nécessaire."
        exit 1
    fi
    OUTBIN="${BASE}_uwu.bin"
    echo "[*] Génération du shellcode auto-décodant..."
    python3 "$CLI" generate --hex "$HEXSTR" -o "$OUTBIN"
    echo "[+] Fichier généré : $OUTBIN"
fi
