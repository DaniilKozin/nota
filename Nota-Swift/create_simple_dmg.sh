#!/bin/bash

set -e

echo "💿 Creating simple DMG with Nota.app only..."

# Read version from VERSION file
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
    echo "📌 Version: $VERSION"
else
    VERSION="2.1.0"
    echo "⚠️  VERSION file not found, using default: $VERSION"
fi

# Extract short version (e.g., 2.1 from 2.1.0)
SHORT_VERSION=$(echo $VERSION | cut -d. -f1,2)

DMG_NAME="Nota-v${SHORT_VERSION}"
VOLUME_NAME="Nota v${SHORT_VERSION}"
SOURCE_FOLDER="dmg_simple"
FINAL_DMG="${DMG_NAME}.dmg"

# Clean previous builds
rm -rf "${SOURCE_FOLDER}"
rm -f "${FINAL_DMG}"

# Create source folder
mkdir -p "${SOURCE_FOLDER}"

# Copy app to source folder
if [ ! -d "Nota.app" ]; then
    echo "❌ Nota.app not found! Run ./create_app_bundle.sh first"
    exit 1
fi

echo "📦 Copying Nota.app..."
cp -R "Nota.app" "${SOURCE_FOLDER}/"

# Create Applications symlink
ln -s /Applications "${SOURCE_FOLDER}/Applications"

# Calculate size needed (in MB, with some padding)
SIZE_MB=$(du -sm "${SOURCE_FOLDER}" | cut -f1)
SIZE_MB=$((SIZE_MB + 10))

echo "📏 DMG size: ${SIZE_MB}MB"

# Create DMG
hdiutil create -srcfolder "${SOURCE_FOLDER}" \
               -volname "${VOLUME_NAME}" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               -size ${SIZE_MB}m \
               temp.dmg

# Mount the DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "temp.dmg" | egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_POINT="/Volumes/${VOLUME_NAME}"

echo "📁 Mounted at: ${MOUNT_POINT}"

# Set DMG window properties with AppleScript
echo '
   tell application "Finder"
     tell disk "'${VOLUME_NAME}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 900, 400}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 96
           set position of item "Nota.app" of container window to {150, 150}
           set position of item "Applications" of container window to {350, 150}
           close
           open
           update without registering applications
           delay 5
     end tell
   end tell
' | osascript

# Unmount
hdiutil detach "${DEVICE}"

# Convert to compressed DMG
hdiutil convert "temp.dmg" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"

# Clean up
rm -f temp.dmg
rm -rf "${SOURCE_FOLDER}"

echo ""
echo "✅ DMG created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Location: $(pwd)/${FINAL_DMG}"
echo "📊 Size: $(du -sh "${FINAL_DMG}" | cut -f1)"
echo "📌 Version: ${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 READY FOR DISTRIBUTION!"
echo ""
echo "📦 What's included:"
echo "   • Nota.app (signed with ad-hoc signature)"
echo "   • Applications symlink (drag & drop install)"
echo ""
echo "⚠️  IMPORTANT FOR USERS:"
echo "   After installing, run: xattr -cr /Applications/Nota.app"
echo "   Or right-click Nota.app → Open (first time only)"
echo ""
echo "📤 To distribute:"
echo "   1. Upload ${FINAL_DMG} to GitHub Release"
echo "   2. Users download and drag to Applications"
echo "   3. Users run: xattr -cr /Applications/Nota.app"
echo ""
