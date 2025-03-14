import 'dart:io';
import 'package:flutter/services.dart';

class ScannerService {
  // AR Scanner channel
  final MethodChannel _arScanChannel = const MethodChannel(
    'lidar_flutter/ar_scanner',
  );

  // Scan service channel
  final MethodChannel _scanServiceChannel = const MethodChannel(
    'lidar_flutter/scan_service',
  );

  // Check if device supports LiDAR
  Future<bool> checkLiDARSupport() async {
    try {
      final bool hasLiDAR = await _arScanChannel.invokeMethod('supportsLiDAR');
      return hasLiDAR;
    } catch (e) {
      print('Error checking LiDAR support: $e');
      return false;
    }
  }

  // Check if device supports scanning
  Future<bool> checkDeviceSupport() async {
    try {
      final bool hasSupport =
          await _scanServiceChannel.invokeMethod('checkDeviceSupport');
      return hasSupport;
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  // Initialize scanning
  Future<void> initializeScan() async {
    try {
      await _scanServiceChannel.invokeMethod('initializeScan');
    } catch (e) {
      print('Error initializing scan: $e');
      throw Exception('Failed to initialize scanner: ${e.toString()}');
    }
  }

  // Setup ARKit configuration
  Future<void> setupARKitConfig(
      {bool enableLiDAR = true, bool enableMesh = true}) async {
    if (Platform.isIOS) {
      try {
        await _arScanChannel.invokeMethod('setupARKitConfig',
            {'enableLiDAR': enableLiDAR, 'enableMesh': enableMesh});
      } catch (e) {
        print('Error setting up ARKit config: $e');
        throw Exception('Failed to setup ARKit configuration: ${e.toString()}');
      }
    }
  }

  // Start scanning
  Future<void> startScan() async {
    try {
      await _scanServiceChannel.invokeMethod('startScan');
    } catch (e) {
      print('Error starting scan: $e');
      throw Exception('Failed to start scan: ${e.toString()}');
    }
  }

  // Pause scanning
  Future<void> pauseScan() async {
    try {
      if (Platform.isIOS) {
        await _arScanChannel.invokeMethod('pauseSession');
      } else {
        await _scanServiceChannel.invokeMethod('pauseScan');
      }
    } catch (e) {
      print('Error pausing scan: $e');
    }
  }

  // Resume scanning
  Future<void> resumeScan() async {
    try {
      if (Platform.isIOS) {
        await _arScanChannel.invokeMethod('resumeSession');
      } else {
        await _scanServiceChannel.invokeMethod('resumeScan');
      }
    } catch (e) {
      print('Error resuming scan: $e');
    }
  }

  // Complete scanning
  Future<Map<String, dynamic>> completeScan() async {
    try {
      final result = await _scanServiceChannel.invokeMethod('completeScan');
      return result ?? {};
    } catch (e) {
      print('Error completing scan: $e');
      throw Exception('Failed to complete scan: ${e.toString()}');
    }
  }

  // Cancel scanning
  Future<void> cancelScan() async {
    try {
      await _scanServiceChannel.invokeMethod('cancelScan');
    } catch (e) {
      print('Error canceling scan: $e');
    }
  }
}
