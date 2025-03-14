import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:lidar_flutter/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_flutter/feature/scanner/widget/scan_progress_widget.dart';
import 'package:lidar_flutter/product/init/di/locator.dart';
import 'package:lidar_flutter/product/services/scanner_service.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({Key? key}) : super(key: key);

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  late final ScannerCubit _scannerCubit;
  dynamic _arController; // can be ARKitController on iOS
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerCubit = locator<ScannerCubit>();
    _scannerCubit.initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAR();
    _scannerCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _scannerCubit.pauseScan();
    } else if (state == AppLifecycleState.resumed) {
      _scannerCubit.resumeScan();
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

  void _onARKitViewCreated(ARKitController controller) {
    _arController = controller;
    final scannerService = locator<ScannerService>();

    try {
      // Point cloud verileri için dinleyici ekle
      controller.onAddNodeForAnchor = _handleAddAnchorNode;

      // LiDAR desteğini kontrol et ve ARKit oturumunu ayarla
      scannerService.checkLiDARSupport().then((hasLiDAR) {
        print("LiDAR desteği: $hasLiDAR");

        // ARKit konfigürasyonu gönder
        if (hasLiDAR) {
          try {
            scannerService.setupARKitConfig(
                enableLiDAR: true, enableMesh: true);
          } catch (e) {
            print("ARKit yapılandırma hatası: $e");
          }
        }

        setState(() {
          _isInitialized = true;
        });
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerCubit, ScannerState>(
      bloc: _scannerCubit,
      listener: (context, state) {
        if (state is ScannerCompletedState) {
          // Navigate to model viewer
          context.pushNamed(
            'model-viewer',
            queryParameters: {
              'modelPath': state.modelPath,
              'modelName': 'Scanned Object',
            },
          );
        } else if (state is ScannerErrorState) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('3D Scanner'),
            centerTitle: true,
            actions: [
              if (state is ScannerScanningState || state is ScannerPausedState)
                IconButton(
                  icon: Icon(
                    state is ScannerPausedState
                        ? Icons.play_arrow
                        : Icons.pause,
                  ),
                  onPressed: () {
                    if (state is ScannerPausedState) {
                      _scannerCubit.resumeScan();
                    } else {
                      _scannerCubit.pauseScan();
                    }
                  },
                ),
            ],
          ),
          body: Stack(
            children: [
              // AR View
              if (Platform.isIOS)
                ARKitSceneView(
                  onARKitViewCreated: _onARKitViewCreated,
                  enableTapRecognizer: true,
                ),
              // Android would use ARCore here

              // UI Overlay
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status and progress
                      if (state is ScannerScanningState ||
                          state is ScannerPausedState)
                        ScanProgressWidget(
                          progress: state is ScannerScanningState
                              ? state.progress
                              : (state as ScannerPausedState).progress,
                          message: state is ScannerScanningState
                              ? state.message
                              : (state as ScannerPausedState).message,
                          isPaused: state is ScannerPausedState,
                        ),

                      const Spacer(),

                      // Action buttons
                      if (state is ScannerReadyState)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera),
                          label: const Text('Start Scanning'),
                          onPressed: () => _scannerCubit.startScan(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      else if (state is ScannerScanningState)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Complete Scan'),
                          onPressed: () => _scannerCubit.completeScan(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Cancel button
                      if (state is! ScannerInitialState &&
                          state is! ScannerLoadingState)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          onPressed: () {
                            _scannerCubit.cancelScan();
                            context.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Loading indicator
              if (state is ScannerLoadingState)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
