# Nota v2.4.0 - Complete Release

## 🎉 Major Features

### 1. ✅ Speaker Diarization (Post-Meeting)
**Who said what?** - Now you can identify different speakers after the meeting!

- Uses OpenAI's `gpt-4o-transcribe-diarize` model
- Automatically identifies speakers (Speaker A, Speaker B, etc.)
- Runs after meeting ends
- Updates transcript with speaker labels
- Works for ALL languages

**Example Output:**
```
**Speaker A**: Hello everyone, let's start the meeting.

**Speaker B**: Thanks for joining. I have some updates to share.

**Speaker A**: Great, please go ahead.
```

### 2. ✅ Live Insights During Meeting
**Real-time meeting analysis** - See insights while recording!

- Insights appear every 30 seconds (was 45s)
- Lower threshold: 50 characters (was 120)
- Faster updates during meeting
- Key points, action items, topics discussed
- All in your system language

### 3. ✅ Smart Language Detection
**Automatic provider selection** - App chooses best provider for your language!

**AssemblyAI Streaming** (Real-time, ~200ms):
- English, Spanish, French, German, Italian, Portuguese

**Whisper** (Batch, ~5s chunks):
- Russian, Chinese, Japanese, Korean, and 40+ more languages
- Auto-detects language
- Handles mixed languages (English + Russian)

### 4. ✅ Mixed Language Support
**English + Russian in same meeting?** - No problem!

- Whisper auto-detects language per chunk
- No need to specify language
- Handles code-switching
- Works with any language combination

## What's New

### Speaker Diarization
```swift
// After meeting ends:
1. Upload audio to OpenAI
2. Use gpt-4o-transcribe-diarize model
3. Get transcript with speaker labels
4. Update UI with "Speaker A:", "Speaker B:", etc.
```

**Features:**
- ✅ Automatic speaker identification
- ✅ Works for all languages
- ✅ Post-meeting processing (not real-time)
- ✅ Clean speaker-labeled transcript
- ❌ Doesn't identify speaker names (just A, B, C...)

### Live Insights Improvements
```swift
// Before:
insightsInterval = 45 seconds
minTranscriptLength = 120 characters

// After:
insightsInterval = 30 seconds
minTranscriptLength = 50 characters
```

**Result:** Insights appear faster and more frequently!

### Language Detection
```swift
// Auto mode logic:
if language in [en, es, fr, de, it, pt]:
    use AssemblyAI Streaming (fast, real-time)
else:
    use Whisper (good, 5s chunks)
```

**Supported by AssemblyAI Streaming:**
- 🇬🇧 English
- 🇪🇸 Spanish
- 🇫🇷 French
- 🇩🇪 German
- 🇮🇹 Italian
- 🇵🇹 Portuguese

**Supported by Whisper:**
- 🇷🇺 Russian
- 🇨🇳 Chinese
- 🇯🇵 Japanese
- 🇰🇷 Korean
- And 40+ more languages

### Mixed Language Support
```swift
// Whisper now auto-detects language
// No language parameter = supports mixed languages
// Example: English + Russian in same meeting
```

## Technical Changes

### 1. Speaker Diarization Implementation
```swift
private func generateSpeakerDiarization(audioURL: URL) {
    // Upload audio to OpenAI
    // Use gpt-4o-transcribe-diarize model
    // Get diarized_json response
    // Parse segments with speaker labels
    // Update transcript with speaker tags
}
```

### 2. Insights Configuration
```swift
// Faster insights
private let insightsInterval: TimeInterval = 30.0  // was 45.0
private let minTranscriptLengthForInsights = 50    // was 120
```

### 3. Language Detection
```swift
private func startStreamingTranscription() {
    let assemblyAISupportedLanguages = ["en", "es", "fr", "de", "it", "pt"]
    let languagePrefix = String(language.prefix(2))
    let isAssemblyAISupported = assemblyAISupportedLanguages.contains(languagePrefix)
    
    if isAssemblyAISupported {
        startAssemblyAIStreaming()  // Real-time
    } else {
        startWhisperChunkedTranscription()  // Batch
    }
}
```

### 4. Whisper Mixed Language
```swift
// BEFORE: Specified language
body.append("name=\"language\"\r\n\r\n")
body.append("\(language)\r\n")

// AFTER: Auto-detect (supports mixed languages)
// No language parameter = Whisper auto-detects
```

## Use Cases

### Use Case 1: English Meeting with Multiple Speakers
```
Provider: AssemblyAI Streaming
Latency: ~200ms (real-time)
Speaker Diarization: After meeting
Result: Fast transcription + speaker labels
```

### Use Case 2: Russian Meeting
```
Provider: Whisper
Latency: ~5 seconds per chunk
Speaker Diarization: After meeting
Result: Good transcription + speaker labels
```

### Use Case 3: Mixed English + Russian
```
Provider: Whisper (auto-detect)
Latency: ~5 seconds per chunk
Language Detection: Automatic per chunk
Speaker Diarization: After meeting
Result: Both languages transcribed + speaker labels
```

### Use Case 4: Live Insights During Meeting
```
Insights appear every 30 seconds
Shows: Key points, action items, topics
Updates in real-time
All in your system language
```

## API Costs

### AssemblyAI Streaming
- **Cost**: $0.27/hour
- **Included**: Default API key
- **Languages**: 6 (en, es, fr, de, it, pt)
- **Latency**: ~200ms

### Whisper Transcription
- **Cost**: $0.36/hour
- **Required**: Your OpenAI API key
- **Languages**: 50+
- **Latency**: ~5 seconds

### Speaker Diarization
- **Cost**: ~$0.50/hour (gpt-4o-transcribe-diarize)
- **Required**: Your OpenAI API key
- **Languages**: All
- **When**: After meeting ends

### Live Insights
- **Cost**: ~$0.01-0.05 per meeting (gpt-5-nano)
- **Required**: Your OpenAI API key
- **Frequency**: Every 30 seconds
- **Language**: Your system language

## Migration Guide

### From v2.3.x to v2.4.0

**No action required!** Everything works automatically:

1. **English meetings**: AssemblyAI Streaming (fast)
2. **Russian meetings**: Whisper (good)
3. **Mixed meetings**: Whisper (auto-detect)
4. **Speaker labels**: Automatic after meeting
5. **Live insights**: Appear every 30 seconds

### Settings

**No changes needed:**
- Auto mode works for all languages
- Speaker diarization runs automatically
- Insights generate automatically

**Optional:**
- Add OpenAI key for speaker diarization
- Add OpenAI key for live insights

## Known Limitations

### Speaker Diarization
- ❌ Not real-time (runs after meeting)
- ❌ Doesn't identify speaker names (just A, B, C...)
- ❌ Requires OpenAI API key
- ✅ Works for all languages
- ✅ Automatic after meeting

### Mixed Languages
- ⚠️ Whisper processes in 5-second chunks
- ⚠️ Rapid language switching may reduce accuracy
- ✅ Works well for typical mixed meetings
- ✅ Auto-detects language per chunk

### Live Insights
- ⚠️ Requires 50+ characters to start
- ⚠️ Updates every 30 seconds (not instant)
- ✅ Works during recording
- ✅ Translated to your system language

## Testing

### Test 1: English Meeting with Speakers
```
1. Start recording
2. Have 2+ people speak
3. Stop recording
4. Wait for speaker diarization
5. See transcript with "Speaker A:", "Speaker B:"
```

### Test 2: Russian Meeting
```
1. Settings → Language → Russian (or Auto)
2. Start recording
3. Speak Russian
4. See transcription every 5 seconds
5. After meeting: speaker labels added
```

### Test 3: Mixed English + Russian
```
1. Settings → Language → Auto
2. Start recording
3. Speak English, then Russian, then English
4. See both languages transcribed
5. After meeting: speaker labels added
```

### Test 4: Live Insights
```
1. Start recording
2. Speak for 1 minute
3. See insights appear in UI
4. Insights update every 30 seconds
5. Shows key points, action items, topics
```

## Troubleshooting

### Problem: No speaker labels

**Cause**: No OpenAI key or diarization failed

**Solution**:
- Add OpenAI API key in Settings
- Check Console.app for errors
- Ensure audio file exists

### Problem: Insights don't appear

**Cause**: Not enough content or no OpenAI key

**Solution**:
- Speak for at least 1 minute
- Add OpenAI API key in Settings
- Check Console.app for "🧠 Generating insights"

### Problem: Russian doesn't work

**Cause**: AssemblyAI doesn't support Russian

**Solution**:
- This is expected behavior
- Nota automatically uses Whisper
- You'll see transcription in 5-second chunks
- Check logs: "⚠️ Language ru NOT supported by AssemblyAI streaming, using Whisper"

### Problem: Mixed languages don't work well

**Cause**: Rapid language switching in same sentence

**Solution**:
- Whisper works best with language per chunk
- If mostly English: Set language to English
- If mostly Russian: Set language to Russian
- Or use Auto mode (recommended)

## What's Next (v2.5)

- [ ] Speaker name identification (not just A, B, C)
- [ ] Real-time speaker diarization (if API supports)
- [ ] Custom vocabulary per language
- [ ] Better mixed-language handling
- [ ] Audio visualization
- [ ] Voice activity detection

## Credits

- [OpenAI](https://openai.com) - gpt-4o-transcribe-diarize, Whisper
- [AssemblyAI](https://www.assemblyai.com) - Universal-Streaming
- Community feedback on speaker diarization

---

**Release Date**: January 16, 2026  
**Version**: 2.4.0  
**Build**: 240  
**License**: MIT

**Download**: [Nota-v2.4.0-complete.dmg](Nota-Swift/Nota-v2.4.0-complete.dmg)

## Summary

**v2.4.0 = v2.3.1 + Speaker Diarization + Live Insights + Smart Language Detection**

This release adds the most requested feature - speaker diarization! Now you can see who said what in your meetings. Plus faster live insights and smart language detection for Russian and other languages.

**Key Features:**
- 🎭 Speaker diarization (post-meeting)
- 🧠 Live insights (every 30s)
- 🌍 Smart language detection (auto-selects best provider)
- 🔄 Mixed language support (English + Russian)
- ✅ Works for ALL languages


## 🔧 Technical Improvements (v2.4.0 Update)

### Context Preservation for Whisper
**Problem**: Context lost between 5-second audio chunks  
**Solution**: Added `prompt` parameter with last 200 chars of transcript  
**Benefit**: Maintains conversation flow, improves accuracy  
**Works**: Across language switches in mixed-language meetings

**Technical Details:**
```swift
// Before: No context between chunks
transcribeWithWhisper(audioURL)

// After: Context preserved
if !transcriptBuffer.isEmpty {
    let contextPrompt = String(transcriptBuffer.suffix(200))
    // Send as prompt parameter to Whisper API
}
```

### Enhanced Logging & Debugging
- Audio file size logging
- HTTP response status codes
- Raw API responses for debugging
- Detailed error messages
- Character count tracking
- Language detection logging

**Example logs:**
```
📤 Sending audio to Whisper API...
📊 Audio file size: 123456 bytes
🔗 Using context prompt: [previous text]...
📡 Whisper API response status: 200
🌍 Whisper detected language: ru
✅ Whisper transcription (45 chars): Привет, как дела?...
📝 Total buffer size: 45 chars
```

## 📚 New Documentation

- `TEST_RUSSIAN_WHISPER.md` - Testing guide for Russian transcription
- Updated `LANGUAGE_SUPPORT.md` - Added context preservation details

## 🐛 Bug Fixes (v2.4.0 Update)

- **Context lost between chunks** → Added prompt parameter to Whisper API
- **Insufficient debugging info** → Added comprehensive logging
- **Mixed language accuracy** → Context preservation improves consistency

## 🎯 Testing Russian Transcription

See `TEST_RUSSIAN_WHISPER.md` for detailed testing instructions.

**Quick test:**
1. Install new version: `./install_nota.sh`
2. Set language to Russian (or Auto)
3. Set provider to Whisper
4. Start recording and speak in Russian
5. Check Console.app for logs (filter for "Nota")

**Expected behavior:**
- Transcription appears within 5-10 seconds
- Context is preserved between chunks
- Mixed languages work (English + Russian)
- No errors in Console.app
