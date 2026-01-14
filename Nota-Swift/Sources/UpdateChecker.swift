import Foundation
import AppKit

// Auto-update checker for Nota
// Checks GitHub releases for new versions

class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var downloadURL = ""
    @Published var releaseNotes = ""
    @Published var isChecking = false
    
    private let githubRepo = "daniilkozin/nota" // Change to your GitHub username
    private let currentVersion: String
    
    init() {
        // Get current version from bundle
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.0"
    }
    
    // Check for updates
    func checkForUpdates(silent: Bool = true) {
        guard !isChecking else { return }
        
        isChecking = true
        
        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else {
            isChecking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isChecking = false
            }
            
            if let error = error {
                print("❌ Update check failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received from GitHub")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.parseRelease(json, silent: silent)
                }
            } catch {
                print("❌ Failed to parse GitHub response: \(error)")
            }
        }.resume()
    }
    
    private func parseRelease(_ json: [String: Any], silent: Bool) {
        guard let tagName = json["tag_name"] as? String else {
            print("❌ No tag_name in release")
            return
        }
        
        // Remove 'v' prefix if present
        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        
        // Get download URL for DMG
        var dmgURL = ""
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let name = asset["name"] as? String,
                   name.hasSuffix(".dmg"),
                   let downloadUrl = asset["browser_download_url"] as? String {
                    dmgURL = downloadUrl
                    break
                }
            }
        }
        
        // Get release notes
        let notes = json["body"] as? String ?? ""
        
        DispatchQueue.main.async {
            self.latestVersion = version
            self.downloadURL = dmgURL
            self.releaseNotes = notes
            
            // Compare versions
            if self.isNewerVersion(version, than: self.currentVersion) {
                self.updateAvailable = true
                
                if !silent {
                    self.showUpdateDialog()
                }
                
                print("✅ Update available: v\(version)")
            } else {
                if !silent {
                    self.showNoUpdateDialog()
                }
                print("✅ Already on latest version: v\(self.currentVersion)")
            }
        }
    }
    
    // Compare semantic versions
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newComponents = new.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(newComponents.count, currentComponents.count) {
            let newValue = i < newComponents.count ? newComponents[i] : 0
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            
            if newValue > currentValue {
                return true
            } else if newValue < currentValue {
                return false
            }
        }
        
        return false
    }
    
    // Show update available dialog
    private func showUpdateDialog() {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = """
        A new version of Nota is available!
        
        Current version: v\(currentVersion)
        Latest version: v\(latestVersion)
        
        Would you like to download it now?
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "View Release Notes")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            // Download
            openDownloadPage()
        case .alertSecondButtonReturn:
            // View release notes
            openReleasePage()
        default:
            // Later
            break
        }
    }
    
    // Show no update dialog
    private func showNoUpdateDialog() {
        let alert = NSAlert()
        alert.messageText = "You're up to date!"
        alert.informativeText = "Nota v\(currentVersion) is the latest version."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // Open download page
    func openDownloadPage() {
        if !downloadURL.isEmpty, let url = URL(string: downloadURL) {
            NSWorkspace.shared.open(url)
        } else {
            openReleasePage()
        }
    }
    
    // Open release page
    func openReleasePage() {
        let urlString = "https://github.com/\(githubRepo)/releases/latest"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // Check on app launch (once per day)
    func checkOnLaunch() {
        let lastCheckKey = "lastUpdateCheck"
        let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
        let now = Date().timeIntervalSince1970
        
        // Check once per day (86400 seconds)
        if now - lastCheck > 86400 {
            UserDefaults.standard.set(now, forKey: lastCheckKey)
            checkForUpdates(silent: true)
        }
    }
}
