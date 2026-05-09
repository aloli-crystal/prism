#!/bin/bash
# Build universal binary (arm64 + x86_64) pour macOS
set -e

cd "$(dirname "$0")/.."

echo "=== Build Universal Binary ==="
echo ""

mkdir -p bin

# 1. Build arm64 (natif sur Apple Silicon)
echo "[1/3] Build arm64..."
crystal build src/prism.cr -o bin/Prism-arm64 --release --no-debug
echo "      $(file bin/Prism-arm64 | grep -o 'arm64\|x86_64')"

# 2. Build x86_64 (cross-compile)
echo "[2/3] Build x86_64 (cross-compile)..."
crystal build src/prism.cr -o bin/Prism-x86_64 --release --no-debug --target x86_64-apple-macosx
echo "      $(file bin/Prism-x86_64 | grep -o 'arm64\|x86_64')"

# 3. Combiner avec lipo
echo "[3/3] Création du universal binary..."
lipo -create bin/Prism-arm64 bin/Prism-x86_64 -output bin/Prism
echo "      $(file bin/Prism | grep -o 'arm64\|x86_64' | tr '\n' '+' | sed 's/+$//')"
echo "      $(du -h bin/Prism | cut -f1)"

# Nettoyage
rm -f bin/Prism-arm64 bin/Prism-x86_64

echo ""
echo "Universal binary : bin/Prism"
echo "Lancez ./scripts/build-app.sh pour créer le .app et DMG"
