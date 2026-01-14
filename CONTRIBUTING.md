# Contributing to Nota

Thank you for your interest in contributing to Nota! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment for all contributors

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/yourusername/nota/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - macOS version and Nota version
   - Relevant logs or screenshots

### Suggesting Features

1. Check [Discussions](https://github.com/yourusername/nota/discussions) for similar ideas
2. Create a new discussion or issue with:
   - Clear description of the feature
   - Use cases and benefits
   - Potential implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the guidelines below
4. Test thoroughly
5. Commit with clear messages: `git commit -m "Add feature: description"`
6. Push to your fork: `git push origin feature/your-feature-name`
7. Open a Pull Request with:
   - Clear title and description
   - Reference to related issues
   - Screenshots/videos if UI changes

## Development Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and concise

### Code Structure

```swift
// Good: Clear, descriptive names
func startRecordingSession() {
    guard hasPermissions() else { return }
    audioRecorder.start()
}

// Bad: Unclear, abbreviated names
func strtRec() {
    if !perm { return }
    ar.st()
}
```

### Design Language

- Follow Apple's Liquid Glass 2026 design guidelines
- Maintain consistency with existing UI
- Use SwiftUI best practices
- Support Dark Mode

### Testing

- Test on multiple macOS versions (13.0+)
- Verify microphone permissions work correctly
- Test with different audio devices
- Check memory usage and performance

### Documentation

- Update README.md for user-facing changes
- Add inline code comments for complex logic
- Update CHANGELOG.md with your changes
- Include setup instructions if needed

## Project Structure

```
Nota-Swift/
├── Sources/
│   ├── main.swift              # App entry point
│   ├── AudioRecorder.swift     # Audio recording logic
│   ├── DashboardWindow.swift   # Main dashboard UI
│   ├── MiniWindowController.swift  # Mini window UI
│   ├── StatusBarController.swift   # Menu bar icon
│   └── DataModels.swift        # Data structures
├── icons/                      # App icons
├── Package.swift               # Swift package config
├── build.sh                    # Build script
├── create_app_bundle.sh        # App bundle creation
└── create_dmg.sh              # DMG creation
```

## Building from Source

```bash
# Clone repository
git clone https://github.com/yourusername/nota.git
cd nota/Nota-Swift

# Build debug version
swift build

# Build release version
swift build -c release

# Create app bundle
./create_app_bundle.sh

# Run the app
open Nota.app
```

## Security Guidelines

### Critical Rules

- **NEVER commit API keys** or secrets
- **NEVER commit personal data** (emails, names, addresses)
- **ALWAYS use UserDefaults** for user settings
- **ALWAYS store data locally** (no external analytics)

### Before Committing

1. Check for API keys: `git diff | grep -i "sk-"`
2. Check for emails: `git diff | grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"`
3. Review all changes carefully
4. Run security check: `./scripts/security_check.sh` (if available)

## Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

### Examples

```
feat: Add GPT-5 Nano model support

- Added gpt-5-nano to model selection
- Updated API calls to use new model
- Added cost information to UI

Closes #123
```

```
fix: Resolve audio device synchronization issue

- Fixed AudioRecorder instance sharing
- Updated Dashboard and MiniWindow to use shared instance
- Added proper initialization in AppDelegate

Fixes #456
```

## Release Process

1. Update version in `Package.swift`
2. Update `CHANGELOG.md`
3. Create git tag: `git tag v2.2.0`
4. Build release: `./create_app_bundle.sh`
5. Create DMG: `./create_dmg.sh`
6. Test DMG thoroughly
7. Push tag: `git push origin v2.2.0`
8. Create GitHub release with DMG

## Questions?

- Open a [Discussion](https://github.com/yourusername/nota/discussions)
- Check existing [Issues](https://github.com/yourusername/nota/issues)
- Read the [README](README.md)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
