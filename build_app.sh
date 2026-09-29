#!/bin/bash
# Compile Leezi et génère Leezi.app dans le dossier courant.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="Leezi.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/Leezi "$APP/Contents/MacOS/Leezi"
cp Resources/Leezi.icns "$APP/Contents/Resources/Leezi.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Leezi</string>
    <key>CFBundleDisplayName</key>
    <string>Leezi</string>
    <key>CFBundleIdentifier</key>
    <string>com.ngoujon.leezi</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Leezi</string>
    <key>CFBundleIconFile</key>
    <string>Leezi.icns</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Leezi.app généré. Lance-le avec : open Leezi.app"
