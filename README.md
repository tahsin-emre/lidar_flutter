# LiDAR 3D Scanner Flutter App

A Flutter application for 3D scanning using LiDAR and depth sensors on compatible devices.

## Features

- 3D scanning using LiDAR sensors (iOS) or depth sensors (Android)
- Real-time scanning progress visualization
- 3D model viewing with interactive controls
- AR mode for viewing models in real-world context
- Export models to different formats
- Share models with others

## Technical Architecture

This project follows a feature-based architecture with clean separation of concerns:

### Project Structure

```
lib/
├── feature/           # Feature modules
│   ├── home/          # Home screen feature
│   ├── scanner/       # Scanner feature
│   └── model_viewer/  # Model viewer feature
└── product/           # Shared product code
    ├── init/          # App initialization
    │   ├── di/        # Dependency injection
    │   └── router/    # App routing
    ├── models/        # Data models
    ├── services/      # Services
    └── utils/         # Utilities
```

### Architecture Components

- **State Management**: Flutter BLoC for reactive and testable state management
- **Dependency Injection**: GetIt for service locator pattern
- **Navigation**: GoRouter for declarative routing
- **Services**: Platform-specific services for AR/LiDAR functionality
- **Models**: JSON-serializable data models

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- iOS 14.0+ device with LiDAR sensor (iPhone 12 Pro/Pro Max, iPhone 13 Pro/Pro Max, iPad Pro 2020 or newer)
- Android device with ARCore support and depth API compatibility

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/lidar_flutter.git
cd lidar_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

## Development

### Code Generation

This project uses code generation for JSON serialization and dependency injection. After making changes to models or services, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Adding New Features

1. Create a new feature directory under `lib/feature/`
2. Implement the feature using the BLoC pattern
3. Register any services in the dependency injection container
4. Add routes in the router configuration

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- ARKit plugin for iOS LiDAR support
- Model Viewer Plus for 3D model rendering
