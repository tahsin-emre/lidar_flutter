import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../state/scan_state.dart';
import '../widgets/scan_progress_indicator.dart';
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

  // Logger tanımı
  final _devLog = kDebugMode ? print : (String message) {};

  bool _isPaused = false;
  bool _isProcessing = false;
  bool _showCompleteScanButton = false;
  dynamic _arController; // can be ARKitController on iOS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initARScanner();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToScanEvents();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseScan(); // Taramayı durdur
    _disposeAR();
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
    if (_arController != null) {
      if (Platform.isIOS) {
        (_arController as ARKitController).dispose();
      }
      _arController = null;
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

      _devLog('ARKit yapılandırması: $result');

      if (result) {
        // Tarama başlatma
        final scanResult =
            await scanServiceChannel.invokeMethod<bool>('initializeScan') ??
                false;

        if (scanResult) {
          _devLog('Tarama başlatıldı');
          // AR oturumunu başlat
          await methodChannel.invokeMethod<bool>('startScanning');
        }
      }
    } catch (e) {
      _devLog('ARKit başlatma hatası: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AR tarayıcı başlatılamadı: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Taramayı duraklatıp devam ettir
  void _togglePause() {
    if (_isPaused) {
      _resumeScan();
    } else {
      _pauseScan();
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  // Taramayı duraklat
  Future<void> _pauseScan() async {
    try {
      await methodChannel.invokeMethod<void>('pauseScan');
    } catch (e) {
      _devLog('Error pausing scan: $e');
    }
  }

  // Taramayı devam ettir
  Future<void> _resumeScan() async {
    try {
      await methodChannel.invokeMethod<void>('resumeScan');
    } catch (e) {
      _devLog('Error resuming scan: $e');
    }
  }

  // Taramayı sıfırla
  Future<void> _resetScan() async {
    try {
      await methodChannel.invokeMethod<void>('resetScan');
      setState(() {
        _isPaused = false;
        _showCompleteScanButton = false;
      });
    } catch (e) {
      _devLog('Error resetting scan: $e');
    }
  }

  // Tarama olaylarını dinle
  void _listenToScanEvents() {
    scanEventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is! Map) {
        return;
      }
      if (!mounted) {
        return; // Eğer widget artık build ağacında değilse, işlemleri atlayalım
      }

      final scanState = Provider.of<ScanState>(context, listen: false);
      final eventType = event['type'] as String?;

      switch (eventType) {
        case 'scanProgress':
          final progress = event['progress'] as double? ?? 0.0;
          final completedSegments = event['completedSegments'] as int? ?? 0;
          final totalSegments = event['totalSegments'] as int? ?? 0;

          if (mounted) {
            setState(() {
              scanState.updateProgress(progress);

              // 360 derece tamamlanma durumunu güncelle
              if (totalSegments > 0) {
                scanState.updateScanCoverage(completedSegments, totalSegments);
              }
            });
          }
          break;

        case 'guidance':
          final message = event['message'] as String? ?? '';
          if (mounted) {
            setState(() {
              scanState.updateGuidanceMessage(message);
            });
          }
          break;

        case 'scanStatus':
          final status = event['status'] as String? ?? '';

          if (status == 'completed') {
            // Otomatik tarama tamamlandı, 3D modeli oluştur
            _processAndExportModel();
          } else if (status == 'failed') {
            final message = event['message'] as String? ?? 'Bilinmeyen hata';
            if (mounted) {
              setState(() {
                scanState.updateGuidanceMessage('Tarama hatası: $message');
              });
            }
          } else if (status == 'readyToComplete') {
            // Tam 360 derece tarama tamamlandıysa
            if (scanState.isFullyCovered) {
              _processAndExportModel();
            } else {
              if (mounted) {
                setState(() {
                  scanState.updateGuidanceMessage(
                      'Tarama hazır! Tamamlamak için butona basın.');
                  _showCompleteScanButton = true;
                });
              }
            }
          }
          break;

        case 'error':
          final message = event['message'] as String? ?? 'Bilinmeyen hata';
          if (mounted) {
            setState(() {
              scanState.updateGuidanceMessage('Hata: $message');
            });
          }
          break;
      }
    }, onError: (error) {
      _devLog('Event channel error: $error');
    });
  }

  // 3D modeli işle ve view ekranına git
  Future<void> _processAndExportModel() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result =
          await scanServiceChannel.invokeMethod<Map<dynamic, dynamic>>(
        'processAndExportModel',
      );

      if (result != null && result.containsKey('modelPath')) {
        final modelPath = result['modelPath'] as String;
        _devLog('3D model oluşturuldu: $modelPath');

        // İşlem tamamlandı, model görüntüleme ekranına git
        if (mounted) {
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
      _devLog('Model işleme hatası: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        _showErrorDialog(
            'Model oluşturma hatası', 'Model işlenirken bir hata oluştu: $e');
      }
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
                      _devLog('ARKit view oluşturuldu: $id');
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
