#!/bin/bash

set -e

echo "📦 Creating Nota.app bundle..."

# Read version from VERSION file
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
    echo "📌 Version: $VERSION"
else
    VERSION="2.1.0"
    echo "⚠️  VERSION file not found, using default: $VERSION"
fi

# Extract version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
BUILD_NUMBER="${MAJOR}${MINOR}${PATCH}"

# Create app bundle structure
APP_NAME="Nota"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Clean previous build
rm -rf "${APP_BUNDLE}"

# Create directories
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
cp ".build/release/Nota" "${MACOS_DIR}/"

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Nota</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.daniilkozin.nota</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Nota</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Nota needs microphone access to record and transcribe meetings.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Nota uses speech recognition to provide live transcription of your meetings.</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Nota needs access to system events to register global hotkeys for quick access.</string>
</dict>
</plist>
EOF

# Add app icon and tray icon
echo "Adding app icons..."
if [ -f "icons/AppIcon.icns" ]; then
    cp "icons/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    echo "✅ Added new AppIcon.icns"
elif [ -f "icons/icon.icns" ]; then
    cp "icons/icon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    echo "✅ Added icon.icns"
else
    echo "⚠️  No app icon.icns found"
fi

# Copy all tray icon variants for proper display
if [ -f "icons/tray-18x18.png" ]; then
    cp "icons/tray-18x18.png" "${RESOURCES_DIR}/tray-18x18.png"
    echo "✅ Added tray-18x18.png"
fi

if [ -f "icons/tray-22x22.png" ]; then
    cp "icons/tray-22x22.png" "${RESOURCES_DIR}/tray-22x22.png"
    echo "✅ Added tray-22x22.png"
fi

if [ -f "icons/tray-36x36.png" ]; then
    cp "icons/tray-36x36.png" "${RESOURCES_DIR}/tray-36x36.png"
    echo "✅ Added tray-36x36.png (Retina)"
fi

if [ -f "icons/tray-icon.png" ]; then
    cp "icons/tray-icon.png" "${RESOURCES_DIR}/tray-icon.png"
    echo "✅ Added tray-icon.png (fallback)"
fi

# Create PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Set executable permissions
chmod +x "${MACOS_DIR}/Nota"

# Create entitlements file for signing
cat > "${CONTENTS_DIR}/entitlements.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
EOF

# Sign the app with ad-hoc signature (allows running without developer certificate)
echo ""
echo "🔐 Signing application..."
if command -v codesign &> /dev/null; then
    # Remove extended attributes that might cause issues
    xattr -cr "${APP_BUNDLE}"
    
    # Sign with ad-hoc signature
    codesign --force --deep --sign - "${APP_BUNDLE}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Application signed successfully (ad-hoc)"
        
        # Verify signature
        codesign --verify --verbose "${APP_BUNDLE}"
        if [ $? -eq 0 ]; then
            echo "✅ Signature verified"
        else
            echo "⚠️  Signature verification failed (but app should still work)"
        fi
    else
        echo "⚠️  Signing failed (app may show Gatekeeper warning)"
    fi
else
    echo "⚠️  codesign not found - app will show Gatekeeper warning"
fi

echo "✅ Nota.app created successfully!"
echo "📍 Location: $(pwd)/${APP_BUNDLE}"
echo "📌 Version: ${VERSION} (build ${BUILD_NUMBER})"
echo ""
echo "🚀 To install:"
echo "   1. Copy ${APP_BUNDLE} to /Applications/"
echo "   2. Run: open /Applications/${APP_BUNDLE}"
echo ""
echo "⚠️  FIRST TIME INSTALLATION:"
echo "   If you see 'damaged and can't be opened' error:"
echo "   1. Open Terminal"
echo "   2. Run: xattr -cr /Applications/${APP_BUNDLE}"
echo "   3. Run: open /Applications/${APP_BUNDLE}"
echo ""
echo "   Or use the install script: ./install_nota.sh"
echo ""
echo "📋 App info:"
echo "   - Size: $(du -sh "${APP_BUNDLE}" | cut -f1)"
echo "   - Bundle ID: com.daniilkozin.nota"
echo "   - Version: ${VERSION}"
echo "   - Min macOS: 13.0 (Ventura)"
echo "   - Signed: Ad-hoc (for local use)"
echo ""
echo "🎉 Ready for distribution!"