#!/bin/bash
echo "🧹 Limpiando proyecto..."
flutter clean
rm -rf ios/Pods
rm -rf ios/.symlinks
flutter pub get
cd ios && pod install && cd ..
echo "✅ Limpieza completada"