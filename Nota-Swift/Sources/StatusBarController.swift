import AppKit
import SwiftUI

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    
    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        super.init()
        
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        if let button = statusItem.button {
            print("🎨 Setting up status bar icon...")
            
            // Try to load tray icon from bundle resources
            var image: NSImage?
            
            // Try different icon sizes for best quality
            if let bundlePath = Bundle.main.resourcePath {
                let iconPaths = [
                    "\(bundlePath)/tray-18x18.png",
                    "\(bundlePath)/tray-22x22.png",
                    "\(bundlePath)/tray-icon.png"
                ]
                
                for iconPath in iconPaths {
                    if let loadedImage = NSImage(contentsOfFile: iconPath) {
                        image = loadedImage
                        print("✅ Loaded tray icon from: \(iconPath)")
                        break
                    }
                }
            }
            
            // Fallback: try to load from icons directory (development mode)
            if image == nil {
                let iconPaths = [
                    "Nota-Swift/icons/tray-18x18.png",
                    "icons/tray-18x18.png",
                    "Nota-Swift/icons/tray-icon.png",
                    "icons/tray-icon.png"
                ]
                
                for iconPath in iconPaths {
                    if let loadedImage = NSImage(contentsOfFile: iconPath) {
                        image = loadedImage
                        print("✅ Loaded tray icon from development path: \(iconPath)")
                        break
                    }
                }
            }
            
            // Final fallback: use SF Symbol
            if image == nil {
                print("⚠️ Could not load tray icon file, using SF Symbol fallback")
                image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Nota")
            }
            
            // Configure the image
            if let finalImage = image {
                finalImage.isTemplate = true // Adapts to dark/light mode
                finalImage.size = NSSize(width: 18, height: 18)
                button.image = finalImage
                print("✅ Tray icon configured successfully")
            }
            
            // Make the entire button clickable
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Nota - AI Meeting Recorder"
        }
    }
    
    private func setupPopover() {
        // Popover no longer needed - we go straight to mini window
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click - show simple menu
            showContextMenu()
        } else {
            // Left click - toggle mini window directly
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.toggleMiniWindow()
            }
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // Check for Updates
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        updateItem.isEnabled = true
        menu.addItem(updateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Nota", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        menu.addItem(quitItem)
        
        // Show menu properly
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        
        // Clear menu after showing to allow left-click
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.statusItem.menu = nil
        }
    }
    
    @objc private func checkForUpdates() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.updateChecker?.checkForUpdates(silent: false)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

struct StatusBarPopoverView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with enhanced liquid glass effect
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                    
                    Text("Nota")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(.regularMaterial)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                }
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(showingSettings ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingSettings)
            }
            
            // Status indicator with enhanced liquid glass pill
            HStack {
                Circle()
                    .fill(audioRecorder.isRecording ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                    .scaleEffect(audioRecorder.isRecording ? 1.2 : 1.0)
                    .opacity(audioRecorder.isRecording ? 1.0 : 0.7)
                    .shadow(
                        color: audioRecorder.isRecording ? .red.opacity(0.5) : .green.opacity(0.3),
                        radius: audioRecorder.isRecording ? 4 : 2,
                        x: 0,
                        y: 0
                    )
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: audioRecorder.isRecording)
                
                Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .overlay {
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            
            // Transcript preview with enhanced liquid glass container
            ScrollView {
                Text(audioRecorder.transcript.isEmpty ? "Transcript will appear here..." : audioRecorder.transcript)
                    .font(.caption)
                    .foregroundStyle(audioRecorder.transcript.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(height: 80)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
            }
            
            // Control buttons with enhanced liquid glass effect
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if audioRecorder.isRecording {
                            audioRecorder.stopRecording()
                        } else {
                            audioRecorder.startRecording()
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(audioRecorder.isRecording ? "Stop" : "Record")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: audioRecorder.isRecording ? 
                                        [Color.red.opacity(0.9), Color.red.opacity(0.7)] :
                                        [Color.blue.opacity(0.9), Color.blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .shadow(
                                color: audioRecorder.isRecording ? .red.opacity(0.3) : .blue.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    }
                    .scaleEffect(audioRecorder.isRecording ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioRecorder.isRecording)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("Dashboard") {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.showDashboard()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(20)
        .background {
            // Enhanced liquid glass background with environmental adaptation
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @AppStorage("openaiKey") private var openaiKey = ""
    @AppStorage("selectedModel") private var selectedModel = "gpt-5-nano"
    @AppStorage("outputLanguage") private var outputLanguage = "auto"
    @AppStorage("inputDeviceId") private var inputDeviceId = "default"
    @StateObject private var audioRecorder = AudioRecorder()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with enhanced liquid glass styling
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.bottom, 8)
                
                // Language Settings Section with enhanced liquid glass
                settingsSection(
                    title: "Language & Recognition",
                    icon: "globe",
                    color: .green
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        settingsRow(title: "Output Language", description: "Speech recognition and AI analysis language") {
                            Picker("Language", selection: $outputLanguage) {
                                ForEach(audioRecorder.getSupportedLanguages(), id: \.code) { language in
                                    Text(language.name).tag(language.code)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: outputLanguage) { _ in
                                audioRecorder.updateSettings()
                            }
                        }
                    }
                }
                
                // API Configuration Section with enhanced liquid glass
                settingsSection(
                    title: "API Configuration",
                    icon: "key.fill",
                    color: .orange
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        settingsRow(title: "OpenAI API Key", description: "Get your key from platform.openai.com") {
                            SecureField("sk-proj-...", text: $openaiKey)
                                .textFieldStyle(EnhancedGlassTextFieldStyle())
                        }
                        
                        settingsRow(title: "AI Model", description: "Choose model for final analysis") {
                            Picker("Model", selection: $selectedModel) {
                                Text("GPT-5 Nano ($0.05/$0.40) - Recommended").tag("gpt-5-nano")
                                Text("GPT-5 Mini ($0.25/$2.00)").tag("gpt-5-mini")
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
                
                // Audio Settings Section with enhanced liquid glass
                settingsSection(
                    title: "Audio Input",
                    icon: "waveform",
                    color: .purple
                ) {
                    settingsRow(title: "Input Device", description: "Select your audio input source") {
                        Picker("Device", selection: $inputDeviceId) {
                            Text("Default").tag("default")
                            ForEach(audioRecorder.availableDevices, id: \.id) { device in
                                Text(device.name).tag(device.id)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: inputDeviceId) { _ in
                            audioRecorder.updateSettings()
                        }
                    }
                }
                
                // Tips Section with enhanced liquid glass
                settingsSection(
                    title: "Tips & Shortcuts",
                    icon: "lightbulb.fill",
                    color: .yellow
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        tipRow(icon: "command", text: "Press CMD+\\ to show/hide mini window")
                        tipRow(icon: "mic.fill", text: "Use BlackHole for system audio capture")
                        tipRow(icon: "globe", text: "Auto language detection uses system language")
                        tipRow(icon: "brain.head.profile", text: "AI insights appear during longer recordings")
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 500, height: 600)
        .background {
            // Enhanced liquid glass background with depth
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 12)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - Helper Views with Enhanced Liquid Glass
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)
                    .background {
                        Circle()
                            .fill(color.opacity(0.15))
                            .overlay {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                color.opacity(0.4),
                                                color.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            }
                            .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            content()
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private func settingsRow<Content: View>(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            content()
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enhanced Glass Text Field Style
struct EnhancedGlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 13, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
    }
}

