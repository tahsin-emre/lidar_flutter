import 'package:flutter/material.dart';

enum ScanningStage {
  notStarted,
  preparing,
  scanning,
  processing,
  completed,
  failed,
}

class ScanState extends ChangeNotifier {
  ScanningStage _stage = ScanningStage.notStarted;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _modelFilePath;
  String? _errorMessage;
  List<String>? _pointCloudData;

  // Getters
  ScanningStage get stage => _stage;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get modelFilePath => _modelFilePath;
  String? get errorMessage => _errorMessage;
  List<String>? get pointCloudData => _pointCloudData;

  bool get isScanning => _stage == ScanningStage.scanning;
  bool get isCompleted => _stage == ScanningStage.completed;
  bool get isFailed => _stage == ScanningStage.failed;

  // Methods to update state
  void startScanning() {
    _stage = ScanningStage.preparing;
    _statusMessage = 'Preparing scanner...';
    _progress = 0.0;
    _errorMessage = null;
    _modelFilePath = null;
    notifyListeners();
  }

  void updateScanningProgress(double progress, String message) {
    _stage = ScanningStage.scanning;
    _progress = progress;
    _statusMessage = message;
    notifyListeners();
  }

  void startProcessing() {
    _stage = ScanningStage.processing;
    _statusMessage = 'Processing scan data...';
    notifyListeners();
  }

  void setPointCloudData(List<String> data) {
    _pointCloudData = data;
    notifyListeners();
  }

  void completeScan(String modelPath) {
    _stage = ScanningStage.completed;
    _modelFilePath = modelPath;
    _statusMessage = 'Scan completed successfully';
    _progress = 1.0;
    notifyListeners();
  }

  void failScan(String errorMessage) {
    _stage = ScanningStage.failed;
    _errorMessage = errorMessage;
    _statusMessage = 'Scan failed';
    notifyListeners();
  }

  void reset() {
    _stage = ScanningStage.notStarted;
    _progress = 0.0;
    _statusMessage = '';
    _modelFilePath = null;
    _errorMessage = null;
    _pointCloudData = null;
    notifyListeners();
  }
}
