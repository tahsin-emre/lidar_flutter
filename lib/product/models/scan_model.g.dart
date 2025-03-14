// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanModel _$ScanModelFromJson(Map<String, dynamic> json) => ScanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      thumbnailPath: json['thumbnailPath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ScanModelToJson(ScanModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'filePath': instance.filePath,
      'createdAt': instance.createdAt.toIso8601String(),
      'thumbnailPath': instance.thumbnailPath,
      'metadata': instance.metadata,
    };
