# Nota Specifications

This directory contains specification files for Nota development.

## Active Specs

### [GPT-5 Models Integration & App Improvements](./gpt5-models-and-improvements.md)
**Status:** In Progress  
**Priority:** High  
**Created:** January 14, 2026

Updates Nota to use GPT-5 model series and implements critical improvements:

1. **GPT-5 Model Integration**
   - Migrate from GPT-4o models to GPT-5 Nano and GPT-5 Mini
   - API model names: `gpt-5-nano`, `gpt-5-mini`
   - Default to GPT-5 Nano for cost efficiency ($0.05/$0.40 per 1M tokens)

2. **Settings Tab in Dashboard**
   - Move settings from removed popover to Dashboard
   - Create SettingsTabView with Liquid Glass 2026 design
   - Include API keys, model selection, language, audio device settings

3. **Audio Capture Improvements**
   - Verify BlackHole aggregate device support
   - Add audio level monitoring
   - Improve recognition sensitivity
   - Add debug logging for audio issues

4. **Crash Protection**
   - Add comprehensive error handling
   - Wrap API calls in try-catch blocks
   - Implement graceful degradation
   - Add user-facing error messages

## Implementation Status

### Completed
- ✅ Liquid Glass 2026 design implementation
- ✅ Icon synchronization (app + tray)
- ✅ Icon consistency fixes (load from files, not programmatic)
- ✅ Smart transcription system (6s intervals, 45s insights)
- ✅ Interface simplification (removed popover, added home button)
- ✅ Messenger-style transcript bubbles
- ✅ Recording history system
- ✅ Research GPT-5 API model names
- ✅ Tray icon generation script and documentation

### In Progress
- 🔄 GPT-5 model integration
- 🔄 Settings tab in Dashboard
- 🔄 Audio capture improvements
- 🔄 Crash protection

### Pending
- ⏳ BlackHole aggregate device testing
- ⏳ Audio level indicator UI
- ⏳ Comprehensive error handling

## Key Files

### Source Files
- `Nota-Swift/Sources/AudioRecorder.swift` - Audio recording, transcription, AI processing
- `Nota-Swift/Sources/StatusBarController.swift` - Tray icon, menu
- `Nota-Swift/Sources/MiniWindowController.swift` - Mini window UI
- `Nota-Swift/Sources/DashboardWindow.swift` - Dashboard with tabs

### Documentation
- `LIQUID_GLASS_IMPLEMENTATION.md` - Design system guidelines
- `README.md` - Project overview
- `QUICKSTART.md` - Quick start guide

## Next Actions

1. Update AudioRecorder.swift with GPT-5 model names
2. Create SettingsTabView in DashboardWindow.swift
3. Add error handling throughout the app
4. Test with BlackHole aggregate device
5. Add audio level monitoring UI

## Notes

- Current date: January 14, 2026
- GPT-5 launched August 7, 2025
- Context window: 400K tokens (both Nano and Mini)
- Temperature: 0.3 for consistency
- Buffer size: 4096 for better audio capture
