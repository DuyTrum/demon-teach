import 'package:flutter/material.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/achievement.dart';

/// Card widget for displaying an achievement
class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation:
          achievement.isUnlocked ? AppTheme.elevationMd : AppTheme.elevationSm,
      color: achievement.isUnlocked ? null : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            _buildIcon(context),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: achievement.isUnlocked
                              ? AppTheme.textPrimaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    achievement.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  if (!achievement.isUnlocked) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildProgressBar(context),
                  ],
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: achievement.isUnlocked
                            ? AppTheme.accentColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        '+${achievement.bonusXP} XP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: achievement.isUnlocked
                                  ? AppTheme.accentColor
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (achievement.isUnlocked &&
                          achievement.unlockedAt != null) ...[
                        const Spacer(),
                        Text(
                          _formatDate(achievement.unlockedAt!),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? _getTypeColor().withOpacity(0.2)
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Center(
        child: Text(
          achievement.getIcon(),
          style: TextStyle(
            fontSize: 32,
            color: achievement.isUnlocked ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                  ),
            ),
            Text(
              '${(achievement.progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        LinearProgressIndicator(
          value: achievement.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getTypeColor()),
          minHeight: 6,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ],
    );
  }

  Color _getTypeColor() {
    switch (achievement.type) {
      case AchievementType.streak:
        return Colors.orange;
      case AchievementType.xp:
        return Colors.amber;
      case AchievementType.lessonCount:
        return Colors.blue;
      case AchievementType.special:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
