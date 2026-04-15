#!/bin/bash
# Build Prism.app macOS bundle avec icône, signature ad-hoc et DMG
set -e

cd "$(dirname "$0")/.."

APP_NAME="Prism"
BUNDLE_ID="org.aloli-crystal.prism"
APP_DIR="build/${APP_NAME}.app"
DMG_DIR="build/dmg"
DMG_FILE="build/${APP_NAME}.dmg"
VERSION="${1:-1.0.0}"

echo "=== Building ${APP_NAME} v${VERSION} ==="
echo ""

# --- 1. Compilation release ---
echo "[1/5] Compilation release..."
crystal build src/prism.cr -o bin/Prism --release --no-debug
echo "      Binaire : $(du -h bin/Prism | cut -f1)"

# --- 2. Structure .app ---
echo "[2/5] Création du bundle .app..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Binaire
cp bin/Prism "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Icône
if [ -f assets/AppIcon.icns ]; then
  cp assets/AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"
  echo "      Icône intégrée"
else
  echo "      ⚠ Pas d'icône .icns trouvée (assets/AppIcon.icns)"
fi

# Info.plist
cat > "${APP_DIR}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME} — AsciiDoc Editor</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
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
    <key>NSSupportsAutomaticGraphicsSwitching</key>
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
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>org.asciidoc.asciidoc</string>
            <key>UTTypeDescription</key>
            <string>AsciiDoc Document</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.plain-text</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>adoc</string>
                    <string>asciidoc</string>
                    <string>asc</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "      ${APP_DIR} créé"

# --- 3. Signature ad-hoc ---
echo "[3/5] Signature ad-hoc..."
codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null
echo "      Signé (ad-hoc)"

# --- 4. Vérification ---
echo "[4/5] Vérification..."
codesign --verify --verbose "${APP_DIR}" 2>&1 | head -3
echo "      App size : $(du -sh "${APP_DIR}" | cut -f1)"

# --- 5. Création du DMG ---
echo "[5/5] Création du DMG..."
rm -rf "${DMG_DIR}" "${DMG_FILE}"
mkdir -p "${DMG_DIR}"
cp -r "${APP_DIR}" "${DMG_DIR}/"

# Lien symbolique vers Applications
ln -s /Applications "${DMG_DIR}/Applications"

# Créer le DMG
hdiutil create -volname "${APP_NAME}" \
  -srcfolder "${DMG_DIR}" \
  -ov -format UDZO \
  "${DMG_FILE}" 2>/dev/null

rm -rf "${DMG_DIR}"
echo "      $(ls -lh "${DMG_FILE}" | awk '{print $5}') — ${DMG_FILE}"

echo ""
echo "=== Terminé ==="
echo ""
echo "Pour installer :"
echo "  1. Ouvrir ${DMG_FILE}"
echo "  2. Glisser Prism vers Applications"
echo ""
echo "Ou directement :"
echo "  cp -r ${APP_DIR} /Applications/"
echo ""
echo "Note : Au premier lancement, macOS peut afficher un avertissement"
echo "car l'app n'est pas notarisée. Pour passer outre :"
echo "  - Clic droit sur Prism > Ouvrir"
echo "  - Ou : xattr -cr /Applications/Prism.app"
