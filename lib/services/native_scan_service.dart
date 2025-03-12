import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Service to handle communication with native platform code for 3D scanning
class NativeScanService {
  static const MethodChannel _channel = MethodChannel(
    'lidar_flutter/scan_service',
  );

  // Events from native
  static const EventChannel _scanEventChannel = EventChannel(
    'lidar_flutter/scan_events',
  );
  Stream<dynamic>? _scanEventStream;

  // Singleton instance
  static final NativeScanService _instance = NativeScanService._internal();

  factory NativeScanService() {
    return _instance;
  }

  NativeScanService._internal();

  /// Check if the device supports LiDAR (iOS) or depth API (Android)
  Future<bool> checkDeviceSupport() async {
    try {
      final bool isSupported = await _channel.invokeMethod(
        'checkDeviceSupport',
      );
      return isSupported;
    } on PlatformException catch (e) {
      print('Error checking device support: ${e.message}');
      return false;
    }
  }

  /// Initialize the native scanning module
  Future<void> initializeScan() async {
    try {
      await _channel.invokeMethod('initializeScan');
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize scan: ${e.message}');
    }
  }

  /// Start the scanning process
  Future<void> startScan() async {
    try {
      await _channel.invokeMethod('startScan');
    } on PlatformException catch (e) {
      throw Exception('Failed to start scan: ${e.message}');
    }
  }

  /// Pause the scanning process
  Future<void> pauseScan() async {
    try {
      await _channel.invokeMethod('pauseScan');
    } on PlatformException catch (e) {
      throw Exception('Failed to pause scan: ${e.message}');
    }
  }

  /// Resume the scanning process
  Future<void> resumeScan() async {
    try {
      await _channel.invokeMethod('resumeScan');
    } on PlatformException catch (e) {
      throw Exception('Failed to resume scan: ${e.message}');
    }
  }

  /// Complete the scanning process and generate the 3D model
  Future<String> completeScan({String format = 'glb'}) async {
    try {
      final String modelPath = await _channel.invokeMethod('completeScan', {
        'format': format,
      });
      return modelPath;
    } on PlatformException catch (e) {
      throw Exception('Failed to complete scan: ${e.message}');
    }
  }

  /// Cancel the scanning process
  Future<void> cancelScan() async {
    try {
      await _channel.invokeMethod('cancelScan');
    } on PlatformException catch (e) {
      throw Exception('Failed to cancel scan: ${e.message}');
    }
  }

  /// Get point cloud data from the scan
  Future<List<String>> getPointCloudData() async {
    try {
      final List<dynamic> pointCloud = await _channel.invokeMethod(
        'getPointCloudData',
      );
      return pointCloud.cast<String>();
    } on PlatformException catch (e) {
      throw Exception('Failed to get point cloud data: ${e.message}');
    }
  }

  /// Get a stream of scanning events (progress updates, etc.)
  Stream<dynamic> getScanEvents() {
    _scanEventStream ??= _scanEventChannel.receiveBroadcastStream();
    return _scanEventStream!;
  }

  /// Get available 3D models that have been scanned
  Future<List<String>> getAvailableModels() async {
    try {
      final List<dynamic> models = await _channel.invokeMethod(
        'getAvailableModels',
      );
      return models.cast<String>();
    } on PlatformException catch (e) {
      throw Exception('Failed to get available models: ${e.message}');
    }
  }

  /// Delete a 3D model at the specified path
  Future<bool> deleteModel(String path) async {
    try {
      final bool success = await _channel.invokeMethod('deleteModel', {
        'path': path,
      });
      return success;
    } on PlatformException catch (e) {
      throw Exception('Failed to delete model: ${e.message}');
    }
  }
}
