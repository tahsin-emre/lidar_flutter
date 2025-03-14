import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// import 'package:share_plus/share_plus.dart';

class ModelViewerScreen extends StatefulWidget {
  final String modelPath;

  const ModelViewerScreen({
    Key? key,
    required this.modelPath,
  }) : super(key: key);

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  late String modelName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prepareModel();
  }

  void _prepareModel() {
    modelName = path.basename(widget.modelPath);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _shareModel() async {
    // Share.shareXFiles() yerine basit bir SnackBar gösterelim
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modeli paylaş: ${widget.modelPath}')),
      );
    }
  }

  Future<void> _saveModel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final savedPath = path.join(directory.path, 'saved_models', modelName);

      // Dizini oluştur
      final saveDir = Directory(path.dirname(savedPath));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Dosyayı kopyala
      await File(widget.modelPath).copy(savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model başarıyla kaydedildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme hatası: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Model Görüntüleyici'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareModel,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveModel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ModelViewer(
                    backgroundColor: const Color.fromARGB(255, 230, 230, 230),
                    src: 'file://${widget.modelPath}',
                    alt: '3D Model',
                    ar: true,
                    arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                    autoRotate: true,
                    cameraControls: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Model: $modelName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
