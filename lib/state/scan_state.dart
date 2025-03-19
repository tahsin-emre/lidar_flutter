import 'package:flutter/foundation.dart';
import '../services/logger_service.dart';

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

  // Batch update desteği
  bool _batchUpdate = false;
  bool _needsNotification = false;

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

  // Batch update işlemlerini başlat
  void beginUpdate() {
    _batchUpdate = true;
    _needsNotification = false;
  }

  // Batch update işlemlerini bitir ve gerekiyorsa bildirim gönder
  void endUpdate() {
    _batchUpdate = false;
    if (_needsNotification) {
      notifyListeners();
      _needsNotification = false;
    }
  }

  // Değişiklik bildirimini yönet
  void _notifyIfNeeded() {
    if (_batchUpdate) {
      _needsNotification = true;
    } else {
      notifyListeners();
    }
  }

  // Taramayı başlat
  void startScan() {
    logger.info('Tarama başlatılıyor...', tag: 'ScanState');

    beginUpdate();
    _status = ScanningStatus.scanning;
    _progress = 0.0;
    _completedSegments = 0;
    _isPaused = false;
    _errorMessage = '';
    _modelPath = null;
    _statusMessage = 'Tarama başladı';
    endUpdate();
  }

  // Tarama ilerlemesini güncelle
  void updateProgress(double progress) {
    if (_progress == progress) return; // Değişiklik yoksa güncelleme yapma

    _progress = progress;
    _notifyIfNeeded();
  }

  // 360 derece tarama bilgilerini güncelle
  void updateScanCoverage(int completedSegments, int totalSegments) {
    if (_completedSegments == completedSegments &&
        _totalSegments == totalSegments) {
      return; // Değişiklik yoksa güncelleme yapma
    }

    beginUpdate();
    _completedSegments = completedSegments;
    _totalSegments = totalSegments;

    // İlerleme durumuna göre durumu güncelle
    if (_completedSegments >= _totalSegments &&
        _status == ScanningStatus.scanning) {
      _statusMessage = 'Tarama tamamlandı! İşleniyor...';
    }
    endUpdate();
  }

  // Rehberlik mesajını güncelle
  void updateGuidanceMessage(String message) {
    if (_guidanceMessage == message)
      return; // Değişiklik yoksa güncelleme yapma

    _guidanceMessage = message;
    _notifyIfNeeded();
  }

  // Taramayı tamamla
  void completeScan(String modelPath) {
    logger.info('Tarama tamamlandı: $modelPath', tag: 'ScanState');

    beginUpdate();
    _status = ScanningStatus.completed;
    _progress = 1.0;
    _statusMessage = 'Tarama tamamlandı!';
    _guidanceMessage = 'Tarama tamamlandı!';
    _modelPath = modelPath;
    endUpdate();
  }

  // Taramayı duraklat
  void pauseScan() {
    logger.debug('Tarama duraklatıldı', tag: 'ScanState');

    beginUpdate();
    _status = ScanningStatus.paused;
    _isPaused = true;
    _statusMessage = 'Tarama duraklatıldı';
    endUpdate();
  }

  // Taramayı devam ettir
  void resumeScan() {
    logger.debug('Tarama devam ediyor', tag: 'ScanState');

    beginUpdate();
    _status = ScanningStatus.scanning;
    _isPaused = false;
    _statusMessage = 'Tarama devam ediyor';
    endUpdate();
  }

  // Hata durumunda
  void failScan(String errorMessage) {
    logger.error('Tarama başarısız oldu: $errorMessage', tag: 'ScanState');

    beginUpdate();
    _status = ScanningStatus.failed;
    _errorMessage = errorMessage;
    _statusMessage = 'Tarama başarısız oldu';
    endUpdate();
  }

  // Durumu sıfırla
  void reset() {
    logger.info('Tarama durumu sıfırlanıyor', tag: 'ScanState');

    beginUpdate();
    _progress = 0.0;
    _status = ScanningStatus.notStarted;
    _statusMessage = 'Tarama hazır';
    _guidanceMessage = 'Taramaya başlamak için nesnenin etrafında hareket edin';
    _errorMessage = '';
    _completedSegments = 0;
    _isPaused = false;
    _modelPath = null;
    endUpdate();
  }
}
