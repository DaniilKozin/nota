#!/bin/bash

echo "🔍 Diagnosing Transcription Issues"
echo "=================================="
echo ""

# Check if app is running
if pgrep -f "Nota.app" > /dev/null; then
    echo "✅ App is running (PID: $(pgrep -f 'Nota.app'))"
else
    echo "❌ App is not running"
    exit 1
fi

# Check AssemblyAI key
ASSEMBLYAI_KEY=$(defaults read com.daniilkozin.nota assemblyaiKey 2>/dev/null)
if [ -n "$ASSEMBLYAI_KEY" ]; then
    echo "✅ AssemblyAI key found: ${ASSEMBLYAI_KEY:0:8}..."
    if [ "$ASSEMBLYAI_KEY" = "bcacd502bfd640bd817306c3e35a3626" ]; then
        echo "   ✅ Using default included key"
    else
        echo "   ℹ️  Using custom key"
    fi
else
    echo "❌ AssemblyAI key NOT found in UserDefaults"
    echo "   This is the problem! The app needs to be restarted."
fi

# Check Deepgram key
DEEPGRAM_KEY=$(defaults read com.daniilkozin.nota deepgramKey 2>/dev/null)
if [ -n "$DEEPGRAM_KEY" ]; then
    echo "✅ Deepgram key found: ${DEEPGRAM_KEY:0:8}..."
else
    echo "⚠️  Deepgram key not configured (optional)"
fi

# Check OpenAI key
OPENAI_KEY=$(defaults read com.daniilkozin.nota openaiKey 2>/dev/null)
if [ -n "$OPENAI_KEY" ]; then
    echo "✅ OpenAI key found: ${OPENAI_KEY:0:8}..."
else
    echo "⚠️  OpenAI key not configured (needed for insights)"
fi

# Check provider
PROVIDER=$(defaults read com.daniilkozin.nota transcriptionProvider 2>/dev/null)
echo "✅ Transcription provider: ${PROVIDER:-auto}"

# Check language
LANGUAGE=$(defaults read com.daniilkozin.nota outputLanguage 2>/dev/null)
echo "✅ Output language: ${LANGUAGE:-auto}"

# Check microphone permission
echo ""
echo "🎤 Checking Microphone Permission..."
MIC_STATUS=$(sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT auth_value FROM access WHERE service='kTCCServiceMicrophone' AND client LIKE '%nota%';" 2>/dev/null | head -1)

if [ "$MIC_STATUS" = "2" ]; then
    echo "✅ Microphone permission: GRANTED"
elif [ "$MIC_STATUS" = "0" ]; then
    echo "❌ Microphone permission: DENIED"
    echo "   Fix: System Settings → Privacy & Security → Microphone → Enable Nota"
elif [ "$MIC_STATUS" = "1" ]; then
    echo "⚠️  Microphone permission: RESTRICTED"
else
    echo "⚠️  Microphone permission: NOT REQUESTED YET"
    echo "   The app will request permission when you start recording"
fi

echo ""
echo "📊 Diagnosis Summary:"
echo "===================="

# Determine the issue
if [ -z "$ASSEMBLYAI_KEY" ]; then
    echo "❌ ISSUE FOUND: AssemblyAI key not in UserDefaults"
    echo ""
    echo "🔧 SOLUTION:"
    echo "   The app was running when we added the default key."
    echo "   The @AppStorage default only applies on first launch."
    echo ""
    echo "   Option 1: Restart the app"
    echo "   1. Quit Nota (click menu bar icon → Quit)"
    echo "   2. Relaunch: open /Applications/Nota.app"
    echo ""
    echo "   Option 2: Manually set the key"
    echo "   1. Open Dashboard → Settings"
    echo "   2. AssemblyAI key field should show the default"
    echo "   3. Click in the field and press Enter to save"
    echo ""
elif [ "$MIC_STATUS" != "2" ]; then
    echo "❌ ISSUE FOUND: Microphone permission not granted"
    echo ""
    echo "🔧 SOLUTION:"
    echo "   1. Start recording in the app"
    echo "   2. Grant microphone permission when prompted"
    echo "   OR"
    echo "   1. System Settings → Privacy & Security → Microphone"
    echo "   2. Enable Nota"
else
    echo "✅ Configuration looks good!"
    echo ""
    echo "🔍 If transcription still doesn't work:"
    echo "   1. Check console logs: log stream --predicate 'process == \"Nota\"'"
    echo "   2. Try recording and watch for error messages"
    echo "   3. Check internet connection (needed for API calls)"
fi
