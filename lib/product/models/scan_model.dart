import 'package:json_annotation/json_annotation.dart';

part 'scan_model.g.dart';

@JsonSerializable()
class ScanModel {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final String? thumbnailPath;
  final Map<String, dynamic>? metadata;

  ScanModel({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    this.thumbnailPath,
    this.metadata,
  });

  // Factory constructor for creating a new ScanModel with a unique ID and current timestamp
  factory ScanModel.create({
    required String name,
    required String filePath,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    return ScanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      filePath: filePath,
      createdAt: DateTime.now(),
      thumbnailPath: thumbnailPath,
      metadata: metadata,
    );
  }

  // From JSON
  factory ScanModel.fromJson(Map<String, dynamic> json) =>
      _$ScanModelFromJson(json);

  // To JSON
  Map<String, dynamic> toJson() => _$ScanModelToJson(this);

  // Copy with
  ScanModel copyWith({
    String? name,
    String? filePath,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    return ScanModel(
      id: id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
    );
  }
}
