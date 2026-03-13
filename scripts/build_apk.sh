#!/bin/bash
echo "📦 Construyendo APK..."
flutter build apk --release --split-per-abi
echo "✅ APK generado en: build/app/outputs/flutter-apk/"
