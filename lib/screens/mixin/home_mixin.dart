import 'package:flutter/material.dart';
import 'package:lidar_flutter/screens/home_screen.dart';
import 'package:lidar_flutter/screens/scanner_screen.dart';
import 'package:permission_handler/permission_handler.dart';

mixin HomeMixin on State<HomeScreen> {
  bool hasLidar = false;
  bool checkingCapabilities = true;
  String deviceInfo = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    await _checkDeviceCapabilities();
    await _requestPermissions();
  }

  Future<void> _checkDeviceCapabilities() async {
    // This would typically be implemented with platform channels
    // to check for LiDAR on iOS and depth API on Android

    // For now, simply detect platform and simulate checks
    final platform = Theme.of(context).platform;

    setState(() {
      checkingCapabilities = false;

      // In a real app, you'd check actual device capabilities
      if (platform == TargetPlatform.iOS) {
        hasLidar = true;
        deviceInfo = 'iOS device with LiDAR';
      } else if (platform == TargetPlatform.android) {
        hasLidar = true;
        deviceInfo = 'Android device with ARCore depth API';
      } else {
        hasLidar = false;
        deviceInfo = 'Unsupported platform';
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    // Additional permissions as needed
  }

  void navigateToScanner() {
    if (!hasLidar) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Lidar Desteği Yok'),
          content: Text('Bu cihazda Lidar desteği yok.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
  }
}
