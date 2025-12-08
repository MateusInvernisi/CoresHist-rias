import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String authorName;
  final String imageUrl;
  final String text;
  final double latitude;
  final double longitude;
  final List<String> palette;
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.imageUrl,
    required this.text,
    required this.latitude,
    required this.longitude,
    required this.palette,
    required this.createdAt,
  });

  StoryModel copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? imageUrl,
    String? text,
    double? latitude,
    double? longitude,
    List<String>? palette,
    DateTime? createdAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      palette: palette ?? this.palette,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'text': text,
      'latitude': latitude,
      'longitude': longitude,
      'palette': palette,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final paletteList = (data['palette'] as List?) ?? [];

    return StoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      authorName: data['authorName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      text: data['text'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      palette: paletteList.map((e) => e.toString()).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
