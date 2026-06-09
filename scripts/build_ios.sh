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
# Este script envuelve `flutter build ios --release` y restaura
# automáticamente LastUpgradeCheck/LastUpgradeVersion a 2630 (Xcode 26.3),
# ya que Flutter los resetea a 1510 en cada build.
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
TARGET_VERSION="2630"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Arjipagos - Build iOS${NC}"
echo -e "${BLUE}============================================${NC}"

CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
echo -e "\n${BLUE}► Versión: $CURRENT_VERSION${NC}"

echo -e "\n${YELLOW}► Construyendo iOS release...${NC}"
flutter build ios --release "$@"

# Flutter resetea LastUpgradeCheck y LastUpgradeVersion a 1510 en cada build.
# Los restauramos inmediatamente para mantener la compatibilidad con Xcode 26.3.
echo -e "\n${YELLOW}► Restaurando LastUpgradeCheck/LastUpgradeVersion a $TARGET_VERSION...${NC}"

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
