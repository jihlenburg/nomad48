# CLAUDE.md - Project Instructions for NOMAD48

This file contains project-specific instructions and context for Claude Code to work effectively with the NOMAD48 mobile application.

## Task Management Workflow

### Required Files
Maintain these files in the project root to track progress and changes:

1. **TODO.md** - Active task list
   - Location: `/Users/jihlenburg/nomad48/TODO.md`
   - Contains all open tasks, planned features, and pending work
   - Updated whenever new tasks are identified or completed

2. **CHANGELOG.md** - Project logbook
   - Location: `/Users/jihlenburg/nomad48/CHANGELOG.md`
   - Chronological record of what was done and when
   - Updated after completing significant work
   - Helps understand recent changes and retrace decisions

### Workflow Rules

#### When Starting Work
1. **Always read TODO.md first** to understand current tasks
2. Check CHANGELOG.md to see recent changes
3. Update TODO.md if new tasks are discovered during planning

#### During Development
1. Mark tasks as "In Progress" in TODO.md when starting work
2. Add subtasks or notes as work progresses
3. Keep TODO.md updated with any blockers or dependencies

#### After Completing Work
1. **Update TODO.md**:
   - Mark completed tasks with ✅ or move to "Completed" section
   - Add any new tasks discovered during implementation
   - Update task status and notes

2. **Update CHANGELOG.md**:
   - Add entry with date and summary of what was done
   - Include file paths for major changes
   - Note any breaking changes or important decisions
   - Reference related TODO items if applicable

#### In Planning Mode
1. Create detailed task list in TODO.md
2. Break down features into actionable tasks
3. Note dependencies and order of operations
4. After exiting planning mode, ensure TODO.md reflects the plan

### Task Format in TODO.md

Use this structure:
```markdown
## Active Tasks

### High Priority
- [ ] Task description (file paths if known)
  - Details or subtasks
  - Blocker: if blocked by something

### In Progress
- [→] Task being worked on
  - Started: YYYY-MM-DD
  - Current status

### Low Priority
- [ ] Future task

## Completed
- [✅] Completed task (YYYY-MM-DD)
```

### Changelog Format

Use this structure:
```markdown
## [Date: YYYY-MM-DD]

### Added
- Feature or file added

### Changed
- What was modified and why

### Fixed
- Bugs or issues resolved

### Notes
- Important decisions or context
```

## Project Overview

NOMAD48 is a Flutter-based mobile application for interacting with NOMAD48 Bluetooth Low Energy (BLE) devices and NFC tags. The app is designed for both iOS and Android platforms.

## Technology Stack

- **Framework**: Flutter 3.38.9+
- **Language**: Dart 3.10.8+
- **Local Storage**: Hive (device cache, expansion state)
- **BLE Library**: flutter_blue_plus
- **NFC Library**: nfc_manager
- **Platforms**: iOS (11.0+, iPhone 7+ for NFC) and Android (API 21+)

## Code Style and Conventions

### Dart/Flutter Standards
- Follow official Dart style guide and Flutter best practices
- Use `flutter analyze` before committing code
- Keep widgets small and focused (single responsibility)
- Prefer composition over inheritance
- Use const constructors wherever possible for performance

### File Organization
- Place screen-level widgets in `lib/screens/`
- Place extracted/reusable widgets in `lib/widgets/`
- Place business logic and services in `lib/services/`
- Place data models in `lib/models/`
- Place utilities in `lib/utils/`
- Place app-wide constants in `lib/constants/`

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `lowerCamelCase` (per Dart style guide / flutter analyze)
- Private members: prefix with underscore `_privateMethod`

## BLE Development Guidelines

### flutter_blue_plus Usage
- Always check Bluetooth adapter state before scanning
- Request necessary permissions before BLE operations
- Dispose of stream subscriptions properly
- Handle connection timeouts gracefully
- Implement reconnection logic for unstable connections

### NOMAD48 Device Specifics
- Document any device-specific UUIDs, characteristics, or services
- Add device protocol documentation as it becomes available
- Keep BLE communication code modular and testable

## NFC Development Guidelines

### nfc_manager Usage
- Always check NFC availability before starting operations
- Stop NFC sessions properly when done or cancelled
- Handle NDEF message parsing carefully
- Validate tag writability before writing
- Check tag capacity before writing large messages

### NFC Best Practices
- Provide clear user feedback during NFC operations
- Use try-catch blocks for all NFC operations
- Test with multiple tag types (NTAG, MifareClassic, etc.)
- Handle read-only tags gracefully
- Implement timeout handling for NFC sessions

## Testing Requirements

- Write unit tests for business logic and services
- Write widget tests for complex UI components
- Use mockito for mocking BLE operations in tests
- Run `flutter test` before submitting PRs
- Aim for meaningful test coverage, not just high percentages

## Platform-Specific Considerations

### iOS
- BLE requires location permissions due to iOS restrictions
- NFC only works on iPhone 7 and newer
- NFC requires entitlements configuration (Runner.entitlements)
- Test on physical devices (BLE and NFC don't work in simulator)
- CocoaPods must be installed and up-to-date
- Background BLE capabilities may need special configuration

### Android
- BLE permissions differ between Android 11 and 12+
- NFC requires hardware support and enabled in settings
- Intent filters configured for NFC tag discovery
- Test on multiple Android versions (especially 12+)
- Location services must be enabled for BLE scanning
- Consider different OEM Bluetooth and NFC implementations

## Build and Development Commands

### Common Commands
```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run with hot reload
flutter run --hot

# Clean build artifacts
flutter clean

# Run tests
flutter test

# Check for issues
flutter analyze

# Format code
dart format .
```

### iOS Specific
```bash
# Install pods
cd ios && pod install && cd ..

# Clean iOS build
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..
```

### Android Specific
```bash
# Clean Gradle cache
cd android && ./gradlew clean && cd ..
```

## Dependencies Management

### Adding New Dependencies
1. Add to `pubspec.yaml` under appropriate section
2. Run `flutter pub get`
3. For iOS, run `cd ios && pod install && cd ..` if native code is involved
4. Update this file if dependency introduces new patterns or requirements

### Current Key Dependencies
- `flutter_blue_plus`: BLE operations
- `nfc_manager`: NFC tag reading and writing
- `permission_handler`: Runtime permissions
- `hive` / `hive_flutter`: Local storage (device probe cache, expansion state)
- `simple_icons`: Brand SVG icons for manufacturer logos

## Versioning Policy

This project uses **semantic versioning** (`MAJOR.MINOR.PATCH+BUILD`) in `pubspec.yaml`, with a conservative approach to major bumps.

### Version Format: `0.MINOR.PATCH+BUILD`
- **MAJOR (0.x.x)**: Stays at `0` until the app is production-ready. Bump only when explicitly requested or for truly breaking architectural changes. Be very cautious with major version bumps.
- **MINOR (x.1.x)**: New features, significant UI changes, new screens, new device protocol support. Anything that adds meaningful new capability.
- **PATCH (x.x.1)**: Bug fixes, tweaks, refactors, performance improvements, logging changes, dependency updates. Anything that doesn't add new user-facing capability.
- **BUILD (+N)**: Increment on every release build. Reset to 1 when MINOR bumps.

### Rules
- **Default to PATCH** — if unsure whether a change is MINOR or PATCH, choose PATCH
- **Tag every MINOR bump** in git: `git tag v0.X.0`
- **Update version in `pubspec.yaml`** when completing work that warrants a bump
- **Update CHANGELOG.md** header to include the version number
- **Never bump MAJOR** without explicit user approval

### Current Version
- `0.1.0+1` — Initial feature-complete BLE scanner with device identification, sort stability, and RSSI hysteresis

## Git Workflow

- Follow conventional commits format
- Create feature branches from main
- Test thoroughly before creating PRs
- Update README.md if adding user-facing features
- Don't commit generated files or build artifacts

## Error Handling

- Use try-catch for BLE operations
- Provide user-friendly error messages
- Log errors appropriately (consider using logger package)
- Handle edge cases (Bluetooth off, no permissions, etc.)

## Performance Considerations

- Use const constructors to reduce rebuilds
- Dispose of resources (streams, controllers) properly
- Avoid unnecessary widget rebuilds (use Consumer wisely)
- Profile the app on real devices, not just emulators
- Monitor memory usage during long BLE sessions

## Security Considerations

- Never commit sensitive data (API keys, credentials)
- Validate all data received from BLE devices
- Implement appropriate error handling for malformed data
- Consider encryption for sensitive device communications

## Documentation

- Document complex BLE communication patterns
- Add inline comments for non-obvious code
- Update README.md when adding major features
- Document NOMAD48 device protocol as it's discovered
- Keep this CLAUDE.md file updated with new patterns

## When Working with Claude

### Before Making Changes
- **Read TODO.md** to understand current task priorities
- **Check CHANGELOG.md** for recent changes that might affect your work
- Read relevant code files first
- Understand the current architecture
- Check for existing patterns or utilities
- Consider cross-platform implications

### When Adding Features
- Check if feature is in TODO.md, mark as "In Progress"
- Follow the established project structure
- Maintain consistency with existing code style
- Add appropriate error handling
- Consider testing requirements
- Update documentation as needed
- **Update TODO.md** when complete
- **Add entry to CHANGELOG.md** with details of changes

### When Debugging
- Check CHANGELOG.md for recent changes that might have introduced issues
- Check BLE/NFC permissions first (common issue)
- Verify Bluetooth and NFC are enabled on device
- Check platform-specific logs (Xcode/Android Studio)
- Test on real hardware (BLE/NFC don't work on emulators)
- Use flutter_blue_plus debug logging if needed
- For NFC issues, test with known working tags first
- **Document solution in CHANGELOG.md** if fix is non-obvious

## Useful Resources

- [Flutter Docs](https://docs.flutter.dev/)
- [flutter_blue_plus Docs](https://pub.dev/packages/flutter_blue_plus)
- [nfc_manager Docs](https://pub.dev/packages/nfc_manager)
- [BLE Fundamentals](https://www.bluetooth.com/bluetooth-resources/intro-to-bluetooth-low-energy/)
- [NFC Forum](https://nfc-forum.org/)
- [NDEF Specification](https://nfc-forum.org/our-work/specification-releases/specifications/nfc-forum-technical-specifications/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

## Notes

- This is a GPL-3.0 licensed project
- Maintain compatibility with Flutter stable channel
- Test on both iOS and Android before major releases
- Keep dependencies up to date but test thoroughly after updates
- Use `rg` (ripgrep) instead of `grep` for all codebase searches
