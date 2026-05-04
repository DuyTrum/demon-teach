import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/repositories/achievement_repository.dart';

/// Use case for getting all achievements
class GetAchievements {
  final AchievementRepository _repository;

  GetAchievements(this._repository);

  Future<Result<List<Achievement>>> call({
    required String userId,
    required String targetLanguage,
  }) async {
    return await _repository.getAchievements(userId, targetLanguage);
  }
}
