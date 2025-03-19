import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/scan_cubit.dart';
import '../../services/logger_service.dart';
import 'ar_scanner_mixin.dart';
import 'scan_state_mixin.dart';

mixin ScanEventMixin<T extends StatefulWidget>
    on State<T>, ARScannerMixin<T>, ScanStateMixin<T> {
  StreamSubscription? _scanEventSubscription;
  static const methodChannel = MethodChannel('lidar_flutter/ar_scanner');
  static const scanEventChannel = EventChannel('lidar_flutter/scan_events');
  @override
  final MethodChannel scanServiceChannel =
      const MethodChannel('lidar_flutter/scan_service');

  void listenToScanEvents() {
    _scanEventSubscription = scanEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) {
          return;
        }

        final eventType = event['type'] as String?;
        handleScanEvent(eventType, event);
      },
      onError: (error) {
        logger.logError('Event channel hatası', exception: error);
      },
      onDone: () {
        logger.logInfo('Scan event stream kapandı', tag: 'ScannerScreen');
      },
    );
  }

  void handleScanEvent(String? eventType, Map event) {
    if (!mounted) return;

    final scanCubit = context.read<ScanCubit>();

    switch (eventType) {
      case 'scanProgress':
        handleScanProgressEvent(scanCubit, event);
        break;

      case 'guidance':
        handleGuidanceEvent(scanCubit, event);
        break;

      case 'scanStatus':
        handleScanStatusEvent(scanCubit, event);
        break;

      case 'error':
        handleErrorEvent(scanCubit, event);
        break;
    }
  }

  void handleScanProgressEvent(ScanCubit scanCubit, Map event) {
    final progress = event['progress'] as double? ?? 0.0;
    final completedSegments = event['completedSegments'] as int? ?? 0;
    final totalSegments = event['totalSegments'] as int? ?? 0;

    scanCubit.updateProgress(progress);
    if (totalSegments > 0) {
      scanCubit.updateScanCoverage(completedSegments, totalSegments);
    }
  }

  void handleGuidanceEvent(ScanCubit scanCubit, Map event) {
    final message = event['message'] as String? ?? '';
    scanCubit.updateGuidanceMessage(message);
  }

  void handleScanStatusEvent(ScanCubit scanCubit, Map event) {
    final status = event['status'] as String? ?? '';

    switch (status) {
      case 'completed':
        processAndExportModel();
        break;

      case 'failed':
        final message = event['message'] as String? ?? 'Bilinmeyen hata';
        scanCubit.updateGuidanceMessage('Tarama hatası: $message');
        break;

      case 'readyToComplete':
        if (scanCubit.state.isFullyCovered) {
          processAndExportModel();
        } else {
          scanCubit.updateGuidanceMessage(
              'Tarama hazır! Tamamlamak için butona basın.');
          setState(() {
            setShowCompleteScanButton(true);
          });
        }
        break;
    }
  }

  void handleErrorEvent(ScanCubit scanCubit, Map event) {
    final message = event['message'] as String? ?? 'Bilinmeyen hata';
    logger.logError('Tarama hatası: $message', tag: 'ScannerScreen');
    scanCubit.updateGuidanceMessage('Hata: $message');
  }

  void disposeScanEvents() {
    _scanEventSubscription?.cancel();
  }

  Future<void> processAndExportModel();
}
