import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_flutter/bloc/scan_cubit.dart';
import 'package:lidar_flutter/screens/mixins/ar_scanner_mixin.dart';
import 'package:lidar_flutter/screens/mixins/scan_event_mixin.dart';
import 'package:lidar_flutter/screens/mixins/scan_state_mixin.dart';
import 'package:lidar_flutter/screens/mixins/scan_ui_mixin.dart';
import 'package:lidar_flutter/screens/model_viewer_screen.dart';
import 'package:lidar_flutter/services/logger_service.dart';

mixin ScannerMixin<T extends StatefulWidget> on State<T>
    implements
        WidgetsBindingObserver,
        ARScannerMixin<T>,
        ScanStateMixin<T>,
        ScanEventMixin<T>,
        ScanUIMixin<T> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addObserver(this);

    // // AR tarayıcıyı asenkron olarak başlat
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   initARScanner().catchError((error) {
    //     logger.logError('AR tarayıcı başlatma hatası', exception: error);
    //     showError('AR tarayıcı başlatılamadı', error.toString());
    //   });
    //   if (mounted) {
    //     listenToScanEvents();
    //   }
    // });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pauseScan(); // Taramayı durdur
    disposeAR();
    disposeScanEvents(); // Stream aboneliğini iptal et
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      pauseScan();
    } else if (state == AppLifecycleState.resumed) {
      resumeScan();
    }
  }

  // 3D modeli işle ve view ekranına git - optimize edilmiş
  @override
  Future<void> processAndExportModel() async {
    if (isProcessing) return; // Zaten işlem yapılıyorsa tekrar başlatma

    setProcessing(true);

    try {
      logger.logInfo('Model işleniyor...', tag: 'ScannerScreen');

      final result =
          await scanServiceChannel.invokeMethod<Map<dynamic, dynamic>>(
        'processAndExportModel',
      );

      if (result != null && result.containsKey('modelPath')) {
        final modelPath = result['modelPath'] as String;
        logger.logInfo('3D model oluşturuldu: $modelPath',
            tag: 'ScannerScreen');

        // İşlem tamamlandı, model görüntüleme ekranına git
        if (mounted) {
          // ScanState'i güncelle
          final scanCubit = context.read<ScanCubit>();
          scanCubit.completeScan(modelPath);

          setProcessing(false);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ModelViewerScreen(modelPath: modelPath),
            ),
          );
        }
      } else {
        throw Exception('3D model oluşturulamadı');
      }
    } catch (e) {
      logger.logError('Model işleme hatası', exception: e);
      if (mounted) {
        // Hata durumunda ScanState'i güncelle
        final scanCubit = context.read<ScanCubit>();
        scanCubit.failScan('Model işlenirken bir hata oluştu: $e');

        setProcessing(false);

        showError(
            'Model oluşturma hatası', 'Model işlenirken bir hata oluştu: $e');
      }
    }
  }
}
