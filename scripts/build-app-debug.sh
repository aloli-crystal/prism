#!/bin/bash
# Build rapide sans --release pour tester le packaging
set -e
cd "$(dirname "$0")/.."

APP_NAME="Prism"
APP_DIR="build/${APP_NAME}.app"
DMG_FILE="build/${APP_NAME}.dmg"

echo "Build debug (rapide)..."
crystal build src/prism.cr -o bin/Prism

rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp bin/Prism "${APP_DIR}/Contents/MacOS/${APP_NAME}"
[ -f assets/AppIcon.icns ] && cp assets/AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"

# Copier le Info.plist du script principal (simplifié)
cat > "${APP_DIR}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>org.aloli-crystal.prism</string>
    <key>CFBundleVersion</key><string>1.0.0-dev</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null

# DMG
rm -rf build/dmg "${DMG_FILE}"
mkdir -p build/dmg
cp -r "${APP_DIR}" build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -volname "${APP_NAME}" -srcfolder build/dmg -ov -format UDZO "${DMG_FILE}" 2>/dev/null
rm -rf build/dmg

echo ""
echo "App : ${APP_DIR} ($(du -sh "${APP_DIR}" | cut -f1))"
echo "DMG : ${DMG_FILE} ($(ls -lh "${DMG_FILE}" | awk '{print $5}'))"
echo ""
echo "Test : open ${APP_DIR}"
