import 'package:flutter/material.dart';
import 'ar_scanner_mixin.dart';

mixin ScanStateMixin<T extends StatefulWidget> on State<T>, ARScannerMixin<T> {
  bool _isPaused = false;
  bool _isProcessing = false;
  bool _showCompleteScanButton = false;

  bool get isPaused => _isPaused;
  bool get isProcessing => _isProcessing;
  bool get showCompleteScanButton => _showCompleteScanButton;

  void togglePause() {
    if (_isProcessing) return;

    if (_isPaused) {
      resumeScan();
    } else {
      pauseScan();
    }

    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void setProcessing(bool value) {
    setState(() {
      _isProcessing = value;
    });
  }

  void setShowCompleteScanButton(bool value) {
    setState(() {
      _showCompleteScanButton = value;
    });
  }

  void showError(String title, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Detaylar',
          onPressed: () => showErrorDialog(title, message),
          textColor: Colors.white,
        ),
      ),
    );
  }

  void showErrorDialog(String title, String message) {
    if (!mounted) return;

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
