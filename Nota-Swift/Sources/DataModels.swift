import Foundation

// MARK: - Core Data Models
struct Project: Identifiable, Codable {
    var id = UUID()
    var name: String
    var keywords: [String]
    var color: String
    var createdAt: Date
    
    init(name: String, keywords: [String] = [], color: String = "blue") {
        self.name = name
        self.keywords = keywords
        self.color = color
        self.createdAt = Date()
    }
}

struct Recording: Identifiable, Codable {
    var id = UUID()
    var title: String
    var transcript: String
    var summary: String
    var tasks: [Task]
    var keywords: [String]
    var projectId: UUID?
    var language: String
    var duration: TimeInterval
    var createdAt: Date
    
    init(title: String, transcript: String, summary: String = "", tasks: [Task] = [], keywords: [String] = [], projectId: UUID? = nil, language: String = "en", duration: TimeInterval = 0) {
        self.title = title
        self.transcript = transcript
        self.summary = summary
        self.tasks = tasks
        self.keywords = keywords
        self.projectId = projectId
        self.language = language
        self.duration = duration
        self.createdAt = Date()
    }
}

struct Task: Identifiable, Codable {
    var id = UUID()
    var description: String
    var priority: TaskPriority
    var isCompleted: Bool
    var dueDate: Date?
    
    init(description: String, priority: TaskPriority = .medium, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.description = description
        self.priority = priority
        self.isCompleted = isCompleted
        self.dueDate = dueDate
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

// MARK: - Data Manager
class DataManager: ObservableObject {
    @Published var projects: [Project] = []
    @Published var recordings: [Recording] = []
    
    private let projectsKey = "nota_projects"
    private let recordingsKey = "nota_recordings"
    
    init() {
        loadData()
    }
    
    // MARK: - Projects
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        // Remove project assignment from recordings
        for i in recordings.indices {
            if recordings[i].projectId == project.id {
                recordings[i].projectId = nil
            }
        }
        saveProjects()
        saveRecordings()
    }
    
    // MARK: - Recordings
    func addRecording(_ recording: Recording) {
        recordings.insert(recording, at: 0) // Add to beginning
        saveRecordings()
    }
    
    func updateRecording(_ recording: Recording) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
            saveRecordings()
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
    
    func assignRecordingToProject(_ recordingId: UUID, projectId: UUID?) {
        if let index = recordings.firstIndex(where: { $0.id == recordingId }) {
            recordings[index].projectId = projectId
            saveRecordings()
        }
    }
    
    // MARK: - Auto Project Assignment
    func findMatchingProject(for keywords: [String], transcript: String) -> UUID? {
        let searchText = (transcript + " " + keywords.joined(separator: " ")).lowercased()
        
        for project in projects {
            for keyword in project.keywords {
                if searchText.contains(keyword.lowercased()) {
                    return project.id
                }
            }
        }
        return nil
    }
    
    // MARK: - Persistence
    private func loadData() {
        loadProjects()
        loadRecordings()
    }
    
    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }
    
    private func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: projectsKey)
        }
    }
    
    private func loadRecordings() {
        if let data = UserDefaults.standard.data(forKey: recordingsKey),
           let decoded = try? JSONDecoder().decode([Recording].self, from: data) {
            recordings = decoded
        }
    }
    
    private func saveRecordings() {
        if let encoded = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(encoded, forKey: recordingsKey)
        }
    }
    
    // MARK: - Filtering
    func recordings(for project: Project) -> [Recording] {
        return recordings.filter { $0.projectId == project.id }
    }
    
    func unassignedRecordings() -> [Recording] {
        return recordings.filter { $0.projectId == nil }
    }
}