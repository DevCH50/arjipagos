#!/bin/bash
# ============================================================================
# Script de Build iOS para Arjipagos
# ============================================================================
# Uso: ./scripts/build_ios.sh [opciones adicionales de flutter build ios]
#
# Ejemplos:
#   ./scripts/build_ios.sh                    # Build release standard
#   ./scripts/build_ios.sh --no-codesign      # Build sin firma de código
#
# Este script envuelve `flutter build ios --release` y deja
# LastUpgradeCheck/LastUpgradeVersion en 2700 (Xcode 27).
#
# Es una red de seguridad, no un arreglo que haga falta hoy: Flutter 3.47 ya NO
# degrada esos valores. Ver el bloque de abajo.
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
XCSCHEME="ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
TARGET_VERSION="2700"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Arjipagos - Build iOS${NC}"
echo -e "${BLUE}============================================${NC}"

CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
echo -e "\n${BLUE}► Versión: $CURRENT_VERSION${NC}"

echo -e "\n${YELLOW}► Construyendo iOS release...${NC}"
flutter build ios --release "$@"

# Las versiones antiguas de Flutter bajaban estos dos valores a 1510 en cada
# build, porque no reconocían el Xcode instalado. Flutter 3.47 ya NO lo hace: su
# migración se salta cualquier valor igual o superior a 1510 (comprobado en
# `xcode_project_object_version_migration.dart`). Con el toolchain de hoy estos
# `sed` no encuentran nada que cambiar, y se conservan por si algún día se vuelve
# a una versión de Flutter que sí los degrade.
#
# 2700 es Xcode 27. El `post_install` del Podfile aplica el mismo suelo en cada
# `pod install`; al cambiar de versión de Xcode hay que tocar TARGET_VERSION aquí
# y LAST_UPGRADE_MINIMO en `ios/Podfile`.
echo -e "\n${YELLOW}► Asegurando LastUpgradeCheck/LastUpgradeVersion en $TARGET_VERSION...${NC}"

sed -i '' "s/LastUpgradeCheck = 1510/LastUpgradeCheck = $TARGET_VERSION/g" "$PBXPROJ"
sed -i '' "s/LastUpgradeVersion = \"1510\"/LastUpgradeVersion = \"$TARGET_VERSION\"/g" "$XCSCHEME"

# Verificar que los valores quedaron correctos
CHECK=$(grep -m1 "LastUpgradeCheck" "$PBXPROJ" | tr -d ' \t')
SCHEME=$(grep -m1 "LastUpgradeVersion" "$XCSCHEME" | tr -d ' \t')

if [[ "$CHECK" == *"$TARGET_VERSION"* ]] && [[ "$SCHEME" == *"$TARGET_VERSION"* ]]; then
    echo -e "${GREEN}  ✓ LastUpgradeCheck = $TARGET_VERSION${NC}"
    echo -e "${GREEN}  ✓ LastUpgradeVersion = \"$TARGET_VERSION\"${NC}"
else
    echo -e "${RED}  ✗ No se pudo restaurar los valores. Verifica manualmente.${NC}"
    exit 1
fi

echo -e "\n${BLUE}============================================${NC}"
echo -e "${GREEN}   Build iOS completado${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "  Versión: $CURRENT_VERSION"
echo -e "  App: build/ios/iphoneos/Runner.app"
echo -e "  Siguiente paso: Abrir Runner.xcworkspace en Xcode → Archive"
echo -e "${BLUE}============================================${NC}"
