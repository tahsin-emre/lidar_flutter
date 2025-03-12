import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lidar_flutter/state/scan_state.dart';
import 'package:lidar_flutter/widgets/scan_progress_indicator.dart';
import 'package:lidar_flutter/screens/model_viewer_screen.dart';
import 'package:arkit_plugin/arkit_plugin.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final MethodChannel platform = const MethodChannel(
    'com.example.lidar_flutter/scanner',
  );

  // AR Scanner channel
  final MethodChannel arScanChannel = const MethodChannel(
    'lidar_flutter/ar_scanner',
  );

  // Scan service channel
  final MethodChannel scanServiceChannel = const MethodChannel(
    'lidar_flutter/scan_service',
  );
  bool _isInitialized = false;
  bool _isPaused = false;
  dynamic _arController; // can be ARKitController on iOS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_initializeAR);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAR();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseAR();
    } else if (state == AppLifecycleState.resumed) {
      _resumeAR();
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

  Future<bool> _checkLiDARSupport() async {
    try {
      final bool hasLiDAR = await arScanChannel.invokeMethod('supportsLiDAR');
      return hasLiDAR;
    } catch (e) {
      print('Error checking LiDAR support: $e');
      return false;
    }
  }

  // AR görünümü initialize etme
  void _initializeAR() async {
    final scanState = Provider.of<ScanState>(context, listen: false);
    scanState.reset();

    try {
      // Cihaz desteğini kontrol et
      final bool hasSupport =
          await scanServiceChannel.invokeMethod('checkDeviceSupport');

      if (!hasSupport) {
        scanState.failScan('Your device does not support LiDAR or Depth API.');
        return;
      }

      // AR oturumu başlat
      await scanServiceChannel.invokeMethod('initializeScan');

      // Durumu güncelle
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing AR: $e');
      scanState.failScan('Failed to initialize scanner. ${e.toString()}');
    }
  }

  void _onARKitViewCreated(ARKitController controller) {
    _arController = controller;

    try {
      // Point cloud verileri için dinleyici ekle
      controller.onAddNodeForAnchor = _handleAddAnchorNode;

      // LiDAR desteğini kontrol et ve ARKit oturumunu ayarla
      _checkLiDARSupport().then((hasLiDAR) {
        print("LiDAR desteği: $hasLiDAR");

        // ARKit konfigürasyonu gönder
        if (hasLiDAR) {
          try {
            // iOS 14+ için konfigürasyon ayarla
            arScanChannel.invokeMethod(
                'setupARKitConfig', {'enableLiDAR': true, 'enableMesh': true});
          } catch (e) {
            print("ARKit yapılandırma hatası: $e");
          }
        }

        // Tarama durumunu güncelle
        final scanState = Provider.of<ScanState>(context, listen: false);
        scanState.updateProgress(0.0, 'Ready to scan. Move around the object.');
      });
    } catch (e) {
      print("ARKit controller oluşturma hatası: $e");
    }
  }

  void _handleAddAnchorNode(ARKitAnchor anchor) {
    // ARKit için anchor eklendiğinde haberdar ol
    print('Anchor added: ${anchor.identifier}');

    try {
      // Anchor tipini tespit et - basit bir kontrol
      if (anchor is ARKitPlaneAnchor) {
        // Düzlem algılandı
        print('Düzlem algılandı: ${anchor.identifier}');

        // Düzlemin boyutu hakkında bilgi
        final ARKitPlaneAnchor planeAnchor = anchor;
        print('Düzlem boyutu: ${planeAnchor.extent}');
      } else {
        // Diğer anchor tipleri
        print('Diğer anchor tipi algılandı');
      }
    } catch (e) {
      print("Anchor işleme hatası: $e");
    }
  }

  void _startScan() async {
    final scanState = Provider.of<ScanState>(context, listen: false);
    scanState.startScan();

    try {
      await scanServiceChannel.invokeMethod('startScan');

      // Simüle tarama ilerleme güncellemeleri başlat
      _simulateScanProgress();
    } catch (e) {
      print('Error starting scan: $e');
      scanState.failScan('Failed to start scan: ${e.toString()}');
    }
  }

  void _pauseAR() async {
    setState(() {
      _isPaused = true;
    });

    // AR oturumunu duraklat
    if (_arController != null) {
      if (Platform.isIOS) {
        // ArKit pause işlemi
        arScanChannel.invokeMethod('pauseSession');
      } else {
        scanServiceChannel.invokeMethod('pauseScan');
      }
    }
  }

  void _resumeAR() async {
    setState(() {
      _isPaused = false;
    });

    // AR oturumunu devam ettir
    if (_arController != null) {
      if (Platform.isIOS) {
        // ArKit resume işlemi
        arScanChannel.invokeMethod('resumeSession');
      } else {
        scanServiceChannel.invokeMethod('resumeScan');
      }
    }
  }

  void _completeScan() async {
    final scanState = Provider.of<ScanState>(context, listen: false);

    try {
      final result = await scanServiceChannel.invokeMethod('completeScan');

      if (result != null && result['modelPath'] != null) {
        // 3D modeli görüntülemek için modeli tamamla ve yolu kaydet
        scanState.completeScan(result['modelPath']);
      }
    } catch (e) {
      print('Error completing scan: $e');
      scanState.failScan('Failed to complete scan: ${e.toString()}');
    }
  }

  void _cancelScan() {
    // Taramayı iptal et ve AR oturumunu kapat
    scanServiceChannel.invokeMethod('cancelScan');

    final scanState = Provider.of<ScanState>(context, listen: false);
    scanState.reset();

    // Ekranı kapat
    Navigator.pop(context);
  }

  // İlerlemeyi simüle et (gerçek uygulamada, platform kanalı üzerinden ilerleme güncellemeleri alınır)
  void _simulateScanProgress() async {
    final scanState = Provider.of<ScanState>(context, listen: false);
    double progress = 0.0;

    // Her 500ms'de bir ilerleme güncelle
    while (progress < 1.0 && mounted && !_isPaused) {
      await Future.delayed(const Duration(milliseconds: 500));
      progress += 0.05;
      if (progress > 1.0) progress = 1.0;

      String message = 'Scanning...';
      if (progress < 0.3) {
        message = 'Start moving around the object...';
      } else if (progress < 0.7) {
        message = 'Continue scanning all sides...';
      } else {
        message = 'Almost done, capturing details...';
      }

      scanState.updateProgress(progress, message);
    }
  }

  // AR görünümü oluşturma metodu
  Widget _buildARView() {
    if (Platform.isIOS) {
      try {
        return ARKitSceneView(
          onARKitViewCreated: _onARKitViewCreated,
          enableTapRecognizer: true,
          showStatistics: true,
          enablePinchRecognizer: true,
          enablePanRecognizer: true,
          enableRotationRecognizer: true,
          configuration: ARKitConfiguration.worldTracking,
        );
      } catch (e) {
        print("ARKit View oluşturma hatası: $e");
        // ARKit plugin hatası durumunda yedek görünüm
        return Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              'LiDAR hatası. Cihazınız LiDAR sensörü ile donatılmış mı?',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } else {
      // Android için AR görünümü (gerçekte ARCore widget'ı kullanılacak)
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Android ARCore taraması bu sürümde etkinleştirilmemiş.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Scanner'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: _cancelScan),
        ],
      ),
      body: Consumer<ScanState>(
        builder: (context, scanState, child) {
          // Make sure scanState is not null before accessing properties
          if (scanState != null && scanState.isFailed) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Scan Failed',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      scanState.errorMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeAR,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (scanState != null &&
              scanState.isCompleted &&
              scanState.modelPath != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 48, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Scan Completed!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Your 3D model is ready to view.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to model viewer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModelViewerScreen(
                            modelPath: scanState.modelPath!,
                            modelName: 'Scanned Object',
                          ),
                        ),
                      );
                    },
                    child: const Text('View Model'),
                  ),
                ],
              ),
            );
          }

          // AR Scanning View
          return Stack(
            children: [
              // AR View implementation
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _isInitialized
                    ? _buildARView()
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Initializing scanner...'),
                          ],
                        ),
                      ),
              ),

              // Bottom controls
              if (_isInitialized)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ScanProgressIndicator(
                        onStartScan: _startScan,
                        onPauseScan: _pauseAR,
                        onResumeScan: _resumeAR,
                        onCompleteScan: _completeScan,
                        onCancelScan: _cancelScan,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
