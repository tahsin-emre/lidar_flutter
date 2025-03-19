import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/scan_state.dart';
import '../services/logger_service.dart';
import 'model_viewer_screen.dart';
import 'package:arkit_plugin/arkit_plugin.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  // Metod kanalı ve event kanalı tanımları
  static const methodChannel = MethodChannel('lidar_flutter/ar_scanner');
  static const scanEventChannel = EventChannel('lidar_flutter/scan_events');
  final MethodChannel scanServiceChannel =
      const MethodChannel('lidar_flutter/scan_service');

  bool _isPaused = false;
  bool _isProcessing = false;
  bool _showCompleteScanButton = false;
  dynamic _arController; // can be ARKitController on iOS
  StreamSubscription? _scanEventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // AR tarayıcıyı asenkron olarak başlat

    // Event dinleyiciyi bir sonraki frame'de başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initARScanner().catchError((error) {
        logger.error('AR tarayıcı başlatma hatası', exception: error);
        _showError('AR tarayıcı başlatılamadı', error.toString());
      });
      if (mounted) {
        _listenToScanEvents();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseScan(); // Taramayı durdur
    _disposeAR();
    _scanEventSubscription?.cancel(); // Stream aboneliğini iptal et
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseScan();
    } else if (state == AppLifecycleState.resumed) {
      _resumeScan();
    }
  }

  void _disposeAR() {
    try {
      if (_arController != null) {
        if (Platform.isIOS) {
          (_arController as ARKitController).dispose();
        }
        _arController = null;
      }
    } catch (e) {
      logger.error('AR Controller dispose hatası', exception: e);
    }
  }

  // AR tarayıcıyı başlat
  Future<void> _initARScanner() async {
    try {
      final scanState = Provider.of<ScanState>(context, listen: false);
      scanState.startScan();

      // ARKit yapılandırması
      final bool result = await methodChannel.invokeMethod<bool>(
            'setupARKitConfig',
            {'enableLiDAR': true, 'enableMesh': true},
          ) ??
          false;

      logger.info('ARKit yapılandırması: $result', tag: 'ScannerScreen');

      if (result) {
        // Tarama başlatma
        final scanResult =
            await scanServiceChannel.invokeMethod<bool>('initializeScan') ??
                false;

        if (scanResult) {
          logger.info('Tarama başlatıldı', tag: 'ScannerScreen');
          // AR oturumunu başlat
          await methodChannel.invokeMethod<bool>('startScanning');
        } else {
          throw Exception('Tarama başlatılamadı');
        }
      } else {
        throw Exception('ARKit yapılandırması başarısız');
      }
    } catch (e) {
      logger.error('ARKit başlatma hatası', exception: e);
      if (mounted) {
        _showError('AR tarayıcı başlatılamadı', e.toString());
      }
      rethrow; // Tekrar fırlat ki üst katmanda yakalanabilsin
    }
  }

  // Taramayı duraklatıp devam ettir
  void _togglePause() {
    if (_isProcessing)
      return; // İşlem sırasında duraklat/devam et tuşunu devre dışı bırak

    if (_isPaused) {
      _resumeScan();
    } else {
      _pauseScan();
    }

    // setState çağrılarını minimize etmek için tek bir güncelleme yapıyoruz
    if (mounted) {
      setState(() {
        _isPaused = !_isPaused;
      });
    }
  }

  // Taramayı duraklat
  Future<void> _pauseScan() async {
    try {
      await methodChannel.invokeMethod<void>('pauseScan');
      logger.debug('Tarama duraklatıldı', tag: 'ScannerScreen');
    } catch (e) {
      logger.error('Tarama duraklatma hatası', exception: e);
    }
  }

  // Taramayı devam ettir
  Future<void> _resumeScan() async {
    try {
      await methodChannel.invokeMethod<void>('resumeScan');
      logger.debug('Tarama devam ettirildi', tag: 'ScannerScreen');
    } catch (e) {
      logger.error('Tarama devam ettirme hatası', exception: e);
    }
  }

  // Taramayı sıfırla
  Future<void> _resetScan() async {
    if (_isProcessing)
      return; // İşlem sırasında sıfırlama tuşunu devre dışı bırak

    try {
      await methodChannel.invokeMethod<void>('resetScan');

      final scanState = Provider.of<ScanState>(context, listen: false);
      scanState.reset();

      if (mounted) {
        setState(() {
          _isPaused = false;
          _showCompleteScanButton = false;
        });
      }

      logger.info('Tarama sıfırlandı', tag: 'ScannerScreen');
    } catch (e) {
      logger.error('Tarama sıfırlama hatası', exception: e);
      _showError('Sıfırlama hatası', e.toString());
    }
  }

  // Tarama olaylarını dinle - state güncellemeleri ve performans optimizasyonu
  void _listenToScanEvents() {
    _scanEventSubscription = scanEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map || !mounted) {
          return;
        }

        final eventType = event['type'] as String?;

        // UI güncellemelerini tek bir setState içinde yapmaya çalışıyoruz
        // Ancak bazı durumlarda birden fazla setState çağrısı gerekebilir

        _handleScanEvent(eventType, event);
      },
      onError: (error) {
        logger.error('Event channel hatası', exception: error);
      },
      onDone: () {
        logger.info('Scan event stream kapandı', tag: 'ScannerScreen');
      },
    );
  }

  // Tarama olaylarını handle et - daha modüler kod yapısı için
  void _handleScanEvent(String? eventType, Map event) {
    if (!mounted) return;

    final scanState = Provider.of<ScanState>(context, listen: false);

    switch (eventType) {
      case 'scanProgress':
        _handleScanProgressEvent(scanState, event);
        break;

      case 'guidance':
        _handleGuidanceEvent(scanState, event);
        break;

      case 'scanStatus':
        _handleScanStatusEvent(scanState, event);
        break;

      case 'error':
        _handleErrorEvent(scanState, event);
        break;
    }
  }

  // Tarama ilerleme olayını handle et
  void _handleScanProgressEvent(ScanState scanState, Map event) {
    final progress = event['progress'] as double? ?? 0.0;
    final completedSegments = event['completedSegments'] as int? ?? 0;
    final totalSegments = event['totalSegments'] as int? ?? 0;

    // UI güncellemesi
    if (mounted) {
      setState(() {
        scanState.updateProgress(progress);
        if (totalSegments > 0) {
          scanState.updateScanCoverage(completedSegments, totalSegments);
        }
      });
    }
  }

  // Rehberlik olayını handle et
  void _handleGuidanceEvent(ScanState scanState, Map event) {
    final message = event['message'] as String? ?? '';

    if (mounted) {
      setState(() {
        scanState.updateGuidanceMessage(message);
      });
    }
  }

  // Tarama durumu olayını handle et
  void _handleScanStatusEvent(ScanState scanState, Map event) {
    final status = event['status'] as String? ?? '';

    switch (status) {
      case 'completed':
        _processAndExportModel();
        break;

      case 'failed':
        final message = event['message'] as String? ?? 'Bilinmeyen hata';
        if (mounted) {
          setState(() {
            scanState.updateGuidanceMessage('Tarama hatası: $message');
          });
        }
        break;

      case 'readyToComplete':
        if (scanState.isFullyCovered) {
          _processAndExportModel();
        } else if (mounted) {
          setState(() {
            scanState.updateGuidanceMessage(
                'Tarama hazır! Tamamlamak için butona basın.');
            _showCompleteScanButton = true;
          });
        }
        break;
    }
  }

  // Hata olayını handle et
  void _handleErrorEvent(ScanState scanState, Map event) {
    final message = event['message'] as String? ?? 'Bilinmeyen hata';

    logger.error('Tarama hatası: $message', tag: 'ScannerScreen');

    if (mounted) {
      setState(() {
        scanState.updateGuidanceMessage('Hata: $message');
      });
    }
  }

  // 3D modeli işle ve view ekranına git - optimize edilmiş
  Future<void> _processAndExportModel() async {
    if (_isProcessing) return; // Zaten işlem yapılıyorsa tekrar başlatma

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      logger.info('Model işleniyor...', tag: 'ScannerScreen');

      final result =
          await scanServiceChannel.invokeMethod<Map<dynamic, dynamic>>(
        'processAndExportModel',
      );

      if (result != null && result.containsKey('modelPath')) {
        final modelPath = result['modelPath'] as String;
        logger.info('3D model oluşturuldu: $modelPath', tag: 'ScannerScreen');

        // İşlem tamamlandı, model görüntüleme ekranına git
        if (mounted) {
          // ScanState'i güncelle
          final scanState = Provider.of<ScanState>(context, listen: false);
          scanState.completeScan(modelPath);

          setState(() {
            _isProcessing = false;
          });

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
      logger.error('Model işleme hatası', exception: e);
      if (mounted) {
        // Hata durumunda ScanState'i güncelle
        final scanState = Provider.of<ScanState>(context, listen: false);
        scanState.failScan('Model işlenirken bir hata oluştu: $e');

        setState(() {
          _isProcessing = false;
        });

        _showError(
            'Model oluşturma hatası', 'Model işlenirken bir hata oluştu: $e');
      }
    }
  }

  // Hata göster - tekrar kullanılabilir yardımcı metod
  void _showError(String title, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Detaylar',
            onPressed: () => _showErrorDialog(title, message),
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  // ScanProgressIndicator içinde tamamlama butonunu ekle
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Tarayıcı'),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: Stack(
        children: [
          // AR view platform view
          SizedBox.expand(
            child: Platform.isIOS
                ? UiKitView(
                    viewType: 'lidar_flutter/ar_view',
                    onPlatformViewCreated: (int id) {
                      logger.info('ARKit view oluşturuldu: $id',
                          tag: 'ScannerScreen');
                    },
                    creationParams: <String, dynamic>{
                      'enableLiDAR': true,
                      'enableMesh': true,
                    },
                    creationParamsCodec: const StandardMessageCodec(),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                          'Bu cihaz AR tarama özelliklerini desteklemiyor',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
          ),

          // Overlay for scan progress and guidance
          SafeArea(
            child: Column(
              children: [
                // Guidance at the top
                Consumer<ScanState>(
                  builder: (context, scanState, child) {
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
                          scanState.guidanceMessage,
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
                Consumer<ScanState>(
                  builder: (context, scanState, child) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Sıfırlama butonu
                          _buildActionButton(
                            icon: Icons.refresh,
                            label: 'Sıfırla',
                            onTap: _resetScan,
                          ),

                          // Duraklat/Devam butonu
                          _buildActionButton(
                            icon: _isPaused ? Icons.play_arrow : Icons.pause,
                            label: _isPaused ? 'Devam' : 'Duraklat',
                            onTap: _togglePause,
                          ),

                          // Tamamla butonu
                          if (_showCompleteScanButton)
                            _buildActionButton(
                              icon: Icons.check_circle,
                              label: 'Tamamla',
                              onTap: _processAndExportModel,
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
          if (_isProcessing)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '3D Model Oluşturuluyor...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Colors.blue.withOpacity(0.8)
              : Colors.grey.withOpacity(0.3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
