# Nota v2.4.0 - Release Notes

## 🎉 What's New

### 1. 🧠 Smart Speaker Identification (FREE!)
**Context-based speaker detection** - No expensive API calls!

Instead of using expensive `gpt-4o-transcribe-diarize` ($0.50/hour), we now use smart GPT analysis to identify speakers from context:

- **Detects names**: "Hi, I'm Alex" → **Alex**
- **Detects roles**: "As the project manager..." → **Project Manager**
- **Infers from context**: Analyzes conversation to identify speakers
- **Falls back gracefully**: Uses Speaker A, Speaker B if no context
- **Cost**: ~$0.01-0.05 per meeting (same as insights)

**Example Output:**
```
💬 Conversation:
**Alex (Engineering)**: We need to fix the login bug.
**Project Manager**: Agreed. Can we do it by Friday?
**Alex (Engineering)**: Yes, I'll have it done by EOD Thursday.
```

### 2. 🧠 Live Insights (Fixed!)
**Real-time meeting analysis** - Now actually works!

- Appears every **30 seconds** (was 45s)
- Lower threshold: **50 characters** (was 120)
- Shows: Summary, Action Items, Key Insights, Topics
- All in your system language

### 3. 🌍 Smart Language Detection
**Automatic provider selection** - Works for all languages!

- **English/Spanish/French/German/Italian/Portuguese** → AssemblyAI (fast, ~200ms)
- **Russian/Chinese/Japanese/Korean/etc** → Whisper (good, ~5s)
- **Auto-detects** system language
- **Logs show** which provider is used

### 4. 🔄 Mixed Language Support
**English + Russian in same meeting** - Works perfectly!

- Whisper auto-detects language per chunk
- No need to specify language
- Handles code-switching
- Works with any language combination

### 5. 🎧 Audio Devices (Fixed!)
**Input devices now load automatically**

- Devices discovered on app launch
- Shows all available input devices
- Includes BlackHole, USB mics, etc.
- Refresh button to reload devices

## Technical Details

### Smart Speaker Identification

Instead of expensive audio-based diarization, we use GPT to analyze the transcript and identify speakers from context:

```swift
// Prompt includes:
- Try to identify speakers from context (names, roles, topics)
- If someone says "I'm John" → use their name
- If you can infer roles (Manager, Developer) → use those
- If no context → use Speaker A, Speaker B
```

**Cost Comparison:**
- Old way (gpt-4o-transcribe-diarize): $0.50/hour
- New way (GPT analysis): $0.01-0.05/meeting
- **Savings: 90-95%!**

### Language Detection

```swift
// Auto mode logic:
1. Check system language
2. If en/es/fr/de/it/pt → AssemblyAI Streaming
3. Else → Whisper
4. Log which provider is used
```

### Audio Devices

```swift
// On init:
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.discoverAudioDevices()
}
```

## How to Test

### Test 1: Smart Speaker Identification
```
1. Start recording
2. Say: "Hi, I'm Alex from engineering"
3. Have someone else say: "This is Maria, the project manager"
4. Stop recording
5. Check insights - should show:
   **Alex (Engineering)**: ...
   **Maria (Project Manager)**: ...
```

### Test 2: Russian Language
```
1. System language: Russian (or Settings → Language → Russian)
2. Start recording
3. Speak Russian
4. Check Console.app logs:
   🌍 System language detected: ru
   🇷🇺 Using Russian (ru-RU)
   ⚠️ Language ru-RU NOT supported by AssemblyAI streaming, using Whisper
5. Transcription appears every 5 seconds
```

### Test 3: Audio Devices
```
1. Open Settings
2. Check Audio & Language section
3. Input Device dropdown should show:
   - Default
   - USB Condenser Microphone
   - BlackHole 2ch
   - Aggregate Device
   - etc.
```

### Test 4: Live Insights
```
1. Start recording
2. Speak for 1 minute
3. After 30 seconds, insights should appear
4. Check for: Summary, Action Items, Key Insights
```

## Cost Breakdown

### For 1-hour meeting:

**Transcription:**
- English: FREE (AssemblyAI included key)
- Russian: $0.36 (Whisper)

**Live Insights:**
- $0.01-0.05 (gpt-5-nano, every 30s)

**Smart Speaker Identification:**
- $0.01-0.05 (included in final insights)

**Total: $0.01-0.41 per hour**

Compare to old way with audio diarization: $0.51-0.91 per hour
**Savings: 50-90%!**

## What's Fixed

1. ✅ **Input devices** - Now load automatically on app launch
2. ✅ **Russian language** - Auto-detects and uses Whisper
3. ✅ **Live insights** - Lower threshold (50 chars) and faster updates (30s)
4. ✅ **Speaker identification** - Smart context-based detection (FREE!)
5. ✅ **Mixed languages** - Whisper auto-detects language per chunk

## Known Limitations

- Speaker identification depends on context (names/roles mentioned)
- If no context, falls back to Speaker A, Speaker B
- Whisper has 5-second delay (not real-time like AssemblyAI)
- Mixed languages work best if not switching too rapidly

## Troubleshooting

### Problem: No input devices shown

**Solution:**
- Wait 1-2 seconds after opening Settings
- Click "Refresh Devices" button
- Check Console.app for device discovery logs

### Problem: Russian not detected

**Solution:**
- Check System Settings → Language & Region
- Or manually select Russian in Nota Settings
- Check Console.app logs for:
  ```
  🌍 System language detected: ru
  🇷🇺 Using Russian (ru-RU)
  ```

### Problem: No speaker names in insights

**Cause:** No names/roles mentioned in conversation

**Solution:**
- Introduce yourself: "Hi, I'm [Name]"
- Mention roles: "As the [Role], I think..."
- Or accept Speaker A, Speaker B labels

### Problem: Insights don't appear

**Cause:** Not enough content (need 50+ characters)

**Solution:**
- Speak for at least 30 seconds
- Check Console.app for "🧠 Generating insights"
- Ensure OpenAI API key is configured

## Files

- `Nota-v2.4.0.dmg` - Main installer
- `CHANGELOG_v2.4.0.md` - Full changelog
- `LANGUAGE_SUPPORT.md` - Language documentation

## Installation

```bash
1. Download Nota-v2.4.0.dmg
2. Open DMG
3. Drag Nota.app to Applications
4. Right-click → Open (first time only)
5. Configure OpenAI API key in Settings
6. Start recording!
```

## What's Next (v2.5)

- [ ] Real-time audio visualization
- [ ] Voice activity detection
- [ ] Better BlackHole integration
- [ ] Custom vocabulary per language
- [ ] Export transcripts with speaker labels

---

**Version**: 2.4.0  
**Build**: 240  
**Release Date**: January 16, 2026  
**License**: MIT

**Download**: [Nota-v2.4.0.dmg](Nota-v2.4.0.dmg)
