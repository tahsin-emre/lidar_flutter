import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/scan_cubit.dart';
import '../services/logger_service.dart';
import 'model_viewer_screen.dart';
import 'mixins/ar_scanner_mixin.dart';
import 'mixins/scan_event_mixin.dart';
import 'mixins/scan_state_mixin.dart';
import 'mixins/scan_ui_mixin.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with
        WidgetsBindingObserver,
        ARScannerMixin<ScannerScreen>,
        ScanStateMixin<ScannerScreen>,
        ScanEventMixin<ScannerScreen>,
        ScanUIMixin<ScannerScreen> {
  // Metod kanalı ve event kanalı tanımları

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // AR tarayıcıyı asenkron olarak başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initARScanner().catchError((error) {
        logger.logError('AR tarayıcı başlatma hatası', exception: error);
        showError('AR tarayıcı başlatılamadı', error.toString());
      });
      if (mounted) {
        listenToScanEvents();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Tarayıcı'),
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: togglePause,
          ),
        ],
      ),
      body: Stack(
        children: [
          // AR view platform view
          buildARView(),

          // Overlay for scan progress and guidance
          SafeArea(
            child: Column(
              children: [
                // Guidance at the top
                BlocBuilder<ScanCubit, ScanState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.guidanceMessage,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Butonlar (İlerleme çubuğu olmadan)
                BlocBuilder<ScanCubit, ScanState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Sıfırlama butonu
                          buildActionButton(
                            icon: Icons.refresh,
                            label: 'Sıfırla',
                            onTap: resetScan,
                          ),

                          // Duraklat/Devam butonu
                          buildActionButton(
                            icon:
                                state.isPaused ? Icons.play_arrow : Icons.pause,
                            label: state.isPaused ? 'Devam' : 'Duraklat',
                            onTap: togglePause,
                          ),

                          // Tamamla butonu
                          if (showCompleteScanButton)
                            buildActionButton(
                              icon: Icons.check_circle,
                              label: 'Tamamla',
                              onTap: processAndExportModel,
                              isPrimary: true,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Processing overlay
          if (isProcessing) buildProcessingOverlay(),
        ],
      ),
    );
  }
}
