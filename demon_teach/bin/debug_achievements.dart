import 'dart:convert';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/services/achievement_engine.dart';

void main() {
  final engine = AchievementEngine();
  try {
    final achievements = engine.getAchievementDefinitions(
      userId: 'test_user',
      targetLanguage: 'en',
    );
    print('Created ${achievements.length} achievements.');
    
    final jsonStr = json.encode(achievements.map((a) => a.toJson()).toList());
    print('JSON encoded successfully.');
    
    final list = json.decode(jsonStr) as List;
    final decoded = list.map((json) => Achievement.fromJson(json as Map<String, dynamic>)).toList();
    print('Decoded ${decoded.length} achievements successfully.');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
