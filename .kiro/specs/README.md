# Nota Audio Capture Improvement Specs

## Overview

This directory contains specifications for improving Nota's audio capture functionality to match the performance of competitors like Cluealy/Pluely.

## Documents

### 1. [audio-capture-analysis.md](./audio-capture-analysis.md)
**Detailed comparison of Pluely vs Nota**

This document provides:
- What we know about Pluely's architecture and features
- What Nota currently has and doesn't have
- Root cause analysis of why Nota doesn't capture system audio
- Comparison table of features
- Recommended improvements prioritized by urgency
- Technical implementation details
- Action plan with immediate, short-term, and medium-term tasks

**Key Findings:**
- Pluely uses Tauri (Rust + React) for ~10MB app size
- Pluely has system audio capture, voice activity detection, and audio visualization
- Nota's AVAudioRecorder cannot select devices (always uses system default)
- Nota's AVAudioEngine implementation CAN select devices (already coded, needs testing)
- Main issue: Need to test AVAudioEngine with BlackHole and add user feedback

### 2. [audio-capture-requirements.md](./audio-capture-requirements.md)
**Formal requirements and user stories**

This document provides:
- Problem statement
- User stories with acceptance criteria (P0/P1/P2/P3 priority)
- Technical architecture and code examples
- Testing plan (unit, integration, manual tests)
- Success metrics and KPIs
- Dependencies and risks
- Timeline (4-week plan)
- Open questions for user feedback

**Key User Stories:**
- **US-1 (P0)**: Capture system audio from meetings using BlackHole
- **US-2 (P0)**: Show real-time audio levels so user knows audio is captured
- **US-3 (P0)**: Clear error messages when audio capture fails
- **US-4 (P1)**: Voice activity detection to save API costs
- **US-5 (P1)**: Audio visualization for visual confirmation
- **US-6 (P1)**: Automatic audio device verification on startup

## Current Status

### ✅ Completed
- AVAudioEngine implementation with device selection (compiles successfully)
- AssemblyAI v3 multilingual streaming integration
- Deepgram multilingual fallback
- Whisper local fallback
- Settings UI for device selection

### ⏳ In Progress
- Testing AVAudioEngine with BlackHole device
- Verifying audio levels show real sound (not -160.0dB)
- Verifying transcription works with system audio

### 🔴 Blocking Issues
- User has active meetings RIGHT NOW where Cluealy works but Nota captures silence
- Need to verify AVAudioEngine implementation works with BlackHole
- Need to add visual feedback so user knows if audio is being captured

## Next Steps

### Immediate (Today)
1. Test AVAudioEngine implementation with BlackHole
2. Verify audio levels show real sound during meeting
3. Verify AssemblyAI receives and transcribes audio
4. Add console logging for audio levels

### Short-term (This Week)
1. Add real-time audio level indicator in UI
2. Add voice activity detection
3. Add clear error messages for audio issues
4. Add audio device health check on startup

### Medium-term (Next Sprint)
1. Add audio visualization (waveform/bars)
2. Add global keyboard shortcuts
3. Add automatic audio routing setup
4. Add stealth mode for screen shares

## Questions for User

Before proceeding with implementation, please review and answer:

1. **Priority Confirmation**
   - Do you agree with the P0/P1/P2/P3 prioritization?
   - Any features you want to add/remove/reprioritize?

2. **Feature Preferences**
   - Do you want audio visualization (waveform/bars)?
   - Do you want voice activity detection (save API costs)?
   - Do you want global keyboard shortcuts (like Pluely's Cmd+Shift+M)?
   - Do you want stealth mode (translucent overlay)?

3. **Setup Approach**
   - Should we auto-configure audio routing or provide manual instructions?
   - Should we bundle BlackHole installer or link to external download?
   - Should we add a setup wizard for first-time users?

4. **Scope**
   - Focus on fixing audio capture first, then add features?
   - Or implement everything in parallel?
   - Any features from Pluely you specifically want to copy?

## How to Use These Specs

### For Development
1. Read `audio-capture-analysis.md` to understand the problem and solution
2. Read `audio-capture-requirements.md` for detailed user stories and acceptance criteria
3. Implement features in priority order (P0 → P1 → P2 → P3)
4. Test against acceptance criteria
5. Measure against success metrics

### For Testing
1. Use acceptance criteria from user stories as test cases
2. Follow testing plan in requirements document
3. Verify success metrics are met
4. Test with real meetings (Zoom, Meet, Teams)

### For Documentation
1. Update AUDIO_SETUP_GUIDE.md with new features
2. Add troubleshooting section for common issues
3. Create video tutorials for setup process
4. Document keyboard shortcuts and features

## Related Files

- `Nota-Swift/Sources/AudioRecorder.swift` - Main audio capture implementation
- `Nota-Swift/Sources/DashboardWindow.swift` - Settings UI with device selection
- `Nota-Swift/Sources/MiniWindowController.swift` - Recording controls
- `AUDIO_SETUP_GUIDE.md` - User guide for audio setup
- `docs/MULTILINGUAL_SUPPORT.md` - Multilingual transcription documentation

## References

- [Pluely GitHub](https://github.com/iamsrikanthnani/pluely) - Open source Cluealy alternative
- [BlackHole](https://github.com/ExistentialAudio/BlackHole) - Virtual audio device
- [AssemblyAI v3 Docs](https://www.assemblyai.com/docs/universal-streaming) - Multilingual streaming
- [Deepgram Docs](https://developers.deepgram.com/docs/live-streaming-audio) - Real-time transcription
- [AVAudioEngine Docs](https://developer.apple.com/documentation/avfaudio/avaudioengine) - Apple audio framework
