import 'package:flutter/foundation.dart';

enum ScanningStatus {
  notStarted, // Tarama henüz başlamadı
  scanning, // Tarama devam ediyor
  paused, // Tarama duraklatıldı
  completed, // Tarama tamamlandı
  failed // Tarama başarısız oldu
}

class ScanState extends ChangeNotifier {
  ScanningStatus _status = ScanningStatus.notStarted;
  double _progress = 0.0;
  String _statusMessage = 'Tarama hazır';
  String _errorMessage = '';
  String? _modelPath;
  String _guidanceMessage =
      'Taramaya başlamak için nesnenin etrafında hareket edin';
  int _completedSegments = 0;
  int _totalSegments =
      36; // Varsayılan olarak 36 segment (10 derece aralıklarla)
  bool _isPaused = false;

  // Getters
  ScanningStatus get status => _status;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String get errorMessage => _errorMessage;
  String? get modelPath => _modelPath;
  String get guidanceMessage => _guidanceMessage;

  // 360 derece tarama bilgisi getter'ları
  int get completedSegments => _completedSegments;
  int get totalSegments => _totalSegments;
  double get scanCompletionPercentage => _completedSegments / _totalSegments;

  bool get isScanning => _status == ScanningStatus.scanning;
  bool get isPausing => _status == ScanningStatus.paused;
  bool get isCompleted => _status == ScanningStatus.completed;
  bool get isFailed => _status == ScanningStatus.failed;
  bool get isFullyCovered => _completedSegments >= _totalSegments;
  bool get isPaused => _isPaused;

  // Taramayı başlat
  void startScan() {
    _status = ScanningStatus.scanning;
    _progress = 0.0;
    _completedSegments = 0;
    _isPaused = false;
    _errorMessage = '';
    _modelPath = null;
    notifyListeners();
  }

  // Tarama ilerlemesini güncelle
  void updateProgress(double progress) {
    _progress = progress;
    notifyListeners();
  }

  // 360 derece tarama bilgilerini güncelle
  void updateScanCoverage(int completedSegments, int totalSegments) {
    _completedSegments = completedSegments;
    _totalSegments = totalSegments;
    notifyListeners();
  }

  // Rehberlik mesajını güncelle
  void updateGuidanceMessage(String message) {
    _guidanceMessage = message;
    notifyListeners();
  }

  // Taramayı tamamla
  void completeScan(String modelPath) {
    _status = ScanningStatus.completed;
    _progress = 1.0;
    _statusMessage = 'Scan completed!';
    _guidanceMessage = 'Tarama tamamlandı!';
    _modelPath = modelPath;
    notifyListeners();
  }

  // Taramayı duraklat
  void pauseScan() {
    _status = ScanningStatus.paused;
    _isPaused = true;
    notifyListeners();
  }

  // Taramayı devam ettir
  void resumeScan() {
    _status = ScanningStatus.scanning;
    _isPaused = false;
    notifyListeners();
  }

  // Hata durumunda
  void failScan(String errorMessage) {
    _status = ScanningStatus.failed;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  // Durumu sıfırla
  void reset() {
    _progress = 0.0;
    _status = ScanningStatus.notStarted;
    _statusMessage = 'Tarama hazır';
    _guidanceMessage = 'Taramaya başlamak için nesnenin etrafında hareket edin';
    _errorMessage = '';
    _completedSegments = 0;
    _isPaused = false;
    _modelPath = null;
    notifyListeners();
  }
}
