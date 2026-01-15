# Nota v2.3.0 - Multilingual Meetings Release

## 🎉 Major Update: True Multilingual Support!

### What's New

#### 🌍 Real Multilingual Meeting Support
- **Automatic Language Detection**: Detects and transcribes multiple languages in real-time
- **Language Switching**: Seamlessly handles mid-conversation language changes
- **99 Languages Supported**: English, Russian, Portuguese, Korean, Spanish, and 94 more
- **Smart Provider Selection**: Deepgram for multilingual, AssemblyAI for English-only

#### 🔧 Fixed Issues
- ✅ **Settings Crash**: Fixed crash when opening Settings during recording
- ✅ **Russian Transcription**: Now works correctly with multilingual model
- ✅ **Mixed Languages**: Properly transcribes conversations with multiple languages
- ✅ **Language Detection**: Shows detected language in console logs

#### 🚀 Technical Improvements
- **Deepgram Auto-Detection**: Uses `language=multi` with `detect_language=true`
- **AssemblyAI v3 API**: Updated to latest streaming endpoint
- **Better Provider Logic**: Deepgram default for multilingual, AssemblyAI fallback
- **Language Logging**: Console shows detected language per utterance

### Use Cases

#### International Teams
```
Speaker 1 (EN): "Let's discuss the Q4 roadmap"
Speaker 2 (RU): "Мы должны сосредоточиться на производительности"
Speaker 3 (PT): "Podemos terminar até sexta-feira"
```
**Result**: All three languages transcribed correctly!

#### Code-Switching
```
"Let's start the meeting. Мы обсудим три вопроса. First is the budget."
```
**Result**: Seamless transcription of mixed English/Russian

### Configuration Changes

#### Default Provider
- **v2.2**: AssemblyAI (English-only in practice)
- **v2.3**: Deepgram (true multilingual support)

#### Provider Priority
1. **Auto Mode**: Deepgram (multilingual)
2. **Manual**: User can select AssemblyAI, Deepgram, or Whisper
3. **Fallback**: Deepgram → AssemblyAI → Whisper

### API Changes

#### Deepgram Configuration
```
URL: wss://api.deepgram.com/v1/listen
Parameters:
  - model=nova-2
  - language=multi (automatic detection)
  - detect_language=true
  - punctuate=true
  - interim_results=true
```

#### AssemblyAI Configuration
```
URL: wss://streaming.assemblyai.com/v3/ws
Parameters:
  - speech_model=universal-streaming-multilingual
  - language_detection=true
  - format_turns=true
```

### Breaking Changes

None! Fully backward compatible.

### Migration Guide

#### From v2.2 to v2.3
1. **No action required** - Auto mode now uses Deepgram
2. **Deepgram key recommended** - For best multilingual support
3. **AssemblyAI still works** - Can manually select in Settings

### Known Limitations

- AssemblyAI multilingual has issues with real-time language switching
- Deepgram recommended for mixed-language meetings
- Very rapid language switching may reduce accuracy
- Heavy accents may affect language detection

### Performance

#### Latency
- **Deepgram**: ~100-200ms (multilingual)
- **AssemblyAI**: ~100-200ms (English-only reliable)
- **Whisper**: ~5 seconds (fallback)

#### Cost
- **Deepgram**: $0.0125/minute = $0.75/hour
- **AssemblyAI**: $0.27/hour (included key)
- **Whisper**: $0.006/minute = $0.36/hour

### Documentation

#### New Documentation
- `docs/MULTILINGUAL_SUPPORT.md` - Complete multilingual guide
- `MULTILINGUAL_TEST_CHECKLIST.md` - Testing guide

#### Updated Documentation
- `README.md` - Updated with multilingual features
- `docs/DEEPGRAM_IMPLEMENTATION.md` - Added language detection
- `docs/ASSEMBLYAI_IMPLEMENTATION.md` - Updated to v3 API

### Bug Fixes

1. **Settings Crash During Recording**
   - **Issue**: Opening Settings while recording caused crash
   - **Fix**: Disabled device discovery during recording
   - **Status**: ✅ Fixed

2. **Russian Not Transcribing**
   - **Issue**: Non-English languages not working
   - **Fix**: Switched to Deepgram with multilingual model
   - **Status**: ✅ Fixed

3. **Mixed Languages Not Working**
   - **Issue**: Only English transcribed in mixed meetings
   - **Fix**: Enabled automatic language detection
   - **Status**: ✅ Fixed

### Testing

#### Tested Languages
- ✅ English
- ✅ Russian
- ✅ Portuguese
- ✅ Mixed (English + Russian + Portuguese)

#### Test Results
- ✅ Single language transcription works
- ✅ Language switching works
- ✅ Settings doesn't crash during recording
- ✅ Language detection logs appear
- ✅ AI insights in system language

### Upgrade Instructions

1. **Download** Nota-v2.3.dmg
2. **Install** - Drag to Applications
3. **Launch** - Right-click → Open (first time)
4. **Test** - Record with multiple languages!

### What's Next (v2.4)

- [ ] Visual language indicator in UI
- [ ] Per-language accuracy metrics
- [ ] Custom vocabulary per language
- [ ] Real-time translation overlay
- [ ] Bilingual transcript export
- [ ] Language usage statistics

### Credits

- [Deepgram](https://deepgram.com) - Multilingual streaming STT
- [AssemblyAI](https://www.assemblyai.com) - Universal-Streaming v3
- Community feedback on multilingual support

---

**Release Date**: January 15, 2026  
**Version**: 2.3.0  
**Build**: 230  
**License**: MIT

**Download**: [Nota-v2.3.dmg](releases/Nota-v2.3.dmg)
