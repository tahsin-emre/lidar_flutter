import 'package:flutter/material.dart';
import '../state/scan_state.dart';

class ScanProgressIndicator extends StatelessWidget {
  final ScanState scanState;
  final VoidCallback? onPauseTap;
  final VoidCallback? onResetTap;
  final VoidCallback? onCompleteTap;

  const ScanProgressIndicator({
    Key? key,
    required this.scanState,
    this.onPauseTap,
    this.onResetTap,
    this.onCompleteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 0.7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // İlerleme çubuğu
          LinearProgressIndicator(
            value: scanState.progress,
            backgroundColor: Colors.grey[800],
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),

          const SizedBox(height: 8),

          // İlerleme yüzdesi ve 360 derece bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // İlerleme yüzdesi
              Text(
                '${(scanState.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // 360 derece segment bilgisi
              if (scanState.completedSegments > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.rotate_right,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${scanState.completedSegments}/${scanState.totalSegments}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Sıfırla butonu
              if (onResetTap != null)
                _buildIconButton(
                  icon: Icons.refresh,
                  label: 'Sıfırla',
                  onTap: onResetTap!,
                ),

              // Duraklat/Devam butonu
              if (onPauseTap != null)
                _buildIconButton(
                  icon: scanState.isPaused ? Icons.play_arrow : Icons.pause,
                  label: scanState.isPaused ? 'Devam' : 'Duraklat',
                  onTap: onPauseTap!,
                ),

              // Tamamla butonu
              if (onCompleteTap != null)
                _buildIconButton(
                  icon: Icons.check_circle,
                  label: 'Tamamla',
                  onTap: onCompleteTap!,
                  primary: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primary
              ? const Color.fromRGBO(33, 150, 243, 0.8)
              : const Color.fromRGBO(158, 158, 158, 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
