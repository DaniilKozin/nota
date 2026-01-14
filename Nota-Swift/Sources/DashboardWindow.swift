import AppKit
import SwiftUI

class DashboardWindowController: NSObject {
    var window: NSWindow?
    private let dataManager: DataManager
    private let audioRecorder: AudioRecorder
    
    init(dataManager: DataManager, audioRecorder: AudioRecorder) {
        self.dataManager = dataManager
        self.audioRecorder = audioRecorder
        super.init()
    }
    
    func showWindow() {
        if window == nil {
            createDashboardWindow()
        }
        
        window?.makeKeyAndOrderFront(nil)
        window?.center()
    }
    
    private func createDashboardWindow() {
        let contentView = DashboardView(dataManager: dataManager, audioRecorder: audioRecorder)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Nota Dashboard"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.backgroundColor = NSColor.windowBackgroundColor
        window?.minSize = NSSize(width: 800, height: 600)
        window?.setFrameAutosaveName("DashboardWindow")
    }
}

struct DashboardView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var audioRecorder: AudioRecorder
    @State private var selectedTab = 0
    @State private var showingNewProject = false
    @State private var selectedRecording: Recording?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Nota Dashboard")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Recording status
                HStack(spacing: 8) {
                    Circle()
                        .fill(audioRecorder.isRecording ? Color.red : Color.green)
                        .frame(width: 8, height: 8)
                        .opacity(audioRecorder.isRecording ? 1.0 : 0.6)
                    
                    Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    if audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        Text(audioRecorder.isRecording ? "Stop" : "Record")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(audioRecorder.isRecording ? Color.red : Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            Divider()
            
            // Tab view
            TabView(selection: $selectedTab) {
                // Recording History Tab
                RecordingHistoryView(audioRecorder: audioRecorder)
                    .tabItem {
                        Image(systemName: "waveform")
                        Text("History")
                    }
                    .tag(0)
                
                // Projects Tab
                ProjectsView(dataManager: dataManager, showingNewProject: $showingNewProject)
                    .tabItem {
                        Image(systemName: "folder.fill")
                        Text("Projects")
                    }
                    .tag(1)
                
                // Analytics Tab
                AnalyticsView(dataManager: dataManager)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Analytics")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsTabView(audioRecorder: audioRecorder)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(3)
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectView(dataManager: dataManager)
        }
        .sheet(item: $selectedRecording) { recording in
            RecordingDetailView(recording: recording, dataManager: dataManager)
        }
    }
}

// MARK: - Projects View
struct ProjectsView: View {
    @ObservedObject var dataManager: DataManager
    @Binding var showingNewProject: Bool
    @State private var selectedProject: Project?
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Projects")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("New Project") {
                    showingNewProject = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Projects grid
            if dataManager.projects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Projects Yet")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Create your first project to organize recordings by topic or company")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Create Project") {
                        showingNewProject = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 280))
                    ], spacing: 16) {
                        ForEach(dataManager.projects) { project in
                            ProjectCard(project: project, dataManager: dataManager)
                                .onTapGesture {
                                    selectedProject = project
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project, dataManager: dataManager)
        }
    }
}

struct ProjectCard: View {
    let project: Project
    @ObservedObject var dataManager: DataManager
    
    var recordingsCount: Int {
        dataManager.recordings(for: project).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(project.color))
                    .frame(width: 12, height: 12)
                
                Text(project.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(recordingsCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if !project.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(project.keywords.prefix(3), id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if project.keywords.count > 3 {
                            Text("+\(project.keywords.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Text("Created \(project.createdAt, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - History View
struct HistoryView: View {
    @ObservedObject var dataManager: DataManager
    @Binding var selectedRecording: Recording?
    @State private var searchText = ""
    @State private var selectedProjectFilter: UUID?
    
    var filteredRecordings: [Recording] {
        var recordings = dataManager.recordings
        
        if let projectId = selectedProjectFilter {
            recordings = recordings.filter { $0.projectId == projectId }
        }
        
        if !searchText.isEmpty {
            recordings = recordings.filter { recording in
                recording.title.localizedCaseInsensitiveContains(searchText) ||
                recording.transcript.localizedCaseInsensitiveContains(searchText) ||
                recording.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return recordings
    }
    
    var body: some View {
        VStack {
            // Header with search and filters
            VStack(spacing: 12) {
                HStack {
                    Text("Recording History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(filteredRecordings.count) recordings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    TextField("Search recordings...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Project", selection: $selectedProjectFilter) {
                        Text("All Projects").tag(UUID?.none)
                        Text("Unassigned").tag(UUID?.some(UUID()))
                        
                        ForEach(dataManager.projects) { project in
                            Text(project.name).tag(UUID?.some(project.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                }
            }
            .padding()
            
            Divider()
            
            // Recordings list
            if filteredRecordings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No Recordings Yet" : "No Matching Recordings")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text(searchText.isEmpty ? "Start recording to see your meeting history here" : "Try adjusting your search or filters")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredRecordings) { recording in
                    RecordingRow(recording: recording, dataManager: dataManager)
                        .onTapGesture {
                            selectedRecording = recording
                        }
                }
            }
        }
    }
}

struct RecordingRow: View {
    let recording: Recording
    @ObservedObject var dataManager: DataManager
    
    var project: Project? {
        guard let projectId = recording.projectId else { return nil }
        return dataManager.projects.first { $0.id == projectId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if let project = project {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(project.color))
                            .frame(width: 8, height: 8)
                        Text(project.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(recording.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !recording.summary.isEmpty {
                Text(recording.summary)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("\(Int(recording.duration / 60)):\(String(format: "%02d", Int(recording.duration) % 60))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(recording.language.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !recording.tasks.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(recording.tasks.count) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @ObservedObject var dataManager: DataManager
    
    var totalRecordings: Int {
        dataManager.recordings.count
    }
    
    var totalDuration: TimeInterval {
        dataManager.recordings.reduce(0) { $0 + $1.duration }
    }
    
    var totalTasks: Int {
        dataManager.recordings.reduce(0) { $0 + $1.tasks.count }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Analytics")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                // Stats cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(title: "Total Recordings", value: "\(totalRecordings)", icon: "waveform")
                    StatCard(title: "Total Duration", value: formatDuration(totalDuration), icon: "clock")
                    StatCard(title: "Tasks Created", value: "\(totalTasks)", icon: "checkmark.circle")
                }
                .padding(.horizontal)
                
                // Projects breakdown
                if !dataManager.projects.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Projects Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(dataManager.projects) { project in
                            let recordingsCount = dataManager.recordings(for: project).count
                            
                            HStack {
                                Circle()
                                    .fill(Color(project.color))
                                    .frame(width: 12, height: 12)
                                
                                Text(project.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(recordingsCount) recordings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - New Project View
struct NewProjectView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var keywords = ""
    @State private var selectedColor = "blue"
    
    let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Project")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Project Name")
                    .font(.headline)
                TextField("Enter project name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Keywords")
                    .font(.headline)
                TextField("company, meeting, project (comma separated)", text: $keywords)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Keywords help automatically assign recordings to this project")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.headline)
                
                HStack {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(Color(color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                Button("Create Project") {
                    let keywordArray = keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    let project = Project(name: name, keywords: keywordArray, color: selectedColor)
                    dataManager.addProject(project)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

// MARK: - Project Detail View
struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    var recordings: [Recording] {
        dataManager.recordings(for: project)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(project.color))
                    .frame(width: 20, height: 20)
                
                Text(project.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            if !project.keywords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keywords")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(project.keywords, id: \.self) { keyword in
                                Text(keyword)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Recordings (\(recordings.count))")
                    .font(.headline)
                
                if recordings.isEmpty {
                    Text("No recordings assigned to this project yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(recordings) { recording in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recording.title)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(recording.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(height: 200)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

// MARK: - Recording Detail View
struct RecordingDetailView: View {
    let recording: Recording
    @ObservedObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(recording.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                // Metadata
                HStack {
                    Text(recording.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(recording.duration / 60)):\(String(format: "%02d", Int(recording.duration) % 60))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(recording.language.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Summary
                if !recording.summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                        
                        Text(recording.summary)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                
                // Tasks
                if !recording.tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tasks (\(recording.tasks.count))")
                            .font(.headline)
                        
                        ForEach(recording.tasks) { task in
                            HStack {
                                Circle()
                                    .fill(Color(task.priority.color))
                                    .frame(width: 8, height: 8)
                                
                                Text(task.description)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text(task.priority.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Full transcript
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Transcript")
                        .font(.headline)
                    
                    ScrollView {
                        Text(recording.transcript)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}


// MARK: - Recording History View
struct RecordingHistoryView: View {
    @ObservedObject var audioRecorder: AudioRecorder
    @State private var recordings: [RecordingSession] = []
    @State private var selectedSession: RecordingSession?
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: RecordingSession?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recording History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(recordings.count) recordings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !recordings.isEmpty {
                    Button("Clear All") {
                        showingDeleteAlert = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            Divider()
            
            if recordings.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Recordings Yet")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Start recording to see your transcription history here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Recordings list
                List(recordings) { session in
                    RecordingSessionRow(
                        session: session,
                        onContinue: {
                            let recorder = audioRecorder
                            recorder.continueFromSession(session)
                        },
                        onDelete: {
                            sessionToDelete = session
                            showingDeleteAlert = true
                        },
                        onSelect: {
                            selectedSession = session
                        }
                    )
                }
            }
        }
        .onAppear {
            loadRecordings()
        }
        .alert("Delete Recording", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                let recorder = audioRecorder
                if let session = sessionToDelete {
                    recorder.deleteSession(session.id)
                    loadRecordings()
                    sessionToDelete = nil
                } else {
                    recorder.clearAllSessions()
                    loadRecordings()
                }
            }
        } message: {
            if sessionToDelete != nil {
                Text("Are you sure you want to delete this recording?")
            } else {
                Text("Are you sure you want to delete all recordings?")
            }
        }
        .sheet(item: $selectedSession) { session in
            RecordingSessionDetailView(session: session, audioRecorder: audioRecorder)
        }
    }
    
    private func loadRecordings() {
        let recorder = audioRecorder
        recordings = recorder.getSavedRecordings()
    }
}

// MARK: - Recording Session Row
struct RecordingSessionRow: View {
    let session: RecordingSession
    let onContinue: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(session.startTime, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.language.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(formatDuration(session.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                Text(session.transcript.isEmpty ? "No transcript" : session.transcript)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(session.transcript.isEmpty ? .secondary : .primary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onContinue) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Continue recording")
                
                Button(action: onSelect) {
                    Image(systemName: "eye.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
                .help("View details")
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete recording")
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Recording Session Detail View
struct RecordingSessionDetailView: View {
    let session: RecordingSession
    @ObservedObject var audioRecorder: AudioRecorder
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recording Details")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(session.startTime, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                // Metadata
                HStack(spacing: 20) {
                    MetadataItem(icon: "clock", label: "Duration", value: formatDuration(session.duration))
                    MetadataItem(icon: "globe", label: "Language", value: session.language)
                    MetadataItem(icon: "text.alignleft", label: "Characters", value: "\(session.transcript.count)")
                }
                
                Divider()
                
                // Transcript
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transcript")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(session.transcript, forType: .string)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    ScrollView {
                        Text(session.transcript.isEmpty ? "No transcript available" : session.transcript)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // Insights
                if !session.insights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Insights")
                            .font(.headline)
                        
                        ScrollView {
                            Text(session.insights)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(height: 150)
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: {
                        let recorder = audioRecorder
                        recorder.continueFromSession(session)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Continue Recording")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        let recorder = audioRecorder
                        recorder.deleteSession(session.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MetadataItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}


// MARK: - Settings Tab View
struct SettingsTabView: View {
    @ObservedObject var audioRecorder: AudioRecorder
    @AppStorage("openaiKey") private var openaiKey = ""
    @AppStorage("deepgramKey") private var deepgramKey = ""
    @AppStorage("selectedModel") private var selectedModel = "gpt-5-nano"
    @AppStorage("outputLanguage") private var outputLanguage = "auto"
    @AppStorage("inputDeviceId") private var inputDeviceId = "default"
    @AppStorage("globalHotkey") private var globalHotkey = "CMD+\\"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            // Content
            Form {
                // API Keys Section
                Section(header: Text("API Configuration").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.subheadline)
                        SecureField("sk-proj-...", text: $openaiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deepgram API Key (Optional)")
                            .font(.subheadline)
                        SecureField("Optional", text: $deepgramKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Picker("AI Model", selection: $selectedModel) {
                        Text("GPT-5 Nano (Recommended)").tag("gpt-5-nano")
                        Text("GPT-5 Mini").tag("gpt-5-mini")
                    }
                }
                
                // Audio Section
                Section(header: Text("Audio & Language").font(.headline)) {
                    Picker("Input Device", selection: $inputDeviceId) {
                        Text("Default").tag("default")
                        ForEach(audioRecorder.availableDevices, id: \.id) { device in
                            Text(device.name).tag(device.id)
                        }
                    }
                    .onChange(of: inputDeviceId) { _ in
                        audioRecorder.updateSettings()
                    }
                    
                    Picker("Language", selection: $outputLanguage) {
                        ForEach(audioRecorder.getSupportedLanguages(), id: \.code) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .onChange(of: outputLanguage) { _ in
                        audioRecorder.updateSettings()
                    }
                    
                    Button("Refresh Devices") {
                        audioRecorder.discoverAudioDevices()
                    }
                }
                
                // Shortcuts Section
                Section(header: Text("Keyboard Shortcuts").font(.headline)) {
                    HStack {
                        Text("Toggle Mini Window:")
                        Spacer()
                        Text(globalHotkey)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    Text("Requires Accessibility permission in System Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // About Section
                Section(header: Text("About").font(.headline)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Check for Updates", destination: URL(string: "https://github.com/DaniilKozin/nota/releases")!)
                    Link("GitHub Repository", destination: URL(string: "https://github.com/DaniilKozin/nota")!)
                    Link("Report Issue", destination: URL(string: "https://github.com/DaniilKozin/nota/issues")!)
                    Link("Documentation", destination: URL(string: "https://github.com/DaniilKozin/nota/blob/main/AUDIO_SETUP_GUIDE.md")!)
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal)
        }
        .onAppear {
            audioRecorder.discoverAudioDevices()
        }
    }
}
