import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ModelService {
  // Model service channel
  final MethodChannel _modelServiceChannel = const MethodChannel(
    'lidar_flutter/model_service',
  );

  // Get model file path
  Future<String> getModelFilePath(String modelName) async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'models', '$modelName.usdz');
  }

  // Save model to file
  Future<String> saveModel(String modelData, String modelName) async {
    try {
      final modelPath = await getModelFilePath(modelName);
      final modelDir = Directory(path.dirname(modelPath));

      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final file = File(modelPath);
      await file.writeAsBytes(modelData.codeUnits);
      return modelPath;
    } catch (e) {
      print('Error saving model: $e');
      throw Exception('Failed to save model: ${e.toString()}');
    }
  }

  // Export model to different format
  Future<String?> exportModel(String sourcePath, String format) async {
    try {
      final result = await _modelServiceChannel.invokeMethod(
        'exportModel',
        {
          'sourcePath': sourcePath,
          'format': format,
        },
      );
      return result['exportPath'];
    } catch (e) {
      print('Error exporting model: $e');
      return null;
    }
  }

  // Share model
  Future<bool> shareModel(String modelPath) async {
    try {
      final result = await _modelServiceChannel.invokeMethod(
        'shareModel',
        {'modelPath': modelPath},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error sharing model: $e');
      return false;
    }
  }

  // List saved models
  Future<List<String>> getSavedModels() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory(path.join(directory.path, 'models'));

      if (!await modelsDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> entities = await modelsDir.list().toList();
      return entities
          .whereType<File>()
          .map((file) => path.basename(file.path))
          .toList();
    } catch (e) {
      print('Error getting saved models: $e');
      return [];
    }
  }

  // Delete model
  Future<bool> deleteModel(String modelPath) async {
    try {
      final file = File(modelPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting model: $e');
      return false;
    }
  }
}
