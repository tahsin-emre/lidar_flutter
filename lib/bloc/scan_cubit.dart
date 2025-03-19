import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/logger_service.dart';

enum ScanningStatus { notStarted, scanning, paused, completed, failed }

class ScanState {
  final ScanningStatus status;
  final double progress;
  final String statusMessage;
  final String errorMessage;
  final String? modelPath;
  final String guidanceMessage;
  final int completedSegments;
  final int totalSegments;
  final bool isPaused;

  const ScanState({
    this.status = ScanningStatus.notStarted,
    this.progress = 0.0,
    this.statusMessage = 'Tarama hazır',
    this.errorMessage = '',
    this.modelPath,
    this.guidanceMessage =
        'Taramaya başlamak için nesnenin etrafında hareket edin',
    this.completedSegments = 0,
    this.totalSegments = 36,
    this.isPaused = false,
  });

  ScanState copyWith({
    ScanningStatus? status,
    double? progress,
    String? statusMessage,
    String? errorMessage,
    String? modelPath,
    String? guidanceMessage,
    int? completedSegments,
    int? totalSegments,
    bool? isPaused,
  }) {
    return ScanState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      modelPath: modelPath ?? this.modelPath,
      guidanceMessage: guidanceMessage ?? this.guidanceMessage,
      completedSegments: completedSegments ?? this.completedSegments,
      totalSegments: totalSegments ?? this.totalSegments,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  bool get isScanning => status == ScanningStatus.scanning;
  bool get isPausing => status == ScanningStatus.paused;
  bool get isCompleted => status == ScanningStatus.completed;
  bool get isFailed => status == ScanningStatus.failed;
  bool get isFullyCovered => completedSegments >= totalSegments;
  double get scanCompletionPercentage => completedSegments / totalSegments;
}

class ScanCubit extends Cubit<ScanState> {
  ScanCubit() : super(const ScanState());

  void startScan() {
    logger.debug('Tarama başlatılıyor...', tag: 'ScanCubit');
    emit(state.copyWith(
      status: ScanningStatus.scanning,
      progress: 0.0,
      completedSegments: 0,
      isPaused: false,
      errorMessage: '',
      modelPath: null,
      statusMessage: 'Tarama başladı',
    ));
  }

  void updateProgress(double progress) {
    if (state.progress == progress) return;
    emit(state.copyWith(progress: progress));
  }

  void updateScanCoverage(int completedSegments, int totalSegments) {
    if (state.completedSegments == completedSegments &&
        state.totalSegments == totalSegments) {
      return;
    }

    emit(state.copyWith(
      completedSegments: completedSegments,
      totalSegments: totalSegments,
      statusMessage: completedSegments >= totalSegments &&
              state.status == ScanningStatus.scanning
          ? 'Tarama tamamlandı! İşleniyor...'
          : state.statusMessage,
    ));
  }

  void updateGuidanceMessage(String message) {
    if (state.guidanceMessage == message) return;
    emit(state.copyWith(guidanceMessage: message));
  }

  void completeScan(String modelPath) {
    logger.debug('Tarama tamamlandı: $modelPath', tag: 'ScanCubit');
    emit(state.copyWith(
      status: ScanningStatus.completed,
      progress: 1.0,
      statusMessage: 'Tarama tamamlandı!',
      guidanceMessage: 'Tarama tamamlandı!',
      modelPath: modelPath,
    ));
  }

  void pauseScan() {
    logger.debug('Tarama duraklatıldı', tag: 'ScanCubit');
    emit(state.copyWith(
      status: ScanningStatus.paused,
      isPaused: true,
      statusMessage: 'Tarama duraklatıldı',
    ));
  }

  void resumeScan() {
    logger.debug('Tarama devam ediyor', tag: 'ScanCubit');
    emit(state.copyWith(
      status: ScanningStatus.scanning,
      isPaused: false,
      statusMessage: 'Tarama devam ediyor',
    ));
  }

  void failScan(String errorMessage) {
    // logger.error('Tarama başarısız oldu: $errorMessage', tag: 'ScanCubit');
    emit(state.copyWith(
      status: ScanningStatus.failed,
      errorMessage: errorMessage,
      statusMessage: 'Tarama başarısız oldu',
    ));
  }

  void reset() {
    // logger.info('Tarama durumu sıfırlanıyor', tag: 'ScanCubit');
    emit(const ScanState());
  }
}
