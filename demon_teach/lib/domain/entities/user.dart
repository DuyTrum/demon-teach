import 'package:demon_teach/domain/entities/entity.dart';

/// User domain entity
class User extends Entity {
  final String id;
  final String email;
  final String nativeLanguage;
  final List<String> targetLanguages;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const User({
    required this.id,
    required this.email,
    required this.nativeLanguage,
    required this.targetLanguages,
    required this.createdAt,
    required this.lastActiveAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? nativeLanguage,
    List<String>? targetLanguages,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        nativeLanguage,
        targetLanguages,
        createdAt,
        lastActiveAt,
      ];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      nativeLanguage: json['nativeLanguage'] ?? '',
      targetLanguages: (json['targetLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nativeLanguage': nativeLanguage,
      'targetLanguages': targetLanguages,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }
}
