#!/bin/bash
# Build Prism.app macOS bundle
set -e

APP_NAME="Prism"
APP_DIR="build/${APP_NAME}.app"
VERSION="${1:-1.0.0}"

echo "Building ${APP_NAME} v${VERSION}..."

# Compile en release
crystal build src/prism.cr -o bin/prism --release --no-debug

# Créer la structure .app
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Copier le binaire
cp bin/prism "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Info.plist
cat > "${APP_DIR}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>org.aloli-crystal.prism</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>AsciiDoc Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.plain-text</string>
            </array>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>adoc</string>
                <string>asciidoc</string>
                <string>asc</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "Built: ${APP_DIR}"
echo "Binary size: $(du -h "${APP_DIR}/Contents/MacOS/${APP_NAME}" | cut -f1)"
echo ""
echo "To install: cp -r ${APP_DIR} /Applications/"
