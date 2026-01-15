#!/bin/bash

echo "🔍 Monitoring Nota Multilingual Transcription"
echo "=============================================="
echo ""
echo "App Status: $(pgrep -f 'Nota.app' > /dev/null && echo '✅ Running' || echo '❌ Not Running')"
echo "PID: $(pgrep -f 'Nota.app')"
echo ""
echo "📊 Configuration:"
echo "  - AssemblyAI Key: $(defaults read com.daniilkozin.nota assemblyaiKey 2>/dev/null | cut -c1-8)..."
echo "  - Provider: $(defaults read com.daniilkozin.nota transcriptionProvider 2>/dev/null || echo 'auto')"
echo "  - Language: $(defaults read com.daniilkozin.nota outputLanguage 2>/dev/null || echo 'auto')"
echo ""
echo "🎤 Instructions:"
echo "  1. Click the microphone icon in menu bar"
echo "  2. Click 'Start Recording'"
echo "  3. Speak in English, then Russian, then mix them"
echo "  4. Watch the logs below for language detection"
echo ""
echo "📝 Expected Logs:"
echo "  - 🎙️ Starting AssemblyAI WebSocket streaming..."
echo "  - 🌍 Using multilingual model with auto language detection"
echo "  - ✅ AssemblyAI session started: <session-id>"
echo "  - 🌍 Detected language: en (confidence: XX%)"
echo "  - 🌍 Detected language: ru (confidence: XX%)"
echo "  - 📝 AssemblyAI interim: <text>"
echo "  - ✅ AssemblyAI final: <text>"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔴 LIVE LOGS (Press Ctrl+C to stop):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Stream logs with filtering for relevant messages
log stream --predicate 'process == "Nota"' --level debug --style compact 2>/dev/null | \
  grep --line-buffered -E "(🎙️|🌍|✅|📝|❌|🎤|⚠️|Starting|Detected|AssemblyAI|Deepgram|Recording|language|transcript)" | \
  while IFS= read -r line; do
    # Add timestamp
    echo "[$(date '+%H:%M:%S')] $line"
  done
