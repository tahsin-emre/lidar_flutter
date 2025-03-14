import 'package:flutter/material.dart';

class AROverlayInstructions extends StatelessWidget {
  const AROverlayInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top instruction card
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            color: const Color.fromRGBO(0, 0, 0, 0.7),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scanning Instructions',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionStep(
                    icon: Icons.check_circle_outline,
                    text: 'Place your object on a flat surface',
                  ),
                  _buildInstructionStep(
                    icon: Icons.check_circle_outline,
                    text: 'Keep a distance of 1-2 feet from the object',
                  ),
                  _buildInstructionStep(
                    icon: Icons.check_circle_outline,
                    text: 'Move slowly around the object for a complete scan',
                  ),
                  _buildInstructionStep(
                    icon: Icons.check_circle_outline,
                    text: 'Watch for visual cues to scan incomplete areas',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Visual guidance areas (simulating AR visual cues)
        // In a real app, these would be rendered in AR space directly
        // based on the scanning progress
        Positioned(
          top: MediaQuery.of(context).size.height / 3,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: _buildARVisualCue(
            icon: Icons.arrow_downward,
            label: 'Scan Here',
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARVisualCue({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(33, 150, 243, 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
