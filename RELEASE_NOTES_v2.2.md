# Nota v2.2.0 - Release Notes

## 🎉 What's New

### 🌍 Universal Language Support
**AssemblyAI now supports 99 languages!** No more language restrictions - transcribe meetings in any of 99 supported languages with a single provider.

### 🔑 Free Transcription Included
**Default API key included** - Start using Nota immediately without any API keys or credit cards. Just download, install, and start recording!

### 🚀 Improved Streaming Performance
- **Optimized audio streaming** - Only new audio chunks are sent (not entire file)
- **Better turn detection** - More accurate speech turn boundaries
- **KeepAlive support** - Maintains connection during silence
- **Proper cleanup** - Graceful WebSocket termination

---

## 📋 Key Features

### Transcription
- ✅ **99 languages** with AssemblyAI (included key)
- ✅ **Real-time streaming** (~100-200ms latency)
- ✅ **Smart fallback** (AssemblyAI → Deepgram → Whisper)
- ✅ **Auto language detection**
- ✅ **High accuracy** for major languages

### AI Analysis (Optional)
- ✅ **Meeting summaries** with GPT-5 Nano/Mini
- ✅ **Action items** with SMART criteria
- ✅ **Key insights** and observations
- ✅ **Sentiment analysis**
- ✅ **Keyword extraction**

### User Experience
- ✅ **Menu bar app** - Always accessible
- ✅ **Mini window** - Stays on top
- ✅ **Dashboard** - Full-featured interface
- ✅ **Recording history** - Auto-saved sessions
- ✅ **Project organization** - Auto-categorization

---

## 💰 Pricing

### Transcription (FREE!)
- **AssemblyAI**: FREE with included key (99 languages)
- Or add your own key: $0.27/hour for unlimited usage
- **Deepgram**: $0.75/hour (optional alternative)
- **Whisper**: $0.36/hour (automatic fallback)

### AI Insights (Optional)
- **GPT-5 Nano**: $0.01-0.05 per hour (recommended)
- **GPT-5 Mini**: $0.05-0.15 per hour

**Total cost for 1-hour meeting: FREE transcription + $0.01-0.05 for AI insights**

---

## 🔧 Technical Improvements

### AssemblyAI Integration
- Fixed message type parsing (`type` field)
- Proper Turn object handling
- Audio position tracking (efficient streaming)
- Session termination messages
- PCM16 audio format with base64 JSON
- Transcript accumulation with buffer management

### Deepgram Integration
- Audio position tracking (efficient streaming)
- Message type checking (`type: "Results"`)
- Speech final detection for better turns
- KeepAlive messages every 5 seconds
- CloseStream message on stop
- Raw binary PCM16 streaming

### Code Quality
- Comprehensive error handling
- Proper memory management
- Timer cleanup on stop
- WebSocket cleanup
- Detailed logging
- Performance optimizations

---

## 📚 Documentation

### New Documentation
- `docs/ASSEMBLYAI_IMPLEMENTATION.md` - Complete AssemblyAI technical docs
- `docs/DEEPGRAM_IMPLEMENTATION.md` - Complete Deepgram technical docs
- `CHANGELOG_v2.2.md` - Detailed changelog
- `TEST_REPORT_v2.2.md` - Comprehensive test report

### Updated Documentation
- `README.md` - Updated features, pricing, setup
- `docs/README.md` - Updated overview

---

## 🆙 Upgrade Guide

### From v2.1 to v2.2

#### Automatic Changes
- AssemblyAI key is automatically configured
- Provider defaults to "Auto" (AssemblyAI for all languages)
- No action required!

#### Optional Changes
- Add OpenAI API key for AI insights (Settings → API Configuration)
- Add your own AssemblyAI key for unlimited usage (Settings → Transcription API Keys)
- Add Deepgram key if you prefer their service (Settings → Transcription API Keys)

#### Breaking Changes
None! Fully backward compatible.

---

## 🐛 Bug Fixes

### Fixed Issues
- ✅ Settings tab crash (simplified UI)
- ✅ Speech Recognition permission removed (only Microphone needed)
- ✅ Accessibility permission prompt removed (no auto-prompt)
- ✅ Mini window not staying on top (now uses floating level)
- ✅ AssemblyAI message parsing (fixed type field)
- ✅ Deepgram audio streaming (position tracking)
- ✅ WebSocket cleanup (proper termination)

---

## 🎯 Getting Started

### Quick Start (3 steps!)
1. **Download** [Nota-v2.2.dmg](releases/Nota-v2.2.dmg)
2. **Install** - Drag to Applications folder
3. **Start Recording** - Click menu bar icon, start recording!

### Optional Setup
1. Add **OpenAI API key** for AI insights
2. Select your preferred **language**
3. Choose your **audio device**

That's it! No credit card, no signup, no hassle.

---

## 🌟 Supported Languages

### High Accuracy (≤10% WER)
English, Spanish, French, German, Indonesian, Italian, Japanese, Dutch, Polish, Portuguese, Russian, Turkish, Ukrainian, Catalan

### Good Accuracy (>10% to ≤25% WER)
Arabic, Azerbaijani, Bulgarian, Bosnian, Mandarin Chinese, Czech, Danish, Greek, Estonian, Finnish, Filipino, Galician, Hindi, Croatian, Hungarian, Korean, Macedonian, Malay, Norwegian Bokmål, Romanian, Slovak, Swedish, Thai, Urdu, Vietnamese

### Moderate Accuracy (>25% to ≤50% WER)
Afrikaans, Belarusian, Welsh, Persian (Farsi), Hebrew, Armenian, Icelandic, Kazakh, Lithuanian, Latvian, Māori, Marathi, Slovenian, Swahili, Tamil

### Fair Accuracy (>50% WER)
Amharic, Assamese, Bengali, Gujarati, Hausa, Javanese, Georgian, Khmer, Kannada, Luxembourgish, Lingala, Lao, Malayalam, Mongolian, Maltese, Burmese, Nepali, Occitan, Punjabi, Pashto, Sindhi, Shona, Somali, Serbian, Telugu, Tajik, Uzbek, Yoruba

**Total: 99 languages**

---

## 🔒 Privacy & Security

- ✅ **All data stored locally** on your Mac
- ✅ **No analytics or telemetry**
- ✅ **No data sent to developer**
- ✅ **API keys stored securely** in UserDefaults
- ✅ **Transcripts only sent to chosen provider** with your key
- ✅ **Open source** - verify the code yourself

---

## 🙏 Credits

- [AssemblyAI](https://www.assemblyai.com) - Universal-Streaming API (99 languages)
- [Deepgram](https://deepgram.com) - Multi-language streaming STT
- [OpenAI](https://openai.com) - GPT-5 API and Whisper
- [BlackHole](https://github.com/ExistentialAudio/BlackHole) - Virtual audio driver
- Community feedback and testing

---

## 📞 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Documentation**: [docs/](docs/)

---

## 🚀 What's Next?

### Planned for v2.3
- [ ] Usage metrics and API monitoring
- [ ] Visual indicator for active provider
- [ ] Language auto-detection
- [ ] Custom vocabulary support
- [ ] Speaker diarization
- [ ] Real-time translation
- [ ] Export formats (PDF, DOCX, SRT)
- [ ] Cloud sync

---

**Download Nota v2.2.0 now and start transcribing in 99 languages for free!**

[⬇️ Download Nota-v2.2.dmg](releases/Nota-v2.2.dmg)

---

**Release Date**: January 15, 2026  
**Version**: 2.2.0  
**Build**: 220  
**License**: MIT
