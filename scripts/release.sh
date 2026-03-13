#!/bin/bash
# ============================================================================
# Script de Release para Arjipagos
# ============================================================================
# Uso: ./scripts/release.sh [version] [--install] [--bundle]
#
# Ejemplos:
#   ./scripts/release.sh                    # Build APK sin cambiar versión
#   ./scripts/release.sh 1.2.0              # Build APK con versión 1.2.0
#   ./scripts/release.sh 1.2.0 --install    # Build e instalar en dispositivo
#   ./scripts/release.sh 1.2.0 --bundle     # Build APK y App Bundle
#   ./scripts/release.sh --install          # Build e instalar sin cambiar versión
# ============================================================================

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Arjipagos - Build de Release${NC}"
echo -e "${BLUE}============================================${NC}"

# Parsear argumentos
VERSION=""
INSTALL=false
BUNDLE=false

for arg in "$@"; do
    case $arg in
        --install)
            INSTALL=true
            ;;
        --bundle)
            BUNDLE=true
            ;;
        *)
            if [[ $arg =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                VERSION=$arg
            fi
            ;;
    esac
done

# Actualizar versión si se especificó
if [ -n "$VERSION" ]; then
    echo -e "\n${YELLOW}► Actualizando versión a $VERSION...${NC}"

    # Obtener build number actual y incrementar
    CURRENT_BUILD=$(grep "version:" pubspec.yaml | sed 's/.*+//')
    NEW_BUILD=$((CURRENT_BUILD + 1))

    # Actualizar pubspec.yaml
    sed -i "s/^version: .*/version: $VERSION+$NEW_BUILD/" pubspec.yaml

    echo -e "${GREEN}  ✓ Versión actualizada: $VERSION+$NEW_BUILD${NC}"
fi

# Mostrar versión actual
CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
echo -e "\n${BLUE}► Versión actual: $CURRENT_VERSION${NC}"

# Limpiar build anterior (opcional, comentar si no se desea)
# echo -e "\n${YELLOW}► Limpiando build anterior...${NC}"
# flutter clean

# Obtener dependencias
echo -e "\n${YELLOW}► Verificando dependencias...${NC}"
flutter pub get

# Analizar código
echo -e "\n${YELLOW}► Analizando código...${NC}"
flutter analyze --no-fatal-infos
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Sin errores de análisis${NC}"
fi

# Build APK
echo -e "\n${YELLOW}► Construyendo APK de release...${NC}"
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "${GREEN}  ✓ APK generado: $APK_PATH ($APK_SIZE)${NC}"

# Build App Bundle si se solicitó
if [ "$BUNDLE" = true ]; then
    echo -e "\n${YELLOW}► Construyendo App Bundle para Play Store...${NC}"
    flutter build appbundle --release

    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo -e "${GREEN}  ✓ App Bundle generado: $AAB_PATH ($AAB_SIZE)${NC}"
fi

# Instalar en dispositivo si se solicitó
if [ "$INSTALL" = true ]; then
    echo -e "\n${YELLOW}► Instalando en dispositivo...${NC}"

    # Verificar si hay dispositivo conectado
    if adb devices | grep -q "device$"; then
        adb install -r "$APK_PATH"
        echo -e "${GREEN}  ✓ APK instalado correctamente${NC}"
    else
        echo -e "${RED}  ✗ No hay dispositivo conectado${NC}"
        exit 1
    fi
fi

# Resumen final
echo -e "\n${BLUE}============================================${NC}"
echo -e "${GREEN}   Build completado exitosamente${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "  Versión: $CURRENT_VERSION"
echo -e "  APK: $APK_PATH"
if [ "$BUNDLE" = true ]; then
    echo -e "  AAB: $AAB_PATH"
fi
echo -e "${BLUE}============================================${NC}"
