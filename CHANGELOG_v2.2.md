# Nota v2.2 - AssemblyAI Universal Support

## 🎉 Major Update: 99 Languages Support!

### What's New

#### 🌍 Universal Language Support
- **AssemblyAI Universal model** now supports **99 languages** (up from English-only)
- **Default API key included** - no setup required for transcription!
- All languages supported at one flat rate: $0.27/hour
- Automatic language detection for all supported languages

#### 🔑 Included API Key
- Pre-configured AssemblyAI API key: `bcacd502bfd640bd817306c3e35a3626`
- Works immediately after installation
- Users can optionally add their own key for higher usage limits
- No credit card required to start using Nota

#### 🚀 Improved Provider Selection
- **Auto mode** now defaults to AssemblyAI for ALL languages
- Smart fallback chain: AssemblyAI → Deepgram → Whisper
- Real-time streaming with ~100-200ms latency
- Immutable transcription (words don't change once finalized)

### Language Support Breakdown

#### High Accuracy (≤10% WER)
English, Spanish, French, German, Indonesian, Italian, Japanese, Dutch, Polish, Portuguese, Russian, Turkish, Ukrainian, Catalan

#### Good Accuracy (>10% to ≤25% WER)
Arabic, Azerbaijani, Bulgarian, Bosnian, Mandarin Chinese, Czech, Danish, Greek, Estonian, Finnish, Filipino, Galician, Hindi, Croatian, Hungarian, Korean, Macedonian, Malay, Norwegian Bokmål, Romanian, Slovak, Swedish, Thai, Urdu, Vietnamese

#### Moderate Accuracy (>25% to ≤50% WER)
Afrikaans, Belarusian, Welsh, Persian (Farsi), Hebrew, Armenian, Icelandic, Kazakh, Lithuanian, Latvian, Māori, Marathi, Slovenian, Swahili, Tamil

#### Fair Accuracy (>50% WER)
Amharic, Assamese, Bengali, Gujarati, Hausa, Javanese, Georgian, Khmer, Kannada, Luxembourgish, Lingala, Lao, Malayalam, Mongolian, Maltese, Burmese, Nepali, Occitan, Punjabi, Pashto, Sindhi, Shona, Somali, Serbian, Telugu, Tajik, Uzbek, Yoruba

**Total: 99 languages**

### Technical Improvements

#### AssemblyAI Implementation
- ✅ Fixed message type parsing (`type` instead of `message_type`)
- ✅ Proper Turn object handling with `end_of_turn` and `turn_is_formatted`
- ✅ Audio position tracking to avoid re-sending entire file
- ✅ Proper session termination with `{"type": "Terminate"}` message
- ✅ PCM16 audio format (16kHz, mono, 16-bit) in WAV container
- ✅ Base64 audio streaming in JSON format every 100ms

#### Settings UI Updates
- Default AssemblyAI key pre-filled
- Updated provider descriptions to reflect 99 language support
- Clearer labeling: "Auto (AssemblyAI - 99 Languages)"
- Help text updated to reflect included API key

### Pricing Changes

#### Before (v2.1)
- AssemblyAI: $0.15/hour (English only)
- Deepgram: $0.75/hour (30+ languages)
- Whisper: $0.36/hour (50+ languages)
- **Total for 1-hour meeting: $0.16-0.20**

#### After (v2.2)
- AssemblyAI: **FREE with included key** (99 languages)
- Or $0.27/hour with your own key
- Deepgram: $0.75/hour (optional alternative)
- Whisper: $0.36/hour (fallback only)
- **Total for 1-hour meeting: FREE transcription + $0.01-0.05 for AI insights**

### Migration Guide

#### For Existing Users
1. Update to v2.2
2. AssemblyAI key is automatically configured
3. No action needed - transcription works immediately!
4. Optionally add OpenAI key for AI insights

#### For New Users
1. Download and install Nota v2.2
2. Start recording immediately (no API keys required!)
3. Optionally add OpenAI key for AI insights and meeting analysis

### Documentation Updates

- ✅ Created `docs/ASSEMBLYAI_IMPLEMENTATION.md` with full technical details
- ✅ Updated `README.md` with new pricing and language support
- ✅ Updated setup instructions to reflect included API key
- ✅ Added language support breakdown

### Breaking Changes

None! This is a fully backward-compatible update.

### Known Issues

- AssemblyAI shared key has usage limits (add your own key if needed)
- Some languages have lower accuracy (see language breakdown above)
- Formatted transcripts have additional ~400-560ms latency

### Next Steps

1. Test with various languages to verify accuracy
2. Monitor shared API key usage
3. Consider adding language-specific optimizations
4. Add visual indicator showing which provider is active

### Credits

- [AssemblyAI](https://www.assemblyai.com) for Universal-Streaming API
- Community feedback for language support requests

---

**Release Date**: January 15, 2026
**Version**: 2.2.0
**Build**: 220
