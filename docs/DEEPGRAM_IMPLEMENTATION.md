# Deepgram Streaming Implementation

## Overview
Deepgram Live Streaming API has been implemented as an alternative transcription provider, supporting 30+ languages with real-time streaming capabilities.

## Implementation Details

### Audio Format
- **Format**: PCM16 (Linear PCM)
- **Sample Rate**: 16000 Hz
- **Channels**: 1 (mono)
- **Bit Depth**: 16-bit
- **File Extension**: .wav

### WebSocket Connection
- **URL**: `wss://api.deepgram.com/v1/listen`
- **Authentication**: `Token <api_key>` in `Authorization` header
- **Query Parameters**:
  - `encoding=linear16`
  - `sample_rate=16000`
  - `channels=1`
  - `language=<language_code>` (e.g., "en", "ru", "es")
  - `punctuate=true`
  - `interim_results=true`
  - `endpointing=300` (300ms silence detection)

### Audio Streaming
- **Format**: Raw PCM16 audio data (binary)
- **Chunk Size**: Variable, sent every 100ms
- **Position Tracking**: Only new audio data is sent (not entire file)

### Message Types

#### Sent to Deepgram:
1. **Audio Data**: Raw binary PCM16 audio chunks
2. **KeepAlive**: Sent every 5 seconds during silence
   ```json
   {"type": "KeepAlive"}
   ```
3. **CloseStream**: Sent when stopping recording
   ```json
   {"type": "CloseStream"}
   ```

#### Received from Deepgram:
1. **Results** - Transcription result:
   ```json
   {
     "type": "Results",
     "channel_index": [0, 1],
     "duration": 1.98,
     "start": 5.99,
     "is_final": true,
     "speech_final": true,
     "channel": {
       "alternatives": [
         {
           "transcript": "Tell me more about this.",
           "confidence": 0.99964225,
           "words": [...]
         }
       ]
     },
     "metadata": {
       "request_id": "...",
       "model_info": {...}
     }
   }
   ```

2. **Metadata** - Connection metadata:
   ```json
   {
     "type": "Metadata",
     "request_id": "...",
     "model_info": {...}
   }
   ```

3. **UtteranceEnd** - Utterance ended:
   ```json
   {
     "type": "UtteranceEnd"
   }
   ```

## Key Features

### Transcript Types
- **Interim Results** (`is_final: false`): Real-time partial transcripts
- **Final Results** (`is_final: true`): Finalized transcripts
- **Speech Final** (`speech_final: true`): End of speaking turn detected

### Turn Detection
- `is_final`: Indicates if the transcript is finalized
- `speech_final`: Indicates if the speaking turn has ended
- `endpointing`: 300ms silence threshold for turn detection

### KeepAlive Messages
- Sent every 5 seconds to maintain connection during silence
- Prevents connection timeout during pauses
- Essential for long meetings with quiet periods

### Position Tracking
- Tracks audio file position to avoid re-sending data
- Only new audio chunks are sent to Deepgram
- Reduces bandwidth and improves performance

## Language Support

Deepgram supports 30+ languages including:
- English (en)
- Spanish (es)
- French (fr)
- German (de)
- Portuguese (pt)
- Russian (ru)
- Chinese (zh)
- Japanese (ja)
- Korean (ko)
- And many more...

## Configuration

### Settings UI
Users can configure:
1. **Deepgram API Key**: Optional alternative to AssemblyAI
2. **Language**: Auto-detected or manually selected
3. **Provider**: Can manually select Deepgram over AssemblyAI

### UserDefaults Keys
- `deepgramKey`: Deepgram API key (optional)
- `transcriptionProvider`: "auto" | "assemblyai" | "deepgram" | "whisper"
- `outputLanguage`: Language code for transcription

## Error Handling

### Automatic Fallback
If Deepgram fails:
1. Logs error message
2. Automatically switches to Whisper
3. User sees seamless transition

### Common Issues
- **No API Key**: Falls back to Whisper
- **WebSocket Error**: Reconnects or falls back
- **Audio Format Error**: Logs error and retries with fallback

## Performance

### Latency
- **Interim Results**: ~100-200ms
- **Final Results**: ~300-500ms
- **Speech Final**: Additional ~300ms for turn detection
- **Audio Chunks**: Sent every 100ms

### Cost
- **Deepgram**: $0.0125/minute = $0.75/hour
- Supports 30+ languages at same rate
- No per-language pricing differences

## Testing

### Manual Testing Steps
1. Add Deepgram API key in Settings
2. Select "Deepgram" as provider (or "Auto" with non-English language)
3. Start recording
4. Speak in any supported language
5. Verify real-time transcription appears
6. Check console logs for connection status
7. Stop recording and verify final transcript

### Debug Logs
- `✅ Deepgram connection established: <request-id>`
- `📝 Deepgram interim: <text>`
- `✅ Deepgram final: <text>`
- `✅ Deepgram speech final: <text>`
- `🔚 Deepgram utterance ended`
- `❌ Deepgram WebSocket error: <error>`

## Comparison with AssemblyAI

| Feature | AssemblyAI | Deepgram |
|---------|------------|----------|
| Languages | 99 | 30+ |
| Cost | $0.27/hour | $0.75/hour |
| Latency | ~100-200ms | ~100-200ms |
| Accuracy (EN) | High | High |
| Turn Detection | `end_of_turn` | `speech_final` |
| KeepAlive | Not needed | Required |
| Audio Format | Base64 JSON | Raw binary |

## Best Practices

1. **Use AssemblyAI by default** - Better pricing and more languages
2. **Use Deepgram for specific needs** - If you prefer their API or have existing integration
3. **Monitor KeepAlive** - Ensure messages are sent during silence
4. **Track Audio Position** - Avoid re-sending entire file
5. **Handle speech_final** - Use for better turn detection
6. **Send CloseStream** - Properly close connection when stopping

## References
- [Deepgram Live Streaming Docs](https://developers.deepgram.com/docs/live-streaming-audio)
- [Deepgram API Reference](https://developers.deepgram.com/reference/listen-live)
- [Deepgram Pricing](https://deepgram.com/pricing)
