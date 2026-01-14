#!/bin/bash

echo "🔍 Checking Nota Permissions..."
echo ""

# Check if Nota is running
if pgrep -x "Nota" > /dev/null; then
    echo "✅ Nota is running"
else
    echo "❌ Nota is not running"
fi

echo ""
echo "📋 Checking macOS Permissions..."
echo ""

# Check microphone permission
echo "🎤 Microphone Permission:"
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT service, client, auth_value FROM access WHERE service='kTCCServiceMicrophone' AND client LIKE '%nota%';" 2>/dev/null || echo "   Unable to check (requires Full Disk Access)"

# Check speech recognition permission  
echo ""
echo "🗣️  Speech Recognition Permission:"
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT service, client, auth_value FROM access WHERE service='kTCCServiceSpeechRecognition' AND client LIKE '%nota%';" 2>/dev/null || echo "   Unable to check (requires Full Disk Access)"

# Check accessibility permission
echo ""
echo "♿ Accessibility Permission:"
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT service, client, auth_value FROM access WHERE service='kTCCServiceAccessibility' AND client LIKE '%nota%';" 2>/dev/null || echo "   Unable to check (requires Full Disk Access)"

echo ""
echo "🎧 Current Audio Devices:"
system_profiler SPAudioDataType | grep -E "^        [A-Z]" | head -10

echo ""
echo "📊 Nota Process Info:"
ps aux | grep "[N]ota.app" | awk '{print "   PID: "$2", CPU: "$3"%, MEM: "$4"%"}'

echo ""
echo "💡 To grant permissions:"
echo "   1. Open System Settings"
echo "   2. Go to Privacy & Security"
echo "   3. Enable Microphone for Nota"
echo "   4. Enable Speech Recognition for Nota"
echo "   5. (Optional) Enable Accessibility for hotkeys"
