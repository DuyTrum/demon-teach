import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/presentation/providers/lesson_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/lesson/lesson_completion_screen.dart';

class DailyLessonScreen extends ConsumerStatefulWidget {
  const DailyLessonScreen({super.key});

  @override
  ConsumerState<DailyLessonScreen> createState() => _DailyLessonScreenState();
}

class _DailyLessonScreenState extends ConsumerState<DailyLessonScreen> {
  int _currentSectionIndex = 0;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Delay lesson loading to avoid modifying provider during build
    Future.microtask(() => _loadLesson());
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
        _startTimer();
      }
    });
  }

  void _loadLesson() {
    final languageState = ref.read(languageProvider);
    final user = ref.read(authProvider).user;
    
    if (languageState.preference != null && user != null) {
      ref.read(lessonProvider.notifier).loadNextLesson(
            userId: user.id,
            targetLanguage: languageState.preference!.targetLanguage,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonState = ref.watch(lessonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Lesson'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Timer display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: lessonState.isLoading
          ? const Center(child: LoadingIndicator())
          : lessonState.error != null
              ? Center(
                  child: ErrorMessage(
                    message: lessonState.error!,
                    onRetry: _loadLesson,
                  ),
                )
              : lessonState.currentLesson == null
                  ? const Center(
                      child: Text('No lesson available'),
                    )
                  : _buildLessonContent(context, lessonState.currentLesson!),
    );
  }

  Widget _buildLessonContent(BuildContext context, Lesson lesson) {
    if (!lesson.hasContent) {
      return const Center(
        child: Text('Lesson content not available'),
      );
    }

    final sections = lesson.content!.content['sections'] as List? ?? [];

    if (sections.isEmpty) {
      return const Center(
        child: Text('No content sections available'),
      );
    }

    return Column(
      children: [
        // Progress bar
        _buildProgressBar(sections.length),

        // Lesson header
        _buildLessonHeader(lesson),

        // Content section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: _buildSection(sections[_currentSectionIndex]),
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(sections.length, lesson),
      ],
    );
  }

  Widget _buildProgressBar(int totalSections) {
    final progress = (_currentSectionIndex + 1) / totalSections;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Section ${_currentSectionIndex + 1} of $totalSections',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonHeader(Lesson lesson) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              lesson.metadata.category.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.metadata.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lesson.metadata.category.displayName} • ${lesson.metadata.difficulty.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final type = section['type'] as String;

    switch (type) {
      case 'vocabulary':
        return _buildVocabularySection(section);
      case 'practice':
        return _buildPracticeSection(section);
      case 'explanation':
        return _buildExplanationSection(section);
      case 'examples':
        return _buildExamplesSection(section);
      default:
        return Text('Unknown section type: $type');
    }
  }

  Widget _buildVocabularySection(Map<String, dynamic> section) {
    final items = section['items'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vocabulary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...items
            .map((item) => _buildVocabularyCard(item as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildVocabularyCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['word'] as String,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    // TODO: Play audio pronunciation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio playback coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (item['pronunciation'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '/${item['pronunciation']}/',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              item['translation'] as String,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeSection(Map<String, dynamic> section) {
    final exercises = section['exercises'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value as Map<String, dynamic>;
          return _buildExerciseCard(index + 1, exercise);
        }),
      ],
    );
  }

  Widget _buildExerciseCard(int number, Map<String, dynamic> exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $number',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              exercise['question'] as String,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...(exercise['options'] as List).map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Handle answer selection
                    final isCorrect = option == exercise['correctAnswer'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isCorrect ? 'Correct! ✓' : 'Try again'),
                        backgroundColor: isCorrect
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(option as String),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationSection(Map<String, dynamic> section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explanation',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Text(
              section['content'] as String,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamplesSection(Map<String, dynamic> section) {
    final items = section['items'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Examples',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final example = entry.value as String;
          return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      example,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavigationButtons(int totalSections, Lesson lesson) {
    final isFirstSection = _currentSectionIndex == 0;
    final isLastSection = _currentSectionIndex == totalSections - 1;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirstSection)
            Expanded(
              child: CustomButton(
                text: 'Previous',
                onPressed: () {
                  setState(() {
                    _currentSectionIndex--;
                  });
                },
                isOutlined: true,
              ),
            ),
          if (!isFirstSection) const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: CustomButton(
              text: isLastSection ? 'Complete Lesson' : 'Next',
              onPressed: () {
                if (isLastSection) {
                  _completeLesson(lesson);
                } else {
                  setState(() {
                    _currentSectionIndex++;
                  });
                }
              },
              icon: isLastSection ? Icons.check : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }

  void _completeLesson(Lesson lesson) async {
    final languageState = ref.read(languageProvider);
    if (languageState.preference == null) return;

    // Calculate score (simple: 100 for completing all sections)
    final score = 100;

    // Navigate to completion screen
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LessonCompletionScreen(
          lesson: lesson,
          score: score,
          timeSpent: _elapsedSeconds,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
