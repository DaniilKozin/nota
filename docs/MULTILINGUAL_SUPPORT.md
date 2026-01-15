# Multilingual Meeting Support

## Overview
Nota v2.2+ supports **mixed-language meetings** where participants speak different languages. The app automatically detects languages and provides insights in your system language.

## How It Works

### 1. Automatic Language Detection
- **AssemblyAI** detects the language of each utterance in real-time
- Supports **99 languages** with automatic switching
- No manual language selection needed
- Works seamlessly with code-switching (switching between languages mid-conversation)

### 2. Real-Time Transcription
- Each speaker's language is detected automatically
- Transcripts show the original language as spoken
- Language detection confidence displayed in console logs
- Example: "🌍 Detected language: ru (confidence: 95%)"

### 3. AI Insights Translation
- **All insights are provided in your system language**
- Multilingual transcripts are analyzed and translated
- Summary, action items, and key insights in your language
- Original meaning and context preserved

## Use Cases

### International Teams
**Scenario**: Team with English, Russian, and Korean speakers
- English speaker: "Let's discuss the Q4 roadmap"
- Russian speaker: "Мы должны сосредоточиться на производительности"
- Korean speaker: "다음 주까지 완료할 수 있습니다"

**Result**:
- Transcript: Shows all three languages as spoken
- Insights: Translated to your system language (e.g., English)
- Action items: "Focus on performance (by next week)"

### Client Meetings
**Scenario**: Sales call with Portuguese and English
- Sales rep (English): "Our solution offers 99% uptime"
- Client (Portuguese): "Quanto custa por mês?"
- Sales rep (English): "Starting at $99 per month"

**Result**:
- Transcript: Mixed English/Portuguese
- Insights: "Client asked about monthly pricing ($99/month)"

### Technical Discussions
**Scenario**: Code review with mixed languages
- Developer 1 (English): "This function needs optimization"
- Developer 2 (Russian): "Я могу это исправить сегодня"
- Developer 3 (English): "Let's use caching"

**Result**:
- Action items: "Optimize function with caching (Developer 2 to fix today)"

## Configuration

### Enable Multilingual Mode
Multilingual mode is **enabled by default** in v2.2+. No configuration needed!

### System Language
Insights are provided in your macOS system language:
1. System Settings → General → Language & Region
2. Nota will use your primary language for insights
3. Supported insight languages: All major languages

### Manual Language Override
If you want to force a specific language for insights:
1. Open Dashboard → Settings
2. Select "Language" dropdown
3. Choose your preferred language
4. Insights will be in that language regardless of system settings

## Technical Details

### AssemblyAI Configuration
```
WebSocket URL: wss://api.assemblyai.com/v2/realtime/ws
Parameters:
  - sample_rate=16000
  - speech_model=universal-streaming-multilingual
  - language_detection=true
```

### Language Detection Response
```json
{
  "type": "Turn",
  "transcript": "Hello, как дела?",
  "language_code": "en",
  "language_confidence": 0.95,
  "end_of_turn": true
}
```

### AI Insights Prompt
```
IMPORTANT: The transcript may contain multiple languages.
- Analyze the content in whatever languages are present
- Provide ALL responses in [System Language]
- Translate any non-[System Language] content
- Preserve the original meaning and context
```

## Supported Languages

### High Accuracy (≤10% WER)
English, Spanish, French, German, Indonesian, Italian, Japanese, Dutch, Polish, Portuguese, Russian, Turkish, Ukrainian, Catalan

### Good Accuracy (>10% to ≤25% WER)
Arabic, Azerbaijani, Bulgarian, Bosnian, Mandarin Chinese, Czech, Danish, Greek, Estonian, Finnish, Filipino, Galician, Hindi, Croatian, Hungarian, Korean, Macedonian, Malay, Norwegian Bokmål, Romanian, Slovak, Swedish, Thai, Urdu, Vietnamese

### Moderate Accuracy (>25% to ≤50% WER)
Afrikaans, Belarusian, Welsh, Persian (Farsi), Hebrew, Armenian, Icelandic, Kazakh, Lithuanian, Latvian, Māori, Marathi, Slovenian, Swahili, Tamil

### Fair Accuracy (>50% WER)
Amharic, Assamese, Bengali, Gujarati, Hausa, Javanese, Georgian, Khmer, Kannada, Luxembourgish, Lingala, Lao, Malayalam, Mongolian, Maltese, Burmese, Nepali, Occitan, Punjabi, Pashto, Sindhi, Shona, Somali, Serbian, Telugu, Tajik, Uzbek, Yoruba

**Total: 99 languages**

## Best Practices

### For Best Results
1. **Clear Audio**: Ensure good microphone quality
2. **One Speaker at a Time**: Avoid overlapping speech
3. **Natural Pace**: Speak at normal conversational speed
4. **Context**: Provide context when switching languages

### Common Patterns
- **Code-Switching**: Switching between languages mid-sentence
- **Technical Terms**: English technical terms in non-English conversations
- **Names**: Proper nouns in original language
- **Quotes**: Direct quotes in original language

### Limitations
- Very rapid language switching may reduce accuracy
- Heavy accents may affect language detection
- Background noise can interfere with detection
- Some language pairs may have lower accuracy

## Troubleshooting

### Language Not Detected
**Issue**: Language detection shows wrong language

**Solutions**:
1. Speak more clearly and at normal pace
2. Provide more context (longer utterances)
3. Check microphone quality
4. Ensure language is in supported list

### Insights Not Translated
**Issue**: Insights still in original language

**Solutions**:
1. Check system language settings
2. Ensure OpenAI key is configured
3. Try regenerating insights
4. Check console logs for errors

### Mixed Language Accuracy
**Issue**: Transcription accuracy drops with mixed languages

**Solutions**:
1. Use "Auto" provider (AssemblyAI multilingual)
2. Ensure good audio quality
3. Avoid rapid language switching
4. Speak one language per sentence when possible

## Examples

### Example 1: English + Russian
**Transcript**:
```
Speaker 1: Let's review the sprint goals
Speaker 2: Мы завершили три задачи
Speaker 1: Great! What about the API integration?
Speaker 2: Это будет готово завтра
```

**Insights (in English)**:
```json
{
  "summary": "Sprint review discussing completed tasks and API integration timeline",
  "action_items": [
    {
      "task": "Complete API integration",
      "deadline": "Tomorrow",
      "assignee": "Speaker 2"
    }
  ],
  "languages_detected": ["en", "ru"]
}
```

### Example 2: English + Korean + Portuguese
**Transcript**:
```
Manager: What's the status on the mobile app?
Developer 1: 앱 개발이 80% 완료되었습니다
Developer 2: Precisamos de mais dois dias para testes
Manager: Sounds good, let's target Friday release
```

**Insights (in English)**:
```json
{
  "summary": "Mobile app development at 80% completion, needs two more days for testing, targeting Friday release",
  "action_items": [
    {
      "task": "Complete mobile app testing",
      "deadline": "Friday",
      "priority": "high"
    }
  ],
  "languages_detected": ["en", "ko", "pt"]
}
```

## Cost Considerations

### Transcription
- **AssemblyAI**: $0.27/hour (all languages)
- No additional cost for multilingual detection
- Same rate regardless of number of languages

### AI Insights
- **GPT-5 Nano**: $0.01-0.05/hour
- Translation included in analysis
- No additional cost for multilingual content

**Total**: ~$0.28-0.32/hour for multilingual meetings

## Future Enhancements

### Planned Features
- [ ] Real-time translation overlay
- [ ] Language-specific speaker identification
- [ ] Bilingual transcript export (original + translated)
- [ ] Custom vocabulary per language
- [ ] Language usage statistics
- [ ] Automatic meeting language detection

## References
- [AssemblyAI Multilingual Streaming](https://www.assemblyai.com/docs/universal-streaming/multilingual-transcription)
- [Supported Languages](https://www.assemblyai.com/docs/concepts/supported-languages)
- [Language Detection API](https://www.assemblyai.com/docs/universal-streaming/multilingual-transcription)

---

**Questions?** Open an issue on [GitHub](https://github.com/DaniilKozin/nota/issues)
