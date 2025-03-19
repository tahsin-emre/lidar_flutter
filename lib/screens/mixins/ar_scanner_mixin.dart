import 'dart:io';
import 'package:flutter/services.dart';
import '../../services/logger_service.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/widgets.dart';

mixin ARScannerMixin<T extends StatefulWidget> on State<T> {
  static const methodChannel = MethodChannel('lidar_flutter/ar_scanner');
  static const scanEventChannel = EventChannel('lidar_flutter/scan_events');
  final MethodChannel scanServiceChannel =
      const MethodChannel('lidar_flutter/scan_service');

  dynamic _arController; // can be ARKitController on iOS

  void disposeAR() {
    try {
      if (_arController != null) {
        if (Platform.isIOS) {
          (_arController as ARKitController).dispose();
        }
        _arController = null;
      }
    } catch (e) {
      // logger.error('AR Controller dispose hatası', exception: e);
    }
  }

  Future<void> initARScanner() async {
    try {
      // ARKit yapılandırması
      final bool result = await methodChannel.invokeMethod<bool>(
            'setupARKitConfig',
            {'enableLiDAR': true, 'enableMesh': true},
          ) ??
          false;

      // logger.info('ARKit yapılandırması: $result', tag: 'ScannerScreen');

      if (result) {
        // Tarama başlatma
        final scanResult =
            await scanServiceChannel.invokeMethod<bool>('initializeScan') ??
                false;

        if (scanResult) {
          // logger.info('Tarama başlatıldı', tag: 'ScannerScreen');
          // AR oturumunu başlat
          await methodChannel.invokeMethod<bool>('startScanning');
        } else {
          throw Exception('Tarama başlatılamadı');
        }
      } else {
        throw Exception('ARKit yapılandırması başarısız');
      }
    } catch (e) {
      // logger.error('ARKit başlatma hatası', exception: e);
      rethrow;
    }
  }

  Future<void> pauseScan() async {
    try {
      await methodChannel.invokeMethod<void>('pauseScan');
      // logger.debug('Tarama duraklatıldı', tag: 'ScannerScreen');
    } catch (e) {
      // logger.error('Tarama duraklatma hatası', exception: e);
    }
  }

  Future<void> resumeScan() async {
    try {
      await methodChannel.invokeMethod<void>('resumeScan');
      logger.debug('Tarama devam ettirildi', tag: 'ScannerScreen');
    } catch (e) {
      // logger.error('Tarama devam ettirme hatası', exception: e);
    }
  }

  Future<void> resetScan() async {
    try {
      await methodChannel.invokeMethod<void>('resetScan');
      // logger.info('Tarama sıfırlandı', tag: 'ScannerScreen');
    } catch (e) {
      // logger.error('Tarama sıfırlama hatası', exception: e);
      rethrow;
    }
  }
}
