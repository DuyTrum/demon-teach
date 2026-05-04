# Demon Teach

An AI-powered multi-language learning mobile application built with Flutter that provides personalized, adaptive language learning experiences for English, Chinese, and Korean.

## 🌟 Features

- **Adaptive Learning**: Dynamic difficulty adjustment based on user performance
- **Spaced Repetition**: Smart review system using SM-2 algorithm
- **Micro-Learning**: Bite-sized lessons designed for 5-15 minute sessions
- **Offline-First**: All core learning functionality works offline with background synchronization
- **Multi-Language Support**: Learn English, Chinese, or Korean
- **Progress Tracking**: XP system, streaks, and achievements
- **Personalized Learning Paths**: Tailored to proficiency level and learning goals

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                 # Core utilities, constants, and errors
│   ├── constants/       # App-wide constants
│   ├── errors/          # Error handling and failures
│   ├── network/         # Network utilities
│   └── utils/           # Utility functions and helpers
├── presentation/        # UI Layer
│   ├── screens/        # App screens
│   ├── widgets/        # Reusable widgets
│   └── providers/      # Riverpod providers (state management)
├── domain/             # Business Logic Layer
│   ├── entities/       # Domain entities
│   ├── repositories/   # Repository interfaces
│   └── usecases/       # Use cases (business rules)
└── data/               # Data Layer
    ├── datasources/    # Local and remote data sources
    ├── models/         # Data models (DTOs)
    └── repositories/   # Repository implementations
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.24.3
- **State Management**: Riverpod
- **Local Database**: Drift (SQLite)
- **HTTP Client**: Dio
- **Audio**: just_audio, record
- **Routing**: go_router
- **Code Generation**: freezed, json_serializable

## 📋 Requirements

- Flutter SDK: ^3.5.3
- Dart SDK: ^3.5.3

## 🚀 Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/demon_teach.git
cd demon_teach
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

## 🧪 Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ⚠️ Web (limited functionality)
- ⚠️ Desktop (Windows, macOS, Linux - limited functionality)

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Contact

For questions or support, please contact: support@demonteach.com

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
