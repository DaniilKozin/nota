#!/bin/bash

echo "🔍 Monitoring Nota Application"
echo "=============================="
echo ""
echo "✅ App should be running now"
echo ""
echo "📋 Instructions:"
echo "  1. Click the microphone icon in the menu bar"
echo "  2. The mini window should appear"
echo "  3. Click the record button"
echo "  4. Watch the logs below"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔴 LIVE LOGS (Press Ctrl+C to stop):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Monitor all Nota logs with timestamps
log stream --predicate 'process == "Nota"' --level debug --style compact 2>&1 | \
  while IFS= read -r line; do
    # Add timestamp and filter for relevant messages
    if echo "$line" | grep -qE "(DEBUG|toggleMiniWindow|showWindow|Record button|Starting|Stopping|Recording|🔴|🎤|⏹️|✅|❌|⚠️)"; then
      echo "[$(date '+%H:%M:%S')] $line"
    fi
  done
