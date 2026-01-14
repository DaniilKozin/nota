import AppKit
import SwiftUI
import AVFoundation
import Speech
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var miniWindow: MiniWindowController?
    var dashboardWindow: DashboardWindowController?
    var dataManager = DataManager()
    var audioRecorder: AudioRecorder?
    var updateChecker: UpdateChecker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - make it menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        print("🚀 Starting Nota...")
        
        // Create shared audio recorder with data manager
        audioRecorder = AudioRecorder()
        audioRecorder?.setDataManager(dataManager)
        print("✅ Audio recorder created with DataManager")
        
        // Setup status bar first
        statusBarController = StatusBarController()
        print("✅ Status bar controller created")
        
        // Setup mini window (but don't show it immediately)
        miniWindow = MiniWindowController()
        miniWindow?.setAudioRecorder(audioRecorder!)
        print("✅ Mini window controller created")
        
        // Setup global hotkey CMD+\
        setupGlobalHotkey()
        
        // Hide main menu
        NSApp.mainMenu = nil
        
        // Setup update checker
        updateChecker = UpdateChecker()
        updateChecker?.checkOnLaunch()
        
        print("✅ Nota started successfully!")
        print("🔥 Use CMD+\\ to show/hide mini window")
    }
    
    private func setupGlobalHotkey() {
        print("🔧 Setting up global hotkey...")
        
        // Check accessibility permissions WITHOUT prompting
        let accessibilityEnabled = AXIsProcessTrusted()
        
        if !accessibilityEnabled {
            print("⚠️ Accessibility permissions not granted")
            print("💡 Global hotkey (CMD+\\) will not work until you grant Accessibility permission")
            print("💡 Go to: System Settings > Privacy & Security > Accessibility")
            // Don't prompt automatically - let user decide if they want hotkeys
        } else {
            print("✅ Accessibility permissions granted - hotkeys enabled")
        }
        
        // Use NSEvent monitoring for global hotkey (CMD+\)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // Check for CMD+\ (try multiple key codes)
            // 42 = backslash on US keyboard, 43 = alternative
            if (event.keyCode == 42 || event.keyCode == 43 || event.keyCode == 50) && event.modifierFlags.contains(.command) {
                print("🎯 Global hotkey detected! keyCode=\(event.keyCode)")
                DispatchQueue.main.async {
                    self.toggleMiniWindow()
                }
            }
        }
        
        // Also monitor local events when app is active
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if (event.keyCode == 42 || event.keyCode == 43 || event.keyCode == 50) && event.modifierFlags.contains(.command) {
                print("🎯 Local hotkey detected! keyCode=\(event.keyCode)")
                DispatchQueue.main.async {
                    self.toggleMiniWindow()
                }
                return nil // Consume the event
            }
            return event
        }
        
        print("✅ Global hotkey CMD+\\ registered")
        if !accessibilityEnabled {
            print("⚠️ Hotkey will only work when app is active (Accessibility permission needed for global hotkey)")
        }
    }
    
    func toggleMiniWindow() {
        print("🔄 toggleMiniWindow() called")
        
        guard let miniWindow = miniWindow else { 
            print("❌ Mini window controller not available")
            return 
        }
        
        if let window = miniWindow.window, window.isVisible {
            window.orderOut(nil)
            print("🙈 Mini window hidden")
        } else {
            print("📱 Showing mini window...")
            miniWindow.showWindow()
            print("👁️ Mini window shown")
        }
    }
    
    func showDashboard() {
        if dashboardWindow == nil {
            dashboardWindow = DashboardWindowController(dataManager: dataManager, audioRecorder: audioRecorder!)
        }
        dashboardWindow?.showWindow()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Simple main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()