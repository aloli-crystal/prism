#!/bin/bash
# Build universal binary (arm64 + x86_64) pour macOS
set -e

cd "$(dirname "$0")/.."

echo "=== Build Universal Binary ==="
echo ""

# 1. Build arm64 (natif sur Apple Silicon)
echo "[1/3] Build arm64..."
crystal build src/prism.cr -o bin/prism-arm64 --release --no-debug
echo "      $(file bin/prism-arm64 | grep -o 'arm64\|x86_64')"

# 2. Build x86_64 (cross-compile)
echo "[2/3] Build x86_64 (cross-compile)..."
crystal build src/prism.cr -o bin/prism-x86_64 --release --no-debug --target x86_64-apple-macosx
echo "      $(file bin/prism-x86_64 | grep -o 'arm64\|x86_64')"

# 3. Combiner avec lipo
echo "[3/3] Création du universal binary..."
lipo -create bin/prism-arm64 bin/prism-x86_64 -output bin/prism
echo "      $(file bin/prism | grep -o 'arm64\|x86_64' | tr '\n' '+' | sed 's/+$//')"
echo "      $(du -h bin/prism | cut -f1)"

# Nettoyage
rm -f bin/prism-arm64 bin/prism-x86_64

echo ""
echo "Universal binary : bin/prism"
echo "Lancez ./scripts/build-app.sh pour créer le .app et DMG"
