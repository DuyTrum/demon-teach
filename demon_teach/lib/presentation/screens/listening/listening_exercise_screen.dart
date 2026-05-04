import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/listening_provider.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/listening/listening_result_screen.dart';

/// Listening exercise screen with audio playback and comprehension questions
class ListeningExerciseScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final VoidCallback? onComplete;

  const ListeningExerciseScreen({
    super.key,
    required this.lessonId,
    this.onComplete,
  });

  @override
  ConsumerState<ListeningExerciseScreen> createState() =>
      _ListeningExerciseScreenState();
}

class _ListeningExerciseScreenState
    extends ConsumerState<ListeningExerciseScreen> {
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    // Load listening exercise
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listeningProvider.notifier).loadExercise(widget.lessonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listeningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Exercise'),
        actions: [
          if (state.exercise != null && state.canShowQuestions)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: Center(
                child: Text(
                  '${state.currentQuestionNumber}/${state.totalQuestions}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ListeningState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.exercise == null) {
      return Center(
        child: ErrorMessage(
          message: state.error!,
          onRetry: () {
            ref.read(listeningProvider.notifier).loadExercise(widget.lessonId);
          },
        ),
      );
    }

    if (state.exercise == null) {
      return const Center(
        child: Text('No listening exercise available for this lesson.'),
      );
    }

    return Column(
      children: [
        // Audio player section
        _buildAudioSection(context, state),

        // Questions section (only shown after audio is played)
        if (state.canShowQuestions)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestion(context, state),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildAnswerOptions(context, state),
                  if (state.showFeedback) ...[
                    const SizedBox(height: AppTheme.spacingXl),
                    _buildFeedback(context, state),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildErrorBanner(context, state.error!),
                  ],
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.headphones,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      'Listen to the audio first',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Play the audio clip at least once to unlock the comprehension questions.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Action buttons
        if (state.canShowQuestions) _buildActionButtons(context, state),
      ],
    );
  }

  Widget _buildAudioSection(BuildContext context, ListeningState state) {
    final exercise = state.exercise!;
    final progress = state.totalDuration.inSeconds > 0
        ? state.currentPosition.inSeconds / state.totalDuration.inSeconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Audio info
          Row(
            children: [
              const Icon(
                Icons.audiotrack,
                color: AppTheme.primaryColor,
                size: 32,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Clip',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${exercise.durationSeconds} seconds',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              if (state.canShowQuestions)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        'Played',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
            minHeight: 6,
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(state.currentPosition),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              Text(
                _formatDuration(state.totalDuration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replay button
              IconButton(
                onPressed: state.isPlaying
                    ? null
                    : () => ref.read(listeningProvider.notifier).replayAudio(),
                icon: const Icon(Icons.replay),
                iconSize: 32,
                color: AppTheme.primaryColor,
                tooltip: 'Replay',
              ),
              const SizedBox(width: AppTheme.spacingXl),

              // Play/Pause button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    if (state.isPlaying) {
                      ref.read(listeningProvider.notifier).pauseAudio();
                    } else {
                      ref.read(listeningProvider.notifier).playAudio();
                    }
                  },
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  iconSize: 48,
                  color: Colors.white,
                  tooltip: state.isPlaying ? 'Pause' : 'Play',
                ),
              ),
              const SizedBox(width: AppTheme.spacingXl),

              // Stop button
              IconButton(
                onPressed: state.isPlaying
                    ? () => ref.read(listeningProvider.notifier).stopAudio()
                    : null,
                icon: const Icon(Icons.stop),
                iconSize: 32,
                color: AppTheme.primaryColor,
                tooltip: 'Stop',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, ListeningState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'Comprehension Question',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(BuildContext context, ListeningState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final currentAnswer = state.getUserAnswer(question.id);
    final isAnswered = currentAnswer != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: question.options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == question.correctAnswer;
        final showCorrectness = state.showFeedback && isAnswered;

        Color? backgroundColor;
        Color? borderColor;
        if (showCorrectness) {
          if (isCorrect) {
            backgroundColor = AppTheme.successColor.withOpacity(0.1);
            borderColor = AppTheme.successColor;
          } else if (isSelected && !isCorrect) {
            backgroundColor = AppTheme.errorColor.withOpacity(0.1);
            borderColor = AppTheme.errorColor;
          }
        } else if (isSelected) {
          backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
          borderColor = AppTheme.primaryColor;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          child: InkWell(
            onTap: state.showFeedback
                ? null
                : () {
                    setState(() {
                      _selectedAnswer = option;
                    });
                  },
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                border: Border.all(
                  color: borderColor ?? Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (showCorrectness && isCorrect)
                    const Icon(Icons.check_circle,
                        color: AppTheme.successColor),
                  if (showCorrectness && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: AppTheme.errorColor),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedback(BuildContext context, ListeningState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final isCorrect = state.isAnsweredCorrectly(question.id) ?? false;

    return Card(
      color: isCorrect
          ? AppTheme.successColor.withOpacity(0.1)
          : AppTheme.errorColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color:
                      isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isCorrect
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              question.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.errorColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ListeningState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: state.showFeedback
            ? _buildNextButton(context, state)
            : _buildSubmitAnswerButton(context, state),
      ),
    );
  }

  Widget _buildSubmitAnswerButton(BuildContext context, ListeningState state) {
    return ElevatedButton(
      onPressed: _selectedAnswer != null
          ? () {
              ref.read(listeningProvider.notifier).answerQuestion(
                    _selectedAnswer!,
                  );
            }
          : null,
      child: const Text('Submit Answer'),
    );
  }

  Widget _buildNextButton(BuildContext context, ListeningState state) {
    if (state.isLastQuestion && state.allQuestionsAnswered) {
      return ElevatedButton(
        onPressed: state.isSubmitting ? null : _handleSubmitExercise,
        child: state.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Submit Exercise'),
      );
    }

    return ElevatedButton(
      onPressed: state.hasNext
          ? () {
              ref.read(listeningProvider.notifier).nextQuestion();
              setState(() {
                _selectedAnswer = null;
              });
            }
          : null,
      child: const Text('Next Question'),
    );
  }

  void _handleSubmitExercise() async {
    await ref.read(listeningProvider.notifier).submitExercise();

    // Navigate to results screen
    if (mounted) {
      final result = ref.read(listeningProvider).result;
      if (result != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListeningResultScreen(
              result: result,
              exercise: ref.read(listeningProvider).exercise!,
              onRetry: () {
                ref.read(listeningProvider.notifier).reset();
                Navigator.of(context).pop();
              },
              onComplete: widget.onComplete,
            ),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
