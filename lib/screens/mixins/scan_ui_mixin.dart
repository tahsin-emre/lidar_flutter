import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../services/logger_service.dart';

mixin ScanUIMixin<T extends StatefulWidget> on State<T> {
  Widget buildActionButton({
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

  Widget buildARView() {
    return SizedBox.expand(
      child: Platform.isIOS
          ? UiKitView(
              viewType: 'lidar_flutter/ar_view',
              onPlatformViewCreated: (int id) {
                logger.logInfo('ARKit view oluşturuldu: $id',
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
                child: Text('Bu cihaz AR tarama özelliklerini desteklemiyor',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
    );
  }

  Widget buildProcessingOverlay() {
    return Container(
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
    );
  }
}
