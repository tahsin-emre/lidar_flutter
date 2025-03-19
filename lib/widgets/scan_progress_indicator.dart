import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/scan_cubit.dart';

class ScanProgressIndicator extends StatelessWidget {
  final VoidCallback? onPauseTap;
  final VoidCallback? onResetTap;
  final VoidCallback? onCompleteTap;

  const ScanProgressIndicator({
    Key? key,
    this.onPauseTap,
    this.onResetTap,
    this.onCompleteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0.7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              if (state.isScanning)
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),

              const SizedBox(height: 16),

              // Status message
              Text(
                state.statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Action buttons
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
                      icon: state.isPaused ? Icons.play_arrow : Icons.pause,
                      label: state.isPaused ? 'Devam' : 'Duraklat',
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
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          color: primary ? Colors.green : Colors.white,
          onPressed: onTap,
        ),
        Text(
          label,
          style: TextStyle(
            color: primary ? Colors.green : Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
