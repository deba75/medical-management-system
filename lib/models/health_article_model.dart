import 'package:cloud_firestore/cloud_firestore.dart';

enum ArticleCategory { 
  generalHealth, 
  nutrition, 
  mentalHealth, 
  fitness, 
  diseases, 
  medications, 
  wellness, 
  pregnancy, 
  childcare, 
  eldercare,
  other
}

class HealthArticleModel {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorImage;
  final String? authorSpecialization;
  final ArticleCategory category;
  final List<String> tags;
  final String? imageUrl;
  final int readTimeMinutes;
  final int views;
  final int likes;
  final List<String> likedBy;
  final bool isPublished;
  final bool isFeatured;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorImage,
    this.authorSpecialization,
    required this.category,
    required this.tags,
    this.imageUrl,
    required this.readTimeMinutes,
    required this.views,
    required this.likes,
    required this.likedBy,
    required this.isPublished,
    required this.isFeatured,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthArticleModel.fromJson(Map<String, dynamic> json, String id) {
    return HealthArticleModel(
      id: id,
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorImage: json['authorImage'],
      authorSpecialization: json['authorSpecialization'],
      category: ArticleCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ArticleCategory.generalHealth,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
      readTimeMinutes: json['readTimeMinutes'] ?? 5,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      isPublished: json['isPublished'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      publishedAt: json['publishedAt'] is Timestamp
          ? (json['publishedAt'] as Timestamp).toDate()
          : DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorImage': authorImage,
      'authorSpecialization': authorSpecialization,
      'category': category.name,
      'tags': tags,
      'imageUrl': imageUrl,
      'readTimeMinutes': readTimeMinutes,
      'views': views,
      'likes': likes,
      'likedBy': likedBy,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get categoryDisplay {
    switch (category) {
      case ArticleCategory.generalHealth:
        return 'General Health';
      case ArticleCategory.nutrition:
        return 'Nutrition';
      case ArticleCategory.mentalHealth:
        return 'Mental Health';
      case ArticleCategory.fitness:
        return 'Fitness';
      case ArticleCategory.diseases:
        return 'Diseases';
      case ArticleCategory.medications:
        return 'Medications';
      case ArticleCategory.wellness:
        return 'Wellness';
      case ArticleCategory.pregnancy:
        return 'Pregnancy';
      case ArticleCategory.childcare:
        return 'Child Care';
      case ArticleCategory.eldercare:
        return 'Elder Care';
      case ArticleCategory.other:
        return 'Other';
    }
  }

  String get categoryIcon {
    switch (category) {
      case ArticleCategory.generalHealth:
        return '🏥';
      case ArticleCategory.nutrition:
        return '🥗';
      case ArticleCategory.mentalHealth:
        return '🧠';
      case ArticleCategory.fitness:
        return '💪';
      case ArticleCategory.diseases:
        return '🦠';
      case ArticleCategory.medications:
        return '💊';
      case ArticleCategory.wellness:
        return '🧘';
      case ArticleCategory.pregnancy:
        return '🤰';
      case ArticleCategory.childcare:
        return '👶';
      case ArticleCategory.eldercare:
        return '👴';
      case ArticleCategory.other:
        return '📰';
    }
  }

  HealthArticleModel copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? authorId,
    String? authorName,
    String? authorImage,
    String? authorSpecialization,
    ArticleCategory? category,
    List<String>? tags,
    String? imageUrl,
    int? readTimeMinutes,
    int? views,
    int? likes,
    List<String>? likedBy,
    bool? isPublished,
    bool? isFeatured,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      authorSpecialization: authorSpecialization ?? this.authorSpecialization,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
