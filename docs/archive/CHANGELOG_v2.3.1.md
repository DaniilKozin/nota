# Nota v2.3.1 - AssemblyAI Only Release

## 🔧 Critical Fix: Removed Deepgram, Back to Working State

### What Changed

This release removes all Deepgram code and returns to the working v2.2 architecture with AssemblyAI as the primary and only streaming provider.

#### ❌ Removed
- **Deepgram Integration** - Completely removed all Deepgram code
- **Deepgram API Key Fields** - Removed from Settings UI
- **Deepgram Provider Option** - Removed from provider selection
- **Deepgram WebSocket** - Removed all WebSocket handling code
- **Deepgram Audio Streaming** - Removed audio streaming functions
- **Deepgram Message Handling** - Removed response parsing code

#### ✅ Restored
- **AssemblyAI as Primary** - Back to working v2.2 configuration
- **Simple Provider Chain** - AssemblyAI → Whisper (fallback only)
- **Stable Transcription** - Using proven AssemblyAI v3 API
- **Multilingual Support** - AssemblyAI handles 99 languages
- **Included API Key** - Default AssemblyAI key works out of the box

### Why This Change?

**Problem**: Version 2.3 introduced Deepgram as default provider, but:
- Deepgram was never actually used by users
- It added complexity without benefit
- Version 2.2 worked perfectly with AssemblyAI
- Users reported transcription stopped working in v2.3

**Solution**: Remove all Deepgram code and return to the proven v2.2 architecture that worked reliably.

### Provider Configuration

#### Before (v2.3.0)
```
Auto Mode: Deepgram (multilingual) → AssemblyAI → Whisper
Manual Options: AssemblyAI, Deepgram, Whisper
```

#### After (v2.3.1)
```
Auto Mode: AssemblyAI (multilingual) → Whisper
Manual Options: AssemblyAI, Whisper
```

### Technical Changes

#### Removed Files/Code
- `startDeepgramStreaming()` - 50+ lines
- `startAudioStreamingToDeepgram()` - 100+ lines
- `sendAudioChunkToDeepgram()` - 30+ lines
- `receiveDeepgramMessage()` - 40+ lines
- `handleDeepgramResponse()` - 80+ lines
- `startAVAudioRecorderRecording()` - 70+ lines (Deepgram-specific)
- Deepgram WebSocket variables and timers
- Deepgram UI fields in Settings

**Total Code Removed**: ~400 lines of unused Deepgram code

#### Simplified Code
- `startStreamingTranscription()` - Simplified provider selection
- `stopRecording()` - Removed Deepgram cleanup
- Settings UI - Removed Deepgram API key fields
- Provider picker - Only shows AssemblyAI and Whisper

### API Configuration

#### AssemblyAI (Primary)
```
URL: wss://streaming.assemblyai.com/v3/ws
Model: universal-streaming-multilingual
Languages: 99 languages with auto-detection
Latency: ~100-200ms
Cost: $0.27/hour (included key provided)
```

#### Whisper (Fallback)
```
URL: https://api.openai.com/v1/audio/transcriptions
Model: whisper-1
Languages: 50+ languages
Latency: ~5 seconds (chunked)
Cost: $0.36/hour
```

### Migration Guide

#### From v2.3.0 to v2.3.1
1. **No action required** - Auto mode now uses AssemblyAI
2. **Deepgram keys ignored** - If you had Deepgram key, it's no longer used
3. **AssemblyAI works** - Default included key works immediately
4. **Whisper fallback** - Only used if AssemblyAI fails

#### Settings Changes
- Deepgram API Key field removed
- Provider picker shows only: Auto, AssemblyAI, Whisper
- Auto mode = AssemblyAI with included key

### What Still Works

✅ **All v2.2 Features**
- 99 language support via AssemblyAI
- Multilingual meetings with auto language detection
- Real-time streaming transcription
- AI insights and summaries
- Recording history
- Audio device selection
- Menu bar integration

✅ **Performance**
- Same ~100-200ms latency as v2.2
- Stable WebSocket connection
- Reliable transcription
- No crashes or freezes

### Known Limitations

- Only AssemblyAI for streaming (Deepgram removed)
- Whisper only as fallback (not for real-time)
- Requires AssemblyAI API key (included by default)

### Testing

#### Tested Scenarios
- ✅ English transcription
- ✅ Russian transcription
- ✅ Mixed language meetings
- ✅ Settings UI (no crashes)
- ✅ Provider selection
- ✅ Recording start/stop
- ✅ Audio device selection

#### Test Results
- ✅ Transcription works immediately
- ✅ No Deepgram errors in logs
- ✅ AssemblyAI connects successfully
- ✅ Language detection works
- ✅ Settings UI clean and simple

### Upgrade Instructions

1. **Download** Nota-v2.3.1.dmg
2. **Install** - Drag to Applications (replace v2.3.0)
3. **Launch** - Right-click → Open (first time)
4. **Test** - Start recording, verify transcription works!

### Breaking Changes

**None!** This is a bug fix release that restores v2.2 functionality.

### What's Next (v2.4)

Now that we're back to stable v2.2 architecture, we can focus on:
- [ ] Fix audio capture for system audio (BlackHole)
- [ ] Add voice activity detection
- [ ] Add audio visualization
- [ ] Add real-time audio level monitoring
- [ ] Improve error messages
- [ ] Add global keyboard shortcuts

### Credits

- [AssemblyAI](https://www.assemblyai.com) - Universal-Streaming v3 API
- Community feedback on v2.3 issues

---

**Release Date**: January 16, 2026  
**Version**: 2.3.1  
**Build**: 231  
**License**: MIT

**Download**: [Nota-v2.3.1.dmg](releases/Nota-v2.3.1.dmg)

## Summary

**v2.3.1 = v2.2 (working) - Deepgram (unused)**

This release removes all Deepgram code that was added in v2.3 but never actually used. We're back to the proven v2.2 architecture with AssemblyAI as the primary provider. Transcription should work reliably again!
