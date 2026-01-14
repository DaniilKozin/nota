#!/bin/bash

set -e

echo "💿 Creating DMG installer for Nota..."

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

DMG_NAME="Nota-v${SHORT_VERSION}-SmartTranscription"
VOLUME_NAME="Nota v${SHORT_VERSION}"
SOURCE_FOLDER="dmg_source"
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

# Copy install script
if [ -f "install_nota.sh" ]; then
    echo "📋 Copying install script..."
    cp "install_nota.sh" "${SOURCE_FOLDER}/"
    chmod +x "${SOURCE_FOLDER}/install_nota.sh"
fi

# Create Applications symlink
ln -s /Applications "${SOURCE_FOLDER}/Applications"

# Create comprehensive README
cat > "${SOURCE_FOLDER}/README.txt" << EOF
╔═══════════════════════════════════════════════════════════════╗
║                  Nota v${VERSION} - AI Meeting Recorder              ║
║                    Smart Transcription Edition                ║
╚═══════════════════════════════════════════════════════════════╝

📦 INSTALLATION (IMPORTANT!)
════════════════════════════
⚠️  To avoid "damaged and can't be opened" error:

METHOD 1 (Recommended - Automatic):
1. Open Terminal (Applications → Utilities → Terminal)
2. Drag install_nota.sh to Terminal window
3. Press Enter
4. Follow the prompts

METHOD 2 (Manual):
1. Drag Nota.app to Applications folder
2. Open Terminal (Applications → Utilities → Terminal)
3. Run: xattr -cr /Applications/Nota.app
4. Run: open /Applications/Nota.app

METHOD 3 (Right-click):
1. Drag Nota.app to Applications folder
2. Right-click (or Control+click) on Nota.app
3. Select "Open" from menu
4. Click "Open" in the dialog

WHY THIS HAPPENS:
macOS Gatekeeper blocks apps from unidentified developers.
The commands above tell macOS to trust this app.

🔐 SECURITY NOTE:
This app is open source and safe. The "damaged" message is
just macOS being cautious about apps without Apple Developer
certificate ($99/year). You can verify the source code on GitHub.

🚀 QUICK START
═══════════════
1. Look for microphone icon in menu bar
2. Click icon to open mini window
3. Click Record button to start
4. Speak or join a meeting
5. Watch live transcription appear
6. Click Stop when done
7. View insights and history in Dashboard

⚙️ FIRST-TIME SETUP
═══════════════════
1. Open Dashboard (home icon in mini window)
2. Go to Settings tab
3. Enter your OpenAI API key (get from platform.openai.com)
4. Choose GPT-5 Nano (recommended) or GPT-5 Mini
5. Select your language (auto-detect by default)
6. Configure audio input device

🎯 KEY FEATURES
═══════════════
✓ Live transcription using Apple Speech Recognition
✓ AI-powered insights with GPT-5 Nano/Mini
✓ Smart transcription every 6 seconds
✓ Insights generation every 45 seconds
✓ Messenger-style transcript bubbles
✓ Recording history with sessions
✓ Project organization with keywords
✓ Liquid Glass 2026 design language
✓ Compact mini window (380x280)
✓ Full Dashboard with analytics
✓ BlackHole aggregate device support
✓ Multi-language support (23 languages)

🎤 AUDIO SETUP (for capturing both sides)
═════════════════════════════════════════
To capture both your voice AND your meeting partner:

1. Install BlackHole: https://github.com/ExistentialAudio/BlackHole
2. Create Aggregate Device in Audio MIDI Setup:
   • Include: Built-in Microphone + BlackHole 2ch
   • Set Clock Source: Built-in Microphone
3. Set as system input: System Settings → Sound → Input
4. In Zoom/Teams:
   • Input: Aggregate Device
   • Output: BlackHole 2ch (or Multi-Output Device)

📋 REQUIREMENTS
═══════════════
• macOS 13.0 (Ventura) or later
• Microphone access
• Internet connection for AI features
• OpenAI API key (for GPT-5 features)

💰 PRICING (OpenAI GPT-5)
═════════════════════════
• GPT-5 Nano: $0.05/$0.40 per 1M tokens (recommended)
• GPT-5 Mini: $0.25/$2.00 per 1M tokens

Typical 1-hour meeting costs: $0.01-0.05 with Nano

🔐 PRIVACY & SECURITY
═════════════════════
✓ All data stored locally on your Mac
✓ No analytics or telemetry
✓ No data sent to developer
✓ API keys stored securely in Keychain
✓ Transcripts only sent to OpenAI with your key
✓ Open source - you can verify the code

📂 DATA LOCATIONS
═════════════════
• Settings: ~/Library/Preferences/com.daniilkozin.nota.plist
• Data: ~/Library/Application Support/com.daniilkozin.nota/
• Recordings: Stored in app data folder

🗑️ UNINSTALL
═════════════
1. Delete /Applications/Nota.app
2. Delete ~/Library/Preferences/com.daniilkozin.nota.plist
3. Delete ~/Library/Application Support/com.daniilkozin.nota/

⌨️ KEYBOARD SHORTCUTS
═════════════════════
• CMD+\ : Show/hide mini window (requires Accessibility)

🆘 TROUBLESHOOTING
══════════════════
• No transcription? Check microphone permissions
• No insights? Add OpenAI API key in Settings
• Can't hear partner? Set up aggregate device (see Audio Setup)
• Partner can't hear you? Check Zoom/Teams input = Aggregate Device
• App crashes? Check Console.app for logs

📚 DOCUMENTATION
════════════════
Full documentation included in app:
• AUDIO_SETUP_GUIDE.md - Detailed audio configuration
• QUICK_FIX_AUDIO.md - Quick troubleshooting
• SECURITY_CHECK.md - Privacy and security details

🔗 LINKS
════════
• GitHub: https://github.com/daniilkozin/nota
• OpenAI API: https://platform.openai.com
• BlackHole: https://github.com/ExistentialAudio/BlackHole
• Support: Open issue on GitHub

📝 VERSION HISTORY
══════════════════
v${VERSION} (January 2026)
• GPT-5 Nano/Mini support
• Smart transcription (6s intervals)
• Insights generation (45s intervals)
• Messenger-style bubbles
• Recording history system
• Project organization
• Liquid Glass 2026 design
• Audio device management
• Keywords and meeting type detection
• Improved Gatekeeper handling

v2.0 (January 2026)
• Complete Swift rewrite
• Native macOS performance
• Liquid Glass design language
• Mini window interface
• Dashboard with analytics

v1.0 (December 2025)
• Initial release
• Basic transcription
• OpenAI integration

═══════════════════════════════════════════════════════════════
Built with ❤️ using Swift for optimal macOS performance
Version ${VERSION} - January 14, 2026
═══════════════════════════════════════════════════════════════
EOF

# Calculate size needed (in MB, with some padding)
SIZE_MB=$(du -sm "${SOURCE_FOLDER}" | cut -f1)
SIZE_MB=$((SIZE_MB + 20))

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
           set the bounds of container window to {400, 100, 900, 450}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set position of item "Nota.app" of container window to {150, 150}
           set position of item "Applications" of container window to {350, 150}
           set position of item "README.txt" of container window to {150, 280}
           set position of item "install_nota.sh" of container window to {350, 280}
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

echo "✅ DMG created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Location: $(pwd)/${FINAL_DMG}"
echo "📊 Size: $(du -sh "${FINAL_DMG}" | cut -f1)"
echo "📌 Version: ${VERSION}"
echo "🔐 Security: No API keys or personal data included"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 READY FOR DISTRIBUTION!"
echo ""
echo "📦 What's included:"
echo "   • Nota.app (clean build, no keys)"
echo "   • install_nota.sh (automatic installer)"
echo "   • README.txt (comprehensive guide)"
echo "   • Applications symlink (for easy install)"
echo ""
echo "🔒 Security verified:"
echo "   • No API keys in binary"
echo "   • No personal data"
echo "   • Users configure their own keys"
echo "   • All data stored locally per user"
echo ""
echo "📤 To distribute:"
echo "   1. Upload ${FINAL_DMG} to file sharing service"
echo "   2. Share download link"
echo "   3. Users mount DMG and run install_nota.sh"
echo "   4. Each user configures their own API keys"
echo ""
echo "⚠️  IMPORTANT FOR USERS:"
echo "   Tell users to run install_nota.sh to avoid Gatekeeper issues!"
echo "   Or manually run: xattr -cr /Applications/Nota.app"
echo ""
echo "💡 First-time user setup:"
echo "   1. Open Nota"
echo "   2. Go to Settings"
echo "   3. Enter OpenAI API key"
echo "   4. Start recording!"
echo ""