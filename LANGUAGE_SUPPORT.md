# Language Support in Nota

## Overview

Nota supports transcription in multiple languages, but the available languages depend on which provider is used.

## Supported Languages by Provider

### AssemblyAI Streaming (Real-time)
**Supported Languages (6):**
- 🇬🇧 English (en)
- 🇪🇸 Spanish (es)
- 🇫🇷 French (fr)
- 🇩🇪 German (de)
- 🇮🇹 Italian (it)
- 🇵🇹 Portuguese (pt)

**Features:**
- ✅ Real-time streaming (~100-200ms latency)
- ✅ Automatic language detection
- ✅ Code-switching (mixed languages in same conversation)
- ✅ High accuracy
- ❌ NO speaker diarization in streaming

**Use for:**
- English meetings
- Spanish/French/German/Italian/Portuguese meetings
- Mixed conversations with these languages

### OpenAI Whisper (Batch)
**Supported Languages (50+):**
- 🇷🇺 Russian (ru)
- 🇨🇳 Chinese (zh)
- 🇯🇵 Japanese (ja)
- 🇰🇷 Korean (ko)
- 🇺🇦 Ukrainian (uk)
- 🇵🇱 Polish (pl)
- 🇹🇷 Turkish (tr)
- 🇦🇪 Arabic (ar)
- 🇮🇳 Hindi (hi)
- And 40+ more languages

**Features:**
- ✅ 50+ languages supported
- ✅ High accuracy
- ✅ Automatic language detection per chunk
- ✅ **Context preservation** between chunks (maintains conversation flow)
- ✅ Mixed-language support (auto-detects language per 5s chunk)
- ⚠️ Slower (5-10 second chunks)
- ❌ NO real-time streaming
- ❌ NO speaker diarization

**Context Preservation:**
- Uses previous transcript as `prompt` parameter
- Maintains conversation continuity across chunks
- Improves accuracy for names, technical terms, and context
- Works across language switches

**Use for:**
- Russian meetings
- Asian languages (Chinese, Japanese, Korean)
- Mixed-language meetings (e.g., English + Russian)
- Any language not supported by AssemblyAI

## How Nota Chooses Provider

### Auto Mode (Default)

```
1. Check system language setting
2. If language is en/es/fr/de/it/pt:
   → Use AssemblyAI Streaming (real-time)
3. If language is anything else (ru, zh, ja, ko, etc.):
   → Use Whisper (batch, 5s chunks)
```

### Manual Mode

You can manually select provider in Settings:
- **AssemblyAI**: Force use of AssemblyAI (only works for 6 languages)
- **Whisper**: Force use of Whisper (works for 50+ languages)

## Language Detection

### AssemblyAI
- Automatically detects language from audio
- Works for 6 supported languages
- Can handle code-switching (e.g., English + Spanish in same conversation)

### Whisper
- Automatically detects language from audio
- Works for 50+ languages
- Processes in 5-second chunks

## Speaker Diarization (Who Said What)

### Current Status
❌ **NOT AVAILABLE in real-time streaming**

### Why?
- AssemblyAI Streaming doesn't support speaker diarization
- Whisper doesn't support speaker diarization
- Speaker diarization requires batch processing after recording

### Future Plans
We plan to add speaker diarization in v2.4:
1. Record audio during meeting
2. After meeting ends, upload to AssemblyAI Batch API
3. Get transcript with speaker labels (Speaker A, Speaker B, etc.)
4. Display in meeting history with speaker tags

## Examples

### Example 1: English Meeting
```
Language: English (en)
Provider: AssemblyAI Streaming
Latency: ~200ms
Quality: Excellent
Speaker Diarization: Not available
```

### Example 2: Russian Meeting
```
Language: Russian (ru)
Provider: Whisper
Latency: ~5 seconds per chunk
Quality: Good
Speaker Diarization: Not available
```

### Example 3: Mixed English + Spanish
```
Languages: English + Spanish
Provider: AssemblyAI Streaming
Latency: ~200ms
Quality: Excellent (handles code-switching)
Speaker Diarization: Not available
```

### Example 4: Mixed English + Russian
```
Languages: English + Russian
Provider: Whisper (because Russian not supported by AssemblyAI)
Latency: ~5 seconds per chunk
Quality: Good
Context: Preserved between chunks using prompt parameter
Speaker Diarization: Not available
Note: Auto-detects language per chunk, maintains conversation flow
```

## Recommendations

### For Best Real-time Experience
Use languages supported by AssemblyAI:
- English, Spanish, French, German, Italian, Portuguese

### For Other Languages
- Whisper works well but with 5-second delay
- Still good for meetings, just not instant

### For Speaker Identification
- Currently not available
- Coming in v2.4 as post-meeting feature
- Will work for all languages

## Troubleshooting

### Problem: Russian doesn't transcribe in real-time

**Cause**: AssemblyAI Streaming doesn't support Russian

**Solution**: 
- Nota automatically uses Whisper for Russian
- You'll see transcription in 5-second chunks
- This is expected behavior

### Problem: Want speaker labels (who said what)

**Cause**: Speaker diarization not available in streaming

**Solution**:
- Feature coming in v2.4
- Will be available as post-meeting analysis
- Will work for all languages

### Problem: Mixed English + Russian doesn't work well

**Cause**: Different languages in same meeting

**Solution**:
- ✅ Whisper auto-detects language per 5-second chunk
- ✅ Context is preserved between chunks using prompt parameter
- ✅ Works well for mixed-language meetings
- Set language to "Auto" or manually select "Whisper" provider
- Conversation flow is maintained across language switches

## API Costs

### AssemblyAI Streaming
- **Cost**: $0.27/hour
- **Included**: Default API key provided
- **Languages**: 6 languages (en, es, fr, de, it, pt)

### Whisper
- **Cost**: $0.36/hour
- **Required**: Your own OpenAI API key
- **Languages**: 50+ languages

## Future Roadmap

### v2.4 (Planned)
- ✅ Speaker diarization (post-meeting)
- ✅ Speaker identification (name speakers)
- ✅ Better mixed-language support
- ✅ Real-time language switching

### v2.5 (Planned)
- ✅ More streaming languages (if AssemblyAI adds them)
- ✅ Custom vocabulary per language
- ✅ Accent adaptation

## Summary

| Feature | AssemblyAI | Whisper |
|---------|-----------|---------|
| **Languages** | 6 | 50+ |
| **Real-time** | ✅ Yes (~200ms) | ❌ No (~5s chunks) |
| **Russian** | ❌ No | ✅ Yes |
| **Speaker Diarization** | ❌ No | ❌ No |
| **Code-switching** | ✅ Yes | ⚠️ Limited |
| **Cost** | $0.27/hr (included) | $0.36/hr (your key) |
| **Best for** | English, Spanish, French, German, Italian, Portuguese | Russian, Chinese, Japanese, Korean, and 40+ more |

**Bottom line**: 
- English/Spanish/French/German/Italian/Portuguese → AssemblyAI (fast, real-time)
- Russian/Chinese/Japanese/Korean/etc → Whisper (good, but 5s delay)
- Speaker diarization → Coming in v2.4 (post-meeting feature)
