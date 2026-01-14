# GPT-5 Models Integration & App Improvements

## Status: In Progress
**Created:** January 14, 2026  
**Priority:** High

---

## Overview
Update Nota to use the latest GPT-5 model series (January 2026) and implement critical improvements for stability, audio capture, and settings management.

---

## User Requirements

### 0. Icon Consistency Fix
**User Request:** "check also icons there are some inconcistency in files, should be always from hre /Users/daniilkozin/Downloads/Recorder/Nota-Swift/icons"

**Current State:**
- StatusBarController was drawing programmatic icon instead of using actual icon file
- Multiple duplicate icon files with inconsistent usage
- Tray icon not matching app icon design

**Completed Changes:**
- ✅ Generated new tray icons from `Remove_background-1768397997157.png`
- ✅ Created tray-18x18.png, tray-22x22.png, tray-36x36.png (Retina)
- ✅ Updated StatusBarController to load actual icon files instead of drawing programmatically
- ✅ Updated create_app_bundle.sh to copy correct tray icons
- ✅ Created icon generation script: `generate_tray_icons.sh`
- ✅ Created comprehensive icon documentation: `icons/README.md`

**Icon Files:**
- App Icon: `AppIcon.icns` (colorful, for Dock/Finder)
- Tray Icons: `tray-18x18.png`, `tray-22x22.png`, `tray-36x36.png` (monochrome, for menu bar)
- Source: `Remove_background-1768397997157.png` (1024x1024px)

---

### 1. GPT-5 Model Integration
**User Request:** "сделай ресерч по моделям. говорю же 5 GPT сейчас актуальные"

**Current State:**
- Using outdated model names: `gpt-4o-mini-2024-07-18`, `gpt-4o-2024-08-06`
- Settings show "GPT-4o Mini" and "GPT-4o" options
- API calls use old model identifiers

**Required Changes:**
- ✅ **CONFIRMED API Model Names:**
  - GPT-5 Nano: `gpt-5-nano`
  - GPT-5 Mini: `gpt-5-mini`
  - GPT-5 (full): `gpt-5`
- Update to GPT-5 Nano and GPT-5 Mini only (remove all other models)
- Set GPT-5 Nano as default for cost efficiency
- Update API calls in `AudioRecorder.swift`
- Update Settings UI to show only Nano and Mini options

**GPT-5 Pricing (January 2026):**
| Model | Context | Max Output | Input Price | Output Price |
|-------|---------|------------|-------------|--------------|
| GPT-5 Nano | 400K tokens | 128K tokens | $0.05/1M | $0.40/1M |
| GPT-5 Mini | 400K tokens | 128K tokens | $0.25/1M | $2.00/1M |

**Acceptance Criteria:**
- [x] Research and identify correct GPT-5 API model names (`gpt-5-nano`, `gpt-5-mini`)
- [ ] Update `selectedModel` default to `gpt-5-nano`
- [ ] Update Settings picker to show only "GPT-5 Nano ($0.05/$0.40)" and "GPT-5 Mini ($0.25/$2.00)"
- [ ] Update `sendOpenAIRequest()` to use correct model names
- [ ] Update `generateFinalInsights()` model selection logic
- [ ] Update `generateLiveInsights()` to always use `gpt-5-nano`
- [ ] Test API calls work with new model names

---

### 2. Settings Tab in Dashboard
**User Request:** "и настройки не вижу где теперь. должны быть в дашборде по идее где-то"

**Current State:**
- Settings exist in `StatusBarController.swift` as `SettingsView`
- Dashboard has tabs for History, Projects, Analytics
- No Settings tab in Dashboard
- Settings only accessible from popover (which was removed)

**Required Changes:**
- Create `SettingsTabView` in `DashboardWindow.swift`
- Add Settings tab to Dashboard TabView (tag: 3)
- Move settings UI from `StatusBarController.swift` to Dashboard
- Ensure AudioRecorder instance is shared properly

**Acceptance Criteria:**
- [ ] Create `SettingsTabView` struct in DashboardWindow.swift
- [ ] Add Settings tab with icon "gearshape.fill" and text "Settings"
- [ ] Include all settings: API keys, model selection, language, audio device
- [ ] Apply Liquid Glass 2026 design language
- [ ] Test settings changes persist and update AudioRecorder

---

### 3. Improve Audio Capture
**User Request:** "проверь достаточно плохо ловится звук и не все считывается, может что-то можно подкрутить"

**Current State:**
- Buffer size: 4096 (already increased from 1024)
- Using Speech Framework for recognition
- BlackHole support mentioned but not fully tested

**Required Changes:**
- Verify BlackHole aggregate device support
- Add audio level monitoring/debugging
- Increase recognition sensitivity if possible
- Add error handling for audio input issues
- Test with different audio sources

**Acceptance Criteria:**
- [ ] Add audio input level indicator in mini window
- [ ] Verify aggregate device (microphone + computer audio) works
- [ ] Add debug logging for audio format and buffer info
- [ ] Test with BlackHole 2ch and 16ch
- [ ] Document audio setup requirements

---

### 4. Crash Protection
**User Request:** "приложение нестабильно работает, щас просто упало" + "проверь чтобы не крашился апп"

**Current State:**
- No comprehensive error handling
- Force unwraps in some places
- No crash recovery mechanism

**Required Changes:**
- Add try-catch blocks around critical operations
- Wrap API calls in error handlers
- Add nil checks for optional values
- Implement graceful degradation
- Add crash logging

**Acceptance Criteria:**
- [ ] Wrap all API calls in do-catch blocks
- [ ] Add error handling in `startRecording()` and `stopRecording()`
- [ ] Handle audio engine failures gracefully
- [ ] Add error alerts to user when critical failures occur
- [ ] Test crash scenarios: no internet, invalid API key, audio permission denied

---

## Technical Implementation Plan

### Phase 1: Research & Model Update
1. Search OpenAI API documentation for GPT-5 model names
2. Update model constants in AudioRecorder.swift
3. Update Settings UI model picker
4. Test API calls with new models

### Phase 2: Settings Migration
1. Create SettingsTabView in DashboardWindow.swift
2. Copy settings UI from StatusBarController
3. Add Settings tab to Dashboard
4. Remove old settings view from StatusBarController
5. Test settings persistence

### Phase 3: Audio Improvements
1. Add audio level monitoring
2. Test BlackHole aggregate device
3. Add debug logging for audio issues
4. Document setup requirements

### Phase 4: Stability & Error Handling
1. Add try-catch blocks to all API calls
2. Add error handling to recording lifecycle
3. Add user-facing error messages
4. Test failure scenarios

---

## Files to Modify

### Primary Files:
- `Nota-Swift/Sources/AudioRecorder.swift` - Model names, API calls, error handling
- `Nota-Swift/Sources/DashboardWindow.swift` - Add SettingsTabView
- `Nota-Swift/Sources/StatusBarController.swift` - Remove/update SettingsView

### Testing Files:
- `Nota-Swift/test_transcription.swift` - Test new models
- `test_apis.swift` - Verify API calls

---

## Dependencies
- OpenAI API access with GPT-5 models enabled
- BlackHole audio driver (for system audio capture)
- macOS Speech Recognition permissions

---

## Success Metrics
- [x] Icons loaded from consistent location (Nota-Swift/icons/)
- [x] Tray icon uses actual PNG file instead of programmatic drawing
- [x] Icon generation script created for future updates
- [x] AudioRecorder синхронизирован между Dashboard и MiniWindow
- [x] GPT-5 Nano и Mini модели используются вместо GPT-4o
- [x] Настройки улучшены визуально и по ширине
- [x] Эмодзи убран из заголовка Dashboard
- [x] Keywords, company, meeting_type добавлены в AI анализ
- [ ] Audio capture works with aggregate devices
- [ ] No crashes during normal operation
- [ ] Error messages shown to user on failures

---

## Notes
- GPT-5 Nano is default for cost efficiency ($0.05 input vs $0.25 for Mini)
- Context window is 400K tokens for both models (plenty for transcription)
- Temperature set to 0.3 for consistency
- Buffer size already optimized at 4096
- Liquid Glass 2026 design must be maintained

---

## Next Steps
1. Research actual GPT-5 API model names from OpenAI
2. Update model selection in AudioRecorder
3. Create SettingsTabView in Dashboard
4. Add comprehensive error handling
5. Test with BlackHole aggregate device
