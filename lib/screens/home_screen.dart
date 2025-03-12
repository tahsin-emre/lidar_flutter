import 'package:flutter/material.dart';
import 'package:lidar_flutter/screens/scanner_screen.dart';
import 'package:lidar_flutter/screens/viewer_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasLidar = false;
  bool _checkingCapabilities = true;
  String _deviceInfo = '';

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
      _checkingCapabilities = false;

      // In a real app, you'd check actual device capabilities
      if (platform == TargetPlatform.iOS) {
        _hasLidar = true;
        _deviceInfo = 'iOS device with LiDAR';
      } else if (platform == TargetPlatform.android) {
        _hasLidar = true;
        _deviceInfo = 'Android device with ARCore depth API';
      } else {
        _hasLidar = false;
        _deviceInfo = 'Unsupported platform';
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    // Additional permissions as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Scanner'), centerTitle: true),
      body:
          _checkingCapabilities
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.view_in_ar, size: 100, color: Colors.blue),
                    const SizedBox(height: 24),
                    Text(
                      '3D Object Scanner',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan real-world objects and create 3D models',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Device Capabilities',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _hasLidar ? Icons.check_circle : Icons.error,
                                  color: _hasLidar ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Flexible(child: Text(_deviceInfo)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed:
                          _hasLidar
                              ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScannerScreen(),
                                ),
                              )
                              : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera),
                          SizedBox(width: 8),
                          Text('Start New Scan'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewerScreen(),
                            ),
                          ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.view_in_ar),
                          SizedBox(width: 8),
                          Text('View Saved Models'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
