#!/bin/bash
# ============================================================================
# Verifica que el build de release no lleve llamadas OFUSCADAS a las APIs
# obsoletas de edge-to-edge de Android 15.
# ============================================================================
# Uso: ./scripts/verificar_edge_to_edge_dex.sh [ruta.apk | ruta.aab]
#      (sin argumento revisa el APK de release y, si existe, el AAB)
#
# Por qué existe: la 1.0.34+43 salió con el aviso de Play «Tu aplicación usa
# APIs o parámetros obsoletos para la vista de extremo a extremo». Las llamadas
# a `Window.setStatusBarColor`/`setNavigationBarColor` eran de androidx
# (`enableEdgeToEdge()`, sus ramas para Android < 15), pero R8 las había
# ofuscado como `d.s`, `d.t`, `d.v` y Play no supo atribuirlas a la librería.
# La regla `-keepnames` de `android/app/proguard-rules.pro` lo arregla; este
# script comprueba en el binario de verdad que sigue así — el test unitario
# solo ve el archivo de reglas, no lo que R8 produce.
#
# Falla si alguna clase que llame a esas APIs no es de `androidx` ni de
# `io.flutter` (es decir: ofuscada, o código nuestro o de un plugin nuevo).
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# dexdump viene en build-tools del SDK de Android; se toma la más reciente.
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
DEXDUMP=$(ls -d "$SDK"/build-tools/*/ 2>/dev/null | sort -V | tail -1)dexdump
if [ ! -x "$DEXDUMP" ]; then
    echo -e "${RED}  ✗ No se encontró dexdump en $SDK/build-tools${NC}"
    exit 1
fi

# Binarios a revisar
if [ -n "$1" ]; then
    BINARIOS=("$1")
else
    BINARIOS=("build/app/outputs/flutter-apk/app-release.apk")
    AAB="build/app/outputs/bundle/release/app-release.aab"
    [ -f "$AAB" ] && BINARIOS+=("$AAB")
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FALLO=false
for BIN in "${BINARIOS[@]}"; do
    if [ ! -f "$BIN" ]; then
        echo -e "${RED}  ✗ No existe $BIN${NC}"
        exit 1
    fi

    # En el APK los dex van en la raíz; en el AAB, dentro de base/dex/.
    rm -rf "$TMP/dex"
    unzip -oqj "$BIN" 'classes*.dex' 'base/dex/classes*.dex' -d "$TMP/dex" 2>/dev/null || true
    if ! ls "$TMP/dex"/classes*.dex >/dev/null 2>&1; then
        echo -e "${RED}  ✗ $BIN no contiene archivos .dex${NC}"
        exit 1
    fi

    # Clases que invocan las APIs obsoletas (una por línea, sin repetir).
    LLAMADORES=$(for f in "$TMP/dex"/classes*.dex; do "$DEXDUMP" -d "$f" 2>/dev/null; done |
        awk '/Class descriptor/ {c = $4}
             /invoke-[a-z]+.*Landroid\/view\/Window;\.(setStatusBarColor|setNavigationBarColor|setNavigationBarDividerColor):/ {print c}' |
        tr -d "'" | sort -u)

    # Atribuibles: androidx y Flutter conservan su nombre y Play las reconoce.
    AJENOS=$(echo "$LLAMADORES" | grep -vE '^L(androidx|io/flutter)/' | grep -v '^$' || true)

    if [ -n "$AJENOS" ]; then
        FALLO=true
        echo -e "${RED}  ✗ $BIN: llamadas a APIs obsoletas de edge-to-edge desde clases no atribuibles:${NC}"
        echo "$AJENOS" | sed 's/^/      /'
    else
        echo -e "${GREEN}  ✓ $BIN: sin llamadas ofuscadas a APIs obsoletas de edge-to-edge${NC}"
    fi
done

if [ "$FALLO" = true ]; then
    echo -e "${YELLOW}  Play mostrará el aviso de APIs obsoletas. Revisar la regla -keepnames de"
    echo -e "  android/app/proguard-rules.pro (ver «Edge-to-edge de Android 15» en CLAUDE.md).${NC}"
    exit 1
fi
