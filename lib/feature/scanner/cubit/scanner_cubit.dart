import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_flutter/product/services/scanner_service.dart';
import 'package:lidar_flutter/product/services/model_service.dart';
import 'package:lidar_flutter/product/init/di/locator.dart';

// States
abstract class ScannerState {}

class ScannerInitialState extends ScannerState {}

class ScannerLoadingState extends ScannerState {
  final String message;

  ScannerLoadingState(this.message);
}

class ScannerReadyState extends ScannerState {}

class ScannerScanningState extends ScannerState {
  final double progress;
  final String message;

  ScannerScanningState(this.progress, this.message);
}

class ScannerPausedState extends ScannerState {
  final double progress;
  final String message;

  ScannerPausedState(this.progress, this.message);
}

class ScannerCompletedState extends ScannerState {
  final String modelPath;

  ScannerCompletedState(this.modelPath);
}

class ScannerErrorState extends ScannerState {
  final String error;

  ScannerErrorState(this.error);
}

// Cubit
class ScannerCubit extends Cubit<ScannerState> {
  final ScannerService _scannerService = locator<ScannerService>();
  final ModelService _modelService = locator<ModelService>();

  double _currentProgress = 0.0;
  String _currentMessage = '';
  Timer? _progressTimer;

  ScannerCubit() : super(ScannerInitialState());

  Future<void> initializeScanner() async {
    emit(ScannerLoadingState('Initializing scanner...'));

    try {
      // Check device support
      final bool hasSupport = await _scannerService.checkDeviceSupport();

      if (!hasSupport) {
        emit(ScannerErrorState(
            'Your device does not support LiDAR or Depth API.'));
        return;
      }

      // Initialize scan
      await _scannerService.initializeScan();

      emit(ScannerReadyState());
    } catch (e) {
      emit(ScannerErrorState('Failed to initialize scanner: ${e.toString()}'));
    }
  }

  Future<void> startScan() async {
    try {
      await _scannerService.startScan();

      _currentProgress = 0.0;
      _currentMessage = 'Starting scan...';
      emit(ScannerScanningState(_currentProgress, _currentMessage));

      // Start simulated progress updates
      _startProgressSimulation();
    } catch (e) {
      emit(ScannerErrorState('Failed to start scan: ${e.toString()}'));
    }
  }

  Future<void> pauseScan() async {
    try {
      await _scannerService.pauseScan();
      _stopProgressSimulation();

      emit(ScannerPausedState(_currentProgress, _currentMessage));
    } catch (e) {
      emit(ScannerErrorState('Failed to pause scan: ${e.toString()}'));
    }
  }

  Future<void> resumeScan() async {
    try {
      await _scannerService.resumeScan();

      emit(ScannerScanningState(_currentProgress, _currentMessage));

      // Resume progress updates
      _startProgressSimulation();
    } catch (e) {
      emit(ScannerErrorState('Failed to resume scan: ${e.toString()}'));
    }
  }

  Future<void> completeScan() async {
    _stopProgressSimulation();

    try {
      final result = await _scannerService.completeScan();

      if (result.containsKey('modelPath') && result['modelPath'] != null) {
        emit(ScannerCompletedState(result['modelPath']));
      } else {
        emit(ScannerErrorState(
            'Failed to complete scan: No model path returned'));
      }
    } catch (e) {
      emit(ScannerErrorState('Failed to complete scan: ${e.toString()}'));
    }
  }

  Future<void> cancelScan() async {
    _stopProgressSimulation();

    try {
      await _scannerService.cancelScan();
      emit(ScannerInitialState());
    } catch (e) {
      emit(ScannerErrorState('Failed to cancel scan: ${e.toString()}'));
    }
  }

  void updateProgress(double progress, String message) {
    _currentProgress = progress;
    _currentMessage = message;

    emit(ScannerScanningState(_currentProgress, _currentMessage));
  }

  void _startProgressSimulation() {
    _stopProgressSimulation();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _currentProgress += 0.05;
      if (_currentProgress > 1.0) _currentProgress = 1.0;

      String message = 'Scanning...';
      if (_currentProgress < 0.3) {
        message = 'Start moving around the object...';
      } else if (_currentProgress < 0.7) {
        message = 'Continue scanning all sides...';
      } else {
        message = 'Almost done, capturing details...';
      }

      _currentMessage = message;
      updateProgress(_currentProgress, _currentMessage);

      if (_currentProgress >= 1.0) {
        _stopProgressSimulation();
        completeScan();
      }
    });
  }

  void _stopProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  Future<void> close() {
    _stopProgressSimulation();
    return super.close();
  }
}
