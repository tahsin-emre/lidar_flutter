# 3D Scanner with LiDAR/Depth Sensors

A Flutter application that uses ARKit (iOS) and ARCore (Android) to scan real-world objects and generate 3D models. The app utilizes LiDAR on iOS devices and depth APIs on Android to collect point cloud data and implements surface reconstruction techniques to create mesh models.

## Features

- **3D Object Scanning**: Uses AR frameworks to scan real-world objects
- **Real-time Guidance**: Overlay UI instructions and visual cues to guide the scanning process
- **3D Model Generation**: Converts point cloud data into 3D models (USDZ, OBJ, GLTF)
- **3D Model Viewer**: Interactive viewer with gesture controls for the generated models
- **Cross-Platform**: Works on both iOS (ARKit) and Android (ARCore)

## Requirements

### iOS
- iOS 14.0 or later (for LiDAR functionality)
- Device with LiDAR sensor (iPhone 12 Pro, iPad Pro 2020 or later)
- Xcode 12 or later

### Android
- Android 8.0 (API Level 26) or later
- ARCore-supported device with depth API support
- Android Studio 4.0 or later

## Setup Instructions

### Prerequisites
1. Install Flutter SDK (version 3.7.0 or later)
2. Set up iOS and Android development environments
3. Install required dependencies

### Installation
1. Clone the repository:
   ```
   git clone https://github.com/yourusername/lidar_flutter.git
   cd lidar_flutter
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

## Technical Implementation

### iOS (ARKit/LiDAR)
- Uses `ARKit` framework with scene reconstruction capabilities
- Utilizes LiDAR sensor for accurate depth mapping
- Implements RealityKit for processing and mesh generation

### Android (ARCore)
- Uses `ARCore` with depth API for point cloud collection
- Implements Sceneform for 3D model processing
- Utilizes depth sensors where available

### Flutter Integration
- Platform Channels for native AR functionality
- Model viewer integration for displaying generated 3D models
- State management with Provider

## Usage Guide

1. **Home Screen**: Choose between starting a new scan or viewing existing models
2. **Scanning Process**:
   - Place your object on a flat surface
   - Maintain a consistent distance (1-2 feet) from the object
   - Move slowly around the object for complete coverage
   - Follow on-screen guidance to capture all areas
3. **Model Processing**: The app will process the point cloud data into a 3D model
4. **Model Viewing**: Interact with the generated model using pinch, rotate, and pan gestures

## Limitations

- Scanning works best with objects 10-50cm in size
- Reflective, transparent, or very dark objects may not scan properly
- Good lighting conditions are necessary for optimal results
- Processing complex models may take longer on older devices

## Future Improvements

- Texture mapping for more realistic models
- Cloud-based processing for higher-quality meshes
- Model editing capabilities
- AR placement of scanned models in the real world
- Multi-language support

## License

[MIT License](LICENSE)

## Acknowledgements

- Flutter Team
- ARKit and ARCore frameworks
- Contributors and testers
