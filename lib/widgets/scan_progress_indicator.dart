import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lidar_flutter/state/scan_state.dart';

class ScanProgressIndicator extends StatelessWidget {
  final VoidCallback onStartScan;
  final VoidCallback onPauseScan;
  final VoidCallback onResumeScan;
  final VoidCallback onCompleteScan;
  final VoidCallback onCancelScan;

  const ScanProgressIndicator({
    Key? key,
    required this.onStartScan,
    required this.onPauseScan,
    required this.onResumeScan,
    required this.onCompleteScan,
    required this.onCancelScan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanState>(
      builder: (context, scanState, child) {
        // Tarama başlamadıysa başlat butonu göster
        if (scanState.status == ScanningStatus.notStarted) {
          return _buildStartButton();
        }

        // Tarama devam ediyorsa ilerleme göstergesi ve kontrol butonlarını göster
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(
                value: scanState.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scanState.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCancelButton(),
                scanState.isScanning
                    ? _buildPauseButton()
                    : _buildResumeButton(),
                _buildCompleteButton(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Scan'),
      onPressed: onStartScan,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildPauseButton() {
    return IconButton(
      icon: const Icon(Icons.pause),
      onPressed: onPauseScan,
      tooltip: 'Pause Scan',
    );
  }

  Widget _buildResumeButton() {
    return IconButton(
      icon: const Icon(Icons.play_arrow),
      onPressed: onResumeScan,
      tooltip: 'Resume Scan',
    );
  }

  Widget _buildCompleteButton() {
    return IconButton(
      icon: const Icon(Icons.check),
      onPressed: onCompleteScan,
      tooltip: 'Complete Scan',
    );
  }

  Widget _buildCancelButton() {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: onCancelScan,
      tooltip: 'Cancel Scan',
    );
  }
}
