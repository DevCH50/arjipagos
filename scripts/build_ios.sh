#!/bin/bash
echo "📦 Construyendo IPA..."
# flutter build ios --release
flutter build ios --release --export-method=app-store
echo "✅ IPA listo para distribución"