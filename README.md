# Team Scheduler

A Flutter application for team scheduling and task management.

## Prerequisites

- Flutter SDK (version 3.8.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Git

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd scheduler
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Setup

### Android Setup
- Ensure Android SDK is installed
- Connect an Android device or start an emulator
- Run `flutter doctor` to verify setup

### iOS Setup (macOS only)
- Install Xcode
- Run `flutter doctor` to verify setup
- Connect an iOS device or start the iOS simulator

## Dependencies

- `supabase_flutter`: Backend services
- `flutter_bloc`: State management
- `image_picker`: Image selection functionality
- `shared_preferences`: Local data storage
- `intl`: Internationalization support

## Project Structure

```
lib/
├── cubits/          # State management
├── models/          # Data models
├── pages/           # UI screens
├── services/        # API services
└── main.dart        # App entry point
```

## Running Tests

```bash
flutter test
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```