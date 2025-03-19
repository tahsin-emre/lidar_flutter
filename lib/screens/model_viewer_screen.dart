import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../services/logger_service.dart';

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
  bool _isProcessing = false; // İşlem yapılıyor mu?

  @override
  void initState() {
    super.initState();
    Future.microtask(_prepareModel);
  }

  Future<void> _prepareModel() async {
    try {
      // Model dosyasının var olduğunu kontrol et
      final file = File(widget.modelPath);
      if (!await file.exists()) {
        logger.error('Model dosyası bulunamadı: ${widget.modelPath}',
            tag: 'ModelViewer');
        if (mounted) {
          _showError('Model dosyası bulunamadı');
        }
        return;
      }

      modelName = path.basename(widget.modelPath);
      logger.info('Model yükleniyor: $modelName', tag: 'ModelViewer');

      // Modeli yüklemeden önce kısa bir gecikme (UI için)
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.error('Model hazırlama hatası', exception: e, tag: 'ModelViewer');
      if (mounted) {
        _showError('Model hazırlanırken bir hata oluştu: $e');
      }
    }
  }

  Future<void> _shareModel() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final filePath = widget.modelPath;
      final file = XFile(filePath);

      logger.info('Model paylaşılıyor: $filePath', tag: 'ModelViewer');

      await Share.shareXFiles(
        [file],
        text: '3D Tarama Modelim: $modelName',
      );
    } catch (e) {
      logger.error('Model paylaşma hatası', exception: e, tag: 'ModelViewer');
      if (mounted) {
        _showError('Paylaşım sırasında bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveModel() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final saveDir = path.join(directory.path, 'saved_models');
      final savedPath = path.join(saveDir, modelName);

      // Dizini oluştur
      final saveDirObj = Directory(saveDir);
      if (!await saveDirObj.exists()) {
        await saveDirObj.create(recursive: true);
      }

      // Dosya zaten var mı kontrol et
      final saveFile = File(savedPath);
      if (await saveFile.exists()) {
        // Dosya zaten varsa yeniden adlandır
        final fileExt = path.extension(modelName);
        final fileName = path.basenameWithoutExtension(modelName);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newName = '${fileName}_$timestamp$fileExt';
        final newPath = path.join(saveDir, newName);

        // Dosyayı kopyala
        await File(widget.modelPath).copy(newPath);

        if (mounted) {
          _showSuccess('Model farklı bir isimle kaydedildi: $newName');
        }
      } else {
        // Dosyayı kopyala
        await File(widget.modelPath).copy(savedPath);

        if (mounted) {
          _showSuccess('Model başarıyla kaydedildi: $modelName');
        }
      }

      logger.info('Model kaydedildi: $savedPath', tag: 'ModelViewer');
    } catch (e) {
      logger.error('Model kaydetme hatası', exception: e, tag: 'ModelViewer');
      if (mounted) {
        _showError('Kaydetme sırasında bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Model Görüntüleyici'),
        actions: [
          if (!_isLoading && !_isProcessing) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareModel,
              tooltip: 'Modeli Paylaş',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveModel,
              tooltip: 'Modeli Kaydet',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ModelViewer(
                        backgroundColor:
                            const Color.fromARGB(255, 230, 230, 230),
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

                // İşlem göstergesi
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
