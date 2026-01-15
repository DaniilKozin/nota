# AssemblyAI Streaming Implementation

## Overview
AssemblyAI Universal-Streaming has been implemented as the **default transcription provider for all languages**, supporting 99 languages with automatic fallback to Deepgram or Whisper if needed.

## Language Support

AssemblyAI Universal model supports **99 languages** including:

### High Accuracy (≤10% WER)
English, Spanish, French, German, Indonesian, Italian, Japanese, Dutch, Polish, Portuguese, Russian, Turkish, Ukrainian, Catalan

### Good Accuracy (>10% to ≤25% WER)
Arabic, Azerbaijani, Bulgarian, Bosnian, Mandarin Chinese, Czech, Danish, Greek, Estonian, Finnish, Filipino, Galician, Hindi, Croatian, Hungarian, Korean, Macedonian, Malay, Norwegian Bokmål, Romanian, Slovak, Swedish, Thai, Urdu, Vietnamese

### Moderate Accuracy (>25% to ≤50% WER)
Afrikaans, Belarusian, Welsh, Persian (Farsi), Hebrew, Armenian, Icelandic, Kazakh, Lithuanian, Latvian, Māori, Marathi, Slovenian, Swahili, Tamil

### Fair Accuracy (>50% WER)
Amhric, Assamese, Bengali, Gujarati, Hausa, Javanese, Georgian, Khmer, Kannada, Luxembourgish, Lingala, Lao, Malayalam, Mongolian, Maltese, Burmese, Nepali, Occitan, Punjabi, Pashto, Sindhi, Shona, Somali, Serbian, Telugu, Tajik, Uzbek, Yoruba

**Total: 99 languages at one flat rate**

## Implementation Details

### Audio Format
- **Format**: PCM16 (Linear PCM)
- **Sample Rate**: 16000 Hz
- **Channels**: 1 (mono)
- **Bit Depth**: 16-bit
- **File Extension**: .wav

### WebSocket Connection
- **URL**: `wss://api.assemblyai.com/v2/realtime/ws?sample_rate=16000`
- **Authentication**: API key in `Authorization` header
- **Audio Streaming**: Base64-encoded audio chunks sent in JSON format every 100ms

### Message Types

#### Sent to AssemblyAI:
1. **Audio Data**:
   ```json
   {"audio_data": "<base64_encoded_pcm16_audio>"}
   ```

2. **Terminate Session**:
   ```json
   {"type": "Terminate"}
   ```

#### Received from AssemblyAI:
1. **Begin** - Session started:
   ```json
   {
     "type": "Begin",
     "id": "session-uuid",
     "expires_at": 1234567890
   }
   ```

2. **Turn** - Transcription result:
   ```json
   {
     "type": "Turn",
     "turn_order": 0,
     "turn_is_formatted": false,
     "end_of_turn": false,
     "transcript": "hello world",
     "end_of_turn_confidence": 0.8,
     "words": [...]
   }
   ```

3. **Termination** - Session ended:
   ```json
   {
     "type": "Termination",
     "audio_duration_seconds": 120.5,
     "session_duration_seconds": 125.0
   }
   ```

4. **Error** - Error occurred:
   ```json
   {
     "type": "Error",
     "error": "error message"
   }
   ```

## Key Features

### Immutable Transcription
Unlike traditional streaming STT that overwrites partial results, AssemblyAI provides immutable transcriptions:
- Each word once finalized will not change
- `word_is_final` indicates if the last word is complete
- Transcripts build progressively: "hello" → "hello my" → "hello my name"

### Turn Detection
- `end_of_turn`: Boolean indicating if the current speaking turn has ended
- `turn_is_formatted`: Boolean indicating if text formatting has been applied
- Formatted turns include proper capitalization and punctuation

### Smart Provider Selection
The app automatically selects the best provider:
- **Auto Mode** (default): AssemblyAI for all 99 supported languages
- **Manual Selection**: Users can override in Settings to use Deepgram or Whisper
- **Fallback Chain**: AssemblyAI → Deepgram → Whisper
- **Included API Key**: Default AssemblyAI key included for immediate use

## Configuration

### Settings UI
Users can configure:
1. **Transcription Provider**: Auto (AssemblyAI), AssemblyAI, Deepgram, or Whisper
2. **AssemblyAI API Key**: Default key included, or add your own
3. **Deepgram API Key**: Optional alternative provider
4. **OpenAI API Key**: Required for insights and Whisper fallback

### UserDefaults Keys
- `transcriptionProvider`: "auto" | "assemblyai" | "deepgram" | "whisper" (default: "auto")
- `assemblyaiKey`: AssemblyAI API key (default: included key)
- `deepgramKey`: Deepgram API key (optional)
- `openaiKey`: OpenAI API key (required for insights and Whisper fallback)

## Error Handling

### Automatic Fallback
If AssemblyAI fails:
1. Logs error message
2. Automatically switches to Deepgram
3. If Deepgram fails, falls back to Whisper
4. User sees seamless transition

### Common Issues
- **No API Key**: Falls back to next provider
- **WebSocket Error**: Reconnects or falls back
- **Audio Format Error**: Logs error and retries with fallback

## Performance

### Latency
- **AssemblyAI**: ~100-200ms for interim results
- **Formatted Results**: Additional ~400-560ms for punctuation
- **Audio Chunks**: Sent every 100ms for real-time streaming

### Cost
- **AssemblyAI**: $0.27/hour for all 99 languages
- **Deepgram**: $0.0125/minute = $0.75/hour (30+ languages)
- **Whisper**: $0.006/minute = $0.36/hour (50+ languages, but 5s latency)

### Default API Key
The app includes a default AssemblyAI API key for immediate use. Users can optionally add their own key for higher usage limits.

## Testing

### Manual Testing Steps
1. Open Settings (default AssemblyAI key is already configured)
2. Select "Auto" or "AssemblyAI" as provider
3. Start recording
4. Speak in any of the 99 supported languages
5. Verify real-time transcription appears
6. Check console logs for connection status
7. Stop recording and verify final transcript

### Testing Different Languages
- English: Should show high accuracy
- Spanish/French/German: Should show high accuracy
- Russian/Chinese/Japanese: Should show good accuracy
- Other languages: Check accuracy tier in language list above

### Debug Logs
- `✅ AssemblyAI session started: <session-id>`
- `📝 AssemblyAI interim: <text>`
- `✅ AssemblyAI final: <text>`
- `✅ AssemblyAI final (formatted): <text>`
- `❌ AssemblyAI error: <error>`

## References
- [AssemblyAI Universal-Streaming Docs](https://www.assemblyai.com/docs/universal-streaming)
- [AssemblyAI Pricing](https://www.assemblyai.com/pricing)
- [Turn Object Structure](https://www.assemblyai.com/docs/universal-streaming#turn-object)
