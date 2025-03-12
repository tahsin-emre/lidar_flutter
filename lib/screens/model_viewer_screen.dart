import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelViewerScreen extends StatelessWidget {
  final String modelPath;
  final String modelName;

  const ModelViewerScreen({
    Key? key,
    required this.modelPath,
    required this.modelName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(modelName),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareModel),
        ],
      ),
      body: ModelViewer(
        src: modelPath,
        alt: 'A 3D model of $modelName',
        ar: true,
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }

  void _shareModel() {
    // In a real app, implement sharing functionality here
    print('Sharing model: $modelPath');
  }
}
