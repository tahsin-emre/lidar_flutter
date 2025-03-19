import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_flutter/screens/mixin/scanner_mixin.dart';
import '../bloc/scan_cubit.dart';
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
        ScannerMixin<ScannerScreen>,
        WidgetsBindingObserver,
        ARScannerMixin<ScannerScreen>,
        ScanStateMixin<ScannerScreen>,
        ScanEventMixin<ScannerScreen>,
        ScanUIMixin<ScannerScreen> {
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
