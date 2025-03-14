import 'package:flutter/material.dart';

class ScanProgressWidget extends StatelessWidget {
  final double progress;
  final String message;
  final bool isPaused;

  const ScanProgressWidget({
    Key? key,
    required this.progress,
    required this.message,
    this.isPaused = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isPaused)
                const Icon(
                  Icons.pause_circle_filled,
                  color: Colors.amber,
                  size: 24,
                )
              else
                const Icon(
                  Icons.radar,
                  color: Colors.greenAccent,
                  size: 24,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              isPaused ? Colors.amber : Colors.greenAccent,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          if (isPaused)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Scanning paused. Tap play to continue.',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
