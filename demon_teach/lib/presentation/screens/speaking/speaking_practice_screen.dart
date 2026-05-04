import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/speaking_provider.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';

/// Speaking practice screen
class SpeakingPracticeScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final VoidCallback? onComplete;

  const SpeakingPracticeScreen({
    super.key,
    required this.lessonId,
    this.onComplete,
  });

  @override
  ConsumerState<SpeakingPracticeScreen> createState() =>
      _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState
    extends ConsumerState<SpeakingPracticeScreen> {
  @override
  void initState() {
    super.initState();
    // Load speaking exercise
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speakingProvider.notifier).loadExercise(widget.lessonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(speakingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaking Practice'),
        actions: [
          if (state.exercise?.hasRecording == true)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'Delete Recording',
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, SpeakingState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.exercise == null) {
      return Center(
        child: ErrorMessage(
          message: state.error!,
          onRetry: () {
            ref.read(speakingProvider.notifier).loadExercise(widget.lessonId);
          },
        ),
      );
    }

    if (state.exercise == null) {
      return const Center(
        child: Text('No speaking exercise available for this lesson.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInstructions(context),
          const SizedBox(height: AppTheme.spacingXl),
          _buildPhraseCard(context, state),
          const SizedBox(height: AppTheme.spacingXl),
          _buildModelAudioSection(context, state),
          const SizedBox(height: AppTheme.spacingXl),
          _buildRecordingSection(context, state),
          if (state.exercise!.hasRecording) ...[
            const SizedBox(height: AppTheme.spacingXl),
            _buildUserRecordingSection(context, state),
          ],
          if (state.exercise!.hasFeedback) ...[
            const SizedBox(height: AppTheme.spacingXl),
            _buildFeedbackSection(context, state),
          ],
          if (state.error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _buildErrorBanner(context, state.error!),
          ],
          const SizedBox(height: AppTheme.spacingXl),
          _buildCompleteButton(context, state),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'How to Practice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInstructionItem(
                context, '1. Listen to the model pronunciation'),
            _buildInstructionItem(context, '2. Tap and hold the record button'),
            _buildInstructionItem(context, '3. Speak the phrase clearly'),
            _buildInstructionItem(context, '4. Release to stop recording'),
            _buildInstructionItem(
                context, '5. Review your pronunciation feedback'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseCard(BuildContext context, SpeakingState state) {
    return Card(
      elevation: AppTheme.elevationMd,
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          children: [
            Text(
              'Practice this phrase:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              state.exercise!.phrase,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelAudioSection(BuildContext context, SpeakingState state) {
    return Card(
      elevation: AppTheme.elevationSm,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.headphones,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Model Pronunciation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: state.isPlayingModel
                  ? () => ref.read(speakingProvider.notifier).stopModelAudio()
                  : () => ref.read(speakingProvider.notifier).playModelAudio(),
              icon: Icon(
                state.isPlayingModel ? Icons.stop : Icons.play_arrow,
              ),
              label: Text(
                state.isPlayingModel ? 'Stop' : 'Play Model Audio',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl,
                  vertical: AppTheme.spacingMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection(BuildContext context, SpeakingState state) {
    return Card(
      elevation: AppTheme.elevationSm,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.mic,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Your Recording',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (state.isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppTheme.spacingMd),
                  Text('Analyzing pronunciation...'),
                ],
              )
            else
              GestureDetector(
                onLongPressStart: (_) => _handleRecordStart(),
                onLongPressEnd: (_) => _handleRecordStop(),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isRecording
                        ? AppTheme.errorColor
                        : AppTheme.errorColor.withOpacity(0.2),
                    boxShadow: state.isRecording
                        ? [
                            BoxShadow(
                              color: AppTheme.errorColor.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 60,
                    color:
                        state.isRecording ? Colors.white : AppTheme.errorColor,
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              state.isRecording
                  ? 'Recording... (Release to stop)'
                  : 'Hold to Record',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: state.isRecording
                        ? AppTheme.errorColor
                        : AppTheme.textSecondaryColor,
                  ),
            ),
            if (!state.hasPermission) ...[
              const SizedBox(height: AppTheme.spacingMd),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(speakingProvider.notifier).requestPermission(),
                icon: const Icon(Icons.mic_off),
                label: const Text('Grant Microphone Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserRecordingSection(BuildContext context, SpeakingState state) {
    return Card(
      elevation: AppTheme.elevationSm,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Playback',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: state.isPlayingUser
                      ? () =>
                          ref.read(speakingProvider.notifier).stopUserAudio()
                      : () => ref
                          .read(speakingProvider.notifier)
                          .playUserRecording(),
                  icon: Icon(
                    state.isPlayingUser ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    state.isPlayingUser ? 'Stop' : 'Play Recording',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(speakingProvider.notifier).deleteRecording(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-record'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, SpeakingState state) {
    final feedback = state.exercise!.feedback!;
    final score = feedback.accuracyScore;

    Color scoreColor;
    IconData scoreIcon;
    if (score >= 0.9) {
      scoreColor = AppTheme.successColor;
      scoreIcon = Icons.sentiment_very_satisfied;
    } else if (score >= 0.75) {
      scoreColor = Colors.lightGreen;
      scoreIcon = Icons.sentiment_satisfied;
    } else if (score >= 0.6) {
      scoreColor = AppTheme.warningColor;
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = AppTheme.errorColor;
      scoreIcon = Icons.sentiment_dissatisfied;
    }

    return Card(
      elevation: AppTheme.elevationMd,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: scoreColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Pronunciation Feedback',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            // Score display
            Center(
              child: Column(
                children: [
                  Icon(
                    scoreIcon,
                    size: 60,
                    color: scoreColor,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    '${(score * 100).toInt()}%',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Accuracy Score',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            // Feedback message
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                feedback.feedback,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            if (feedback.suggestions.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Suggestions:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ...feedback.suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildCompleteButton(BuildContext context, SpeakingState state) {
    final hasRecording = state.exercise?.hasRecording ?? false;

    return ElevatedButton(
      onPressed: hasRecording ? widget.onComplete : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
      ),
      child: Text(
        hasRecording ? 'Complete Speaking Practice' : 'Record to Continue',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleRecordStart() {
    ref.read(speakingProvider.notifier).startRecording();
  }

  void _handleRecordStop() {
    ref.read(speakingProvider.notifier).stopRecording();
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text(
          'Are you sure you want to delete your recording? You will need to record again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(speakingProvider.notifier).deleteRecording();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
