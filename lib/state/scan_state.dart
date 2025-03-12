import 'package:flutter/foundation.dart';

enum ScanningStatus { notStarted, scanning, completed, failed }

class ScanState extends ChangeNotifier {
  ScanningStatus _status = ScanningStatus.notStarted;
  double _progress = 0.0;
  String _statusMessage = '';
  String _errorMessage = '';
  String? _modelPath;

  // Getters
  ScanningStatus get status => _status;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String get errorMessage => _errorMessage;
  String? get modelPath => _modelPath;

  bool get isScanning => _status == ScanningStatus.scanning;
  bool get isCompleted => _status == ScanningStatus.completed;
  bool get isFailed => _status == ScanningStatus.failed;

  // Taramayı başlat
  void startScan() {
    _status = ScanningStatus.scanning;
    _progress = 0.0;
    _statusMessage = 'Starting scan...';
    _errorMessage = '';
    _modelPath = null;
    notifyListeners();
  }

  // İlerleme durumunu güncelle
  void updateProgress(double progress, String message) {
    _progress = progress;
    _statusMessage = message;
    notifyListeners();
  }

  // Taramayı tamamla
  void completeScan(String modelPath) {
    _status = ScanningStatus.completed;
    _progress = 1.0;
    _statusMessage = 'Scan completed!';
    _modelPath = modelPath;
    notifyListeners();
  }

  // Taramayı başarısız olarak işaretle
  void failScan(String error) {
    _status = ScanningStatus.failed;
    _errorMessage = error;
    notifyListeners();
  }

  // Tarama durumunu sıfırla
  void reset() {
    _status = ScanningStatus.notStarted;
    _progress = 0.0;
    _statusMessage = '';
    _errorMessage = '';
    _modelPath = null;
    notifyListeners();
  }
}
