#!/bin/bash
echo "🔨 Generando código..."
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
echo "🔨 Generando packages..."
flutter packages pub run build_runner build --delete-conflicting-outputs
echo "✅ Generación completada"

