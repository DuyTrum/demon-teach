import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/presentation/providers/lesson_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/lesson/lesson_completion_screen.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';
import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/domain/services/speaking_controller.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';
import 'package:demon_teach/core/di/injection_container.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/presentation/widgets/flashcard_widget.dart';
import 'dart:ui';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/presentation/providers/progress_provider.dart';

class DailyLessonScreen extends ConsumerStatefulWidget {
  const DailyLessonScreen({super.key});

  @override
  ConsumerState<DailyLessonScreen> createState() => _DailyLessonScreenState();
}

class _DailyLessonScreenState extends ConsumerState<DailyLessonScreen> {
  int _currentSectionIndex = 0;
  int _elapsedSeconds = 0;
  late AudioPlayer _audioPlayer;

  // Local state for speaking practice in daily lesson
  int? _recordingItemIndex;
  int? _analyzingItemIndex;
  final Map<int, PronunciationFeedback> _speakingFeedbacks = {};
  final Map<int, String> _speakingUserPaths = {};
  final Map<int, String> _practiceSelectedAnswers = {};
  int? _playingItemIndex;
  bool _isPlayingFeedbackAudio = false;
  late final SpeakingController _speakingController;
  late final AudioPlayer _userAudioPlayer;
  late final AudioPlayer _feedbackAudioPlayer;

  // State for learning diversity features
  int _currentFlashcardIndex = 0;
  bool _isFlashcardFlipped = false;
  final Map<int, bool> _readingShowTranslation = {};
  final Map<String, String> _readingSelectedAnswers = {};
  final Map<int, TextEditingController> _practiceTextControllers = {};

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _speakingController = SpeakingController(ref.read(dioProvider));
    _userAudioPlayer = AudioPlayer();
    _feedbackAudioPlayer = AudioPlayer();
    _startTimer();
    // Delay lesson loading to avoid modifying provider during build
    Future.microtask(() => _loadLesson());
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _userAudioPlayer.dispose();
    _feedbackAudioPlayer.dispose();
    _speakingController.dispose();
    for (final controller in _practiceTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      try {
        await _audioPlayer.setSpeed(1.08); // Slightly faster for an upbeat tempo
      } catch (_) {}
      try {
        await _audioPlayer.setPitch(1.22); // Cute, friendly, high-pitched assistant voice!
      } catch (_) {}
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _startRecording(int itemIndex) async {
    try {
      // Stop model audio if playing
      await _audioPlayer.stop();
      if (_playingItemIndex != null) {
        await _userAudioPlayer.stop();
        setState(() {
          _playingItemIndex = null;
        });
      }

      final hasPermission = await _speakingController.hasPermission();
      if (!hasPermission) {
        final requestResult = await _speakingController.requestPermission();
        if (!requestResult.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(requestResult.failure.message)),
            );
          }
          return;
        }
      }

      final result = await _speakingController.startRecording();
      if (result.isSuccess) {
        setState(() {
          _recordingItemIndex = itemIndex;
          _speakingFeedbacks.remove(itemIndex);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.failure.message)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording(int itemIndex, String expectedPhrase, String langCode) async {
    if (_recordingItemIndex != itemIndex) return;

    setState(() {
      _recordingItemIndex = null;
      _analyzingItemIndex = itemIndex;
    });

    try {
      final stopResult = await _speakingController.stopRecording();
      if (stopResult.isSuccess) {
        final path = stopResult.value;
        _speakingUserPaths[itemIndex] = path;

        // Call AI pronunciation evaluator
        final analyzeResult = await _speakingController.analyzePronunciation(
          path,
          expectedPhrase,
          language: langCode,
        );

        if (mounted) {
          setState(() {
            _analyzingItemIndex = null;
            if (analyzeResult.isSuccess) {
              _speakingFeedbacks[itemIndex] = analyzeResult.value;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(analyzeResult.failure.message)),
              );
            }
          });

          // Auto-play the TTS feedback audio if available
          if (analyzeResult.isSuccess && analyzeResult.value.feedbackAudioBase64 != null) {
            _playFeedbackAudio(analyzeResult.value.feedbackAudioBase64!);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _analyzingItemIndex = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(stopResult.failure.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzingItemIndex = null;
        });
      }
      debugPrint('Error stopping recording: $e');
    }
  }

  /// Play TTS feedback audio from base64 MP3 data
  Future<void> _playFeedbackAudio(String base64Audio) async {
    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();
      await _userAudioPlayer.stop();
      await _feedbackAudioPlayer.stop();

      setState(() {
        _isPlayingFeedbackAudio = true;
      });

      // Create a data URI from the base64 audio
      final dataUri = 'data:audio/mp3;base64,$base64Audio';
      await _feedbackAudioPlayer.setUrl(dataUri);
      await _feedbackAudioPlayer.play();

      // Wait for completion
      await _feedbackAudioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('Error playing feedback audio: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPlayingFeedbackAudio = false;
        });
      }
    }
  }

  Future<void> _playUserRecording(int itemIndex) async {
    final path = _speakingUserPaths[itemIndex];
    if (path == null) return;
    try {
      await _audioPlayer.stop();
      if (_playingItemIndex != null) {
        await _userAudioPlayer.stop();
      }
      if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
        await _userAudioPlayer.setUrl(path);
      } else {
        await _userAudioPlayer.setFilePath(path);
      }
      setState(() {
        _playingItemIndex = itemIndex;
      });
      await _userAudioPlayer.play();
      setState(() {
        _playingItemIndex = null;
      });
    } catch (e) {
      debugPrint('Error playing user recording: $e');
      setState(() {
        _playingItemIndex = null;
      });
    }
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
    final user = ref.read(authProvider).user;
    final languageState = ref.read(languageProvider);
    if (user != null && languageState.preference != null) {
      ref.read(lessonProvider.notifier).loadNextLesson(
            userId: user.id,
            targetLanguage: languageState.preference!.targetLanguage,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonState = ref.watch(lessonProvider);
    final progressState = ref.watch(progressProvider);
    final progress = progressState.progress;

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Bài Học Hôm Nay',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (progress != null) _buildHeartsIndicator(context, progress),
          const SizedBox(width: 8),
          // Timer display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.demonGlowPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: AppTheme.demonGlowPurple),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.demonGlowPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.demonBgGradientTop,
                  AppTheme.demonBgGradientMid,
                  AppTheme.demonBgGradientBot,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const Positioned.fill(child: DemonBackgroundParticles()),
          SafeArea(
            child: lessonState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.demonGlowPurple))
                : lessonState.error != null
                    ? Center(
                        child: ErrorMessage(
                          message: lessonState.error!,
                          onRetry: _loadLesson,
                        ),
                      )
                    : lessonState.currentLesson == null
                        ? const Center(
                            child: Text(
                              'Không có bài học khả dụng',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          )
                        : _buildLessonContent(context, lessonState.currentLesson!),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context, Lesson lesson) {
    if (!lesson.hasContent) {
      return const Center(
        child: Text('Nội dung bài học không khả dụng', style: TextStyle(color: Colors.white)),
      );
    }

    final sections = lesson.content!.content['sections'] as List? ?? [];

    if (sections.isEmpty) {
      return const Center(
        child: Text('Không có chương học nào khả dụng', style: TextStyle(color: Colors.white)),
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
            physics: const BouncingScrollPhysics(),
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
                'Chương ${_currentSectionIndex + 1} / $totalSections',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.demonGlowPurple,
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
              backgroundColor: AppTheme.demonNodeLocked,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.demonGlowPurple,
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
        color: AppTheme.demonNodeLocked.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppTheme.demonGlowPurple.withOpacity(0.2),
              border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.4)),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lesson.metadata.category.displayName} • ${lesson.metadata.difficulty.displayName}',
                  style: TextStyle(
                    color: AppTheme.demonTextMuted,
                    fontSize: 12,
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
      case 'reading':
        return _buildReadingSection(section);
      case 'practice':
        return _buildPracticeSection(section);
      case 'explanation':
        return _buildExplanationSection(section);
      case 'examples':
        return _buildExamplesSection(section);
      case 'speaking':
        return _buildSpeakingSection(section);
      default:
        return Text('Unknown section type: $type');
    }
  }

  Widget _buildSpeakingSection(Map<String, dynamic> section) {
    final items = section['items'] as List? ?? [];
    final languageState = ref.read(languageProvider);
    final targetLang = languageState.preference?.targetLanguage ?? 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Luyện nói phát âm',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          return _buildSpeakingCard(index, item, targetLang);
        }),
      ],
    );
  }

  Widget _buildSpeakingCard(int index, Map<String, dynamic> item, String targetLang) {
    final phrase = item['phrase'] as String;
    final pronunciation = item['pronunciation'] as String?;
    final translation = item['translation'] as String;
    
    // Construct audioUrl
    var audioUrl = item['audioUrl'] as String?;
    if (audioUrl != null && audioUrl.startsWith('/')) {
      audioUrl = '${AppConstants.apiBaseUrl}$audioUrl';
    } else if (audioUrl == null) {
      audioUrl = '${AppConstants.apiBaseUrl}/api/tts?text=${Uri.encodeComponent(phrase)}&language=$targetLang';
    }

    final isRecordingThis = _recordingItemIndex == index;
    final isAnalyzingThis = _analyzingItemIndex == index;
    final feedback = _speakingFeedbacks[index];
    final userPath = _speakingUserPaths[index];
    final isPlayingUserThis = _playingItemIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.demonGlowPurple.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Phrase and TTS Play Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phrase,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.demonGlowPurple,
                        fontSize: 22,
                      ),
                    ),
                    if (pronunciation != null && pronunciation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '/$pronunciation/',
                        style: const TextStyle(
                          color: AppTheme.demonTextMuted,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 28, color: Colors.white70),
                onPressed: () => _playAudio(audioUrl),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Translation
          Text(
            translation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          
          // Audio recording and feedback section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                if (isAnalyzingThis) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.demonGlowPurple),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'AI đang chấm điểm...',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                ] else if (isRecordingThis) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mic, color: Colors.redAccent, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Đang ghi âm... Nhấn nút dưới để dừng',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Default State: record / playback user audio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _startRecording(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.demonGlowPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingSm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.mic),
                        label: const Text('Bắt đầu nói'),
                      ),
                      if (userPath != null) ...[
                        const SizedBox(width: AppTheme.spacingMd),
                        ElevatedButton.icon(
                          onPressed: () => _playUserRecording(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.demonGlowPurple),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingSm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(isPlayingUserThis ? Icons.stop : Icons.play_arrow),
                          label: Text(isPlayingUserThis ? 'Dừng phát' : 'Nghe lại'),
                        ),
                      ],
                    ],
                  ),
                ],
                
                // Stop Recording button when active
                if (isRecordingThis) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  ElevatedButton.icon(
                    onPressed: () => _stopRecording(index, phrase, targetLang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text('Dừng & Gửi đánh giá'),
                  ),
                ],
                
                // Display Feedback result if available
                if (feedback != null) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: AppTheme.spacingSm),
                  _buildFeedbackResult(feedback),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackResult(PronunciationFeedback feedback) {
    final score = feedback.accuracyScore;
    final pct = (score * 100).toInt();

    // Determine colors
    Color scoreColor;
    IconData scoreIcon;
    if (score >= 0.8) {
      scoreColor = AppTheme.successColor;
      scoreIcon = Icons.check_circle;
    } else if (score >= 0.5) {
      scoreColor = Colors.orange;
      scoreIcon = Icons.info;
    } else {
      scoreColor = AppTheme.errorColor;
      scoreIcon = Icons.warning;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score Header
        Row(
          children: [
            Icon(scoreIcon, color: scoreColor, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Điểm phát âm: $pct%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
            // Replay feedback audio button
            if (feedback.feedbackAudioBase64 != null)
              IconButton(
                onPressed: _isPlayingFeedbackAudio
                    ? null
                    : () => _playFeedbackAudio(feedback.feedbackAudioBase64!),
                icon: Icon(
                  _isPlayingFeedbackAudio ? Icons.volume_up : Icons.volume_up_outlined,
                  color: _isPlayingFeedbackAudio ? scoreColor : AppTheme.demonTextMuted,
                ),
                tooltip: 'Nghe nhận xét từ Ác Quỷ',
                style: IconButton.styleFrom(
                  backgroundColor: scoreColor.withOpacity(0.1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Feedback message
        Text(
          feedback.feedback,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.demonTextLight,
          ),
        ),
        if (feedback.suggestions.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingSm),
          const Text(
            'Gợi ý cải thiện:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.demonTextMuted,
            ),
          ),
          const SizedBox(height: 4),
          ...feedback.suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.demonTextLight,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  List<Flashcard> _getFlashcardsForSection(Map<String, dynamic> section, Lesson lesson) {
    final List<Flashcard> flashcards = [];
    
    // Attempt 1: Try reading from lesson.content.content['flashcards']
    if (lesson.content != null && lesson.content!.content['flashcards'] != null) {
      final list = lesson.content!.content['flashcards'] as List;
      for (final item in list) {
        try {
          flashcards.add(Flashcard.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Error parsing flashcard from lesson: $e');
        }
      }
    }
    
    // Attempt 2: Fallback to section items if empty
    if (flashcards.isEmpty) {
      final items = section['items'] as List? ?? [];
      for (int i = 0; i < items.length; i++) {
        final item = items[i] as Map<String, dynamic>;
        flashcards.add(Flashcard(
          id: '${lesson.metadata.id}_fc_$i',
          lessonId: lesson.metadata.id,
          frontText: item['word'] as String? ?? '',
          backText: item['translation'] as String? ?? '',
          exampleUsage: (item['example'] ?? item['exampleUsage'] ?? '') as String,
          exampleTranslation: (item['example_translation'] ?? item['exampleTranslation']) as String?,
          phonetic: (item['pronunciation'] ?? item['phonetic']) as String?,
          audioUrl: item['audioUrl'] as String?,
        ));
      }
    }
    
    return flashcards;
  }

  Widget _buildVocabularySection(Map<String, dynamic> section) {
    final lesson = ref.read(lessonProvider).currentLesson;
    if (lesson == null) return const SizedBox.shrink();
    
    final flashcards = _getFlashcardsForSection(section, lesson);
    if (flashcards.isEmpty) {
      return const Center(
        child: Text('Không có từ vựng nào khả dụng', style: TextStyle(color: Colors.white)),
      );
    }
    
    if (_currentFlashcardIndex >= flashcards.length) {
      _currentFlashcardIndex = 0;
    }
    
    final currentCard = flashcards[_currentFlashcardIndex];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Từ vựng mới (Flashcards)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chạm vào thẻ để lật xem nghĩa và ví dụ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.demonTextMuted,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        GestureDetector(
          onTap: () {
            setState(() {
              _isFlashcardFlipped = !_isFlashcardFlipped;
            });
          },
          child: FlashcardWidget(
            key: ValueKey('fc_${currentCard.id}_$_isFlashcardFlipped'),
            flashcard: currentCard,
            isFlipped: _isFlashcardFlipped,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: _currentFlashcardIndex > 0
                  ? () {
                      setState(() {
                        _currentFlashcardIndex--;
                        _isFlashcardFlipped = false;
                      });
                    }
                  : null,
              disabledColor: Colors.white24,
            ),
            Text(
              '${_currentFlashcardIndex + 1} / ${flashcards.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _currentFlashcardIndex < flashcards.length - 1
                  ? () {
                      setState(() {
                        _currentFlashcardIndex++;
                        _isFlashcardFlipped = false;
                      });
                    }
                  : null,
              disabledColor: Colors.white24,
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingMd),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(flashcards.length, (idx) {
            final isActive = idx == _currentFlashcardIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 12 : 8,
              height: isActive ? 12 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.demonGlowPurple : Colors.white24,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.demonGlowPurple.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPracticeSection(Map<String, dynamic> section) {
    final exercises = section['exercises'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Luyện tập',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
    final type = exercise['type'] as String? ?? 'multiple-choice';
    final selectedAnswer = _practiceSelectedAnswers[number];
    final isAnswered = selectedAnswer != null;
    final correctAnswer = exercise['correctAnswer'] as String? ?? '';
    final explanation = exercise['explanation'] as String?;

    final isFillInBlank = type == 'fillInBlank' || type == 'fill-in-the-blank';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.demonGlowPurple.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu hỏi $number',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.demonGlowPurple,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.demonGlowPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
                ),
                child: Text(
                  isFillInBlank ? 'Điền vào chỗ trống' : 'Chọn đáp án đúng',
                  style: const TextStyle(
                    color: AppTheme.demonGlowPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            exercise['question'] as String? ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (isFillInBlank)
            _buildFillInBlankPracticeInput(number, correctAnswer, isAnswered, explanation)
          else
            ..._buildMultipleChoiceOptions(number, exercise['options'] as List? ?? [], correctAnswer, selectedAnswer, isAnswered, explanation),
            
          if (isAnswered && explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giải thích: $explanation',
                    style: const TextStyle(
                      color: AppTheme.demonTextMuted,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFillInBlankPracticeInput(int number, String correctAnswer, bool isAnswered, String? explanation) {
    final controller = _practiceTextControllers.putIfAbsent(
      number,
      () => TextEditingController(text: _practiceSelectedAnswers[number] ?? ''),
    );

    final userAns = _practiceSelectedAnswers[number];
    final isCorrect = userAns != null && _checkFillInBlankCorrect(userAns, correctAnswer);

    Color? borderColor;
    Color? backgroundColor;
    if (isAnswered) {
      borderColor = isCorrect ? Colors.green : Colors.redAccent;
      backgroundColor = isCorrect ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1);
    } else {
      borderColor = Colors.white.withOpacity(0.15);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isAnswered,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: AppTheme.demonGlowPurple,
                  decoration: InputDecoration(
                    hintText: 'Nhập câu trả lời của bạn...',
                    hintStyle: const TextStyle(color: AppTheme.demonTextMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            if (!isAnswered) ...[
              const SizedBox(width: AppTheme.spacingSm),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  
                  setState(() {
                    _practiceSelectedAnswers[number] = text;
                  });
                  
                  final correct = _checkFillInBlankCorrect(text, correctAnswer);

                  if (!correct) {
                    final user = ref.read(authProvider).user;
                    final targetLang = ref.read(languageProvider).preference?.targetLanguage;
                    if (user != null && targetLang != null) {
                      ref.read(progressProvider.notifier).consumeHeart(
                            userId: user.id,
                            targetLanguage: targetLang,
                          ).then((_) {
                        final currentProgress = ref.read(progressProvider).progress;
                        if (currentProgress != null && currentProgress.hearts <= 0) {
                          _handleZeroHearts();
                        }
                      });
                    }
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        correct 
                            ? 'Chính xác! Ngươi thông minh đấy! 😈' 
                            : 'Sai rồi! Học lại đi đệ tử! 😤',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: correct ? AppTheme.demonGlowGreen : Colors.redAccent,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.demonGlowPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Gửi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        if (isAnswered) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.check_circle_rounded,
                color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect 
                      ? 'Chính xác! Đáp án là: $correctAnswer' 
                      : 'Sai rồi! Đáp án đúng: $correctAnswer (Bạn nhập: $userAns)',
                  style: TextStyle(
                    color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _checkFillInBlankCorrect(String userAns, String correctAns) {
    String clean(String s) {
      return s.trim().toLowerCase()
          .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()?]/g'), '')
          .replaceAll(RegExp(r'\s+'), ' ');
    }
    return clean(userAns) == clean(correctAns);
  }

  List<Widget> _buildMultipleChoiceOptions(
    int number,
    List options,
    String correctAnswer,
    String? selectedAnswer,
    bool isAnswered,
    String? explanation,
  ) {
    return options.map((option) {
      final isThisSelected = selectedAnswer == option;
      final isThisCorrect = option == correctAnswer;
      
      Color? backgroundColor;
      Color? borderColor;
      Color textColor = Colors.white;
      BoxShadow? glowShadow;

      if (isAnswered) {
        if (isThisCorrect) {
          backgroundColor = Colors.green.withOpacity(0.15);
          borderColor = Colors.green;
          textColor = Colors.greenAccent;
          glowShadow = BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10);
        } else if (isThisSelected) {
          backgroundColor = Colors.redAccent.withOpacity(0.15);
          borderColor = Colors.redAccent;
          textColor = Colors.redAccent;
          glowShadow = BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10);
        }
      } else {
        borderColor = Colors.white.withOpacity(0.15);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? Colors.transparent,
              width: 1.5,
            ),
            boxShadow: glowShadow != null ? [glowShadow] : null,
          ),
          child: InkWell(
            onTap: isAnswered
                ? null
                : () {
                    setState(() {
                      _practiceSelectedAnswers[number] = option as String;
                    });
                    final isCorrect = (option == correctAnswer);

                    if (!isCorrect) {
                      final user = ref.read(authProvider).user;
                      final targetLang = ref.read(languageProvider).preference?.targetLanguage;
                      if (user != null && targetLang != null) {
                        ref.read(progressProvider.notifier).consumeHeart(
                              userId: user.id,
                              targetLanguage: targetLang,
                            ).then((_) {
                          final currentProgress = ref.read(progressProvider).progress;
                          if (currentProgress != null && currentProgress.hearts <= 0) {
                            _handleZeroHearts();
                          }
                        });
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isCorrect 
                              ? 'Chính xác! Ngươi thông minh đấy! 😈' 
                              : 'Sai rồi! Học lại đi đệ tử! 😤',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: isCorrect ? AppTheme.demonGlowGreen : Colors.redAccent,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option as String,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: isThisSelected || (isAnswered && isThisCorrect) ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isAnswered && isThisCorrect)
                    const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                  if (isAnswered && isThisSelected && !isThisCorrect)
                    const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildReadingSection(Map<String, dynamic> section) {
    final passageText = section['passageText'] as String? ?? '';
    final translation = section['translation'] as String? ?? '';
    final questions = section['questions'] as List? ?? [];
    final sectionIdx = _currentSectionIndex;
    final showTranslation = _readingShowTranslation[sectionIdx] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đọc hiểu đoạn văn',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.demonCardDark.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.demonGlowPurple.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: AppTheme.demonGlowPurple),
                  const SizedBox(width: 8),
                  const Text(
                    'Đoạn văn / Dialogue',
                    style: TextStyle(
                      color: AppTheme.demonGlowPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              SelectableText(
                passageText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              if (translation.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMd),
                const Divider(color: Colors.white24),
                const SizedBox(height: AppTheme.spacingSm),
                
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _readingShowTranslation[sectionIdx] = !showTranslation;
                    });
                  },
                  icon: Icon(
                    showTranslation ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.demonGlowPurple,
                  ),
                  label: Text(
                    showTranslation ? 'Ẩn bản dịch' : 'Hiện bản dịch tiếng Việt',
                    style: const TextStyle(
                      color: AppTheme.demonGlowPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                if (showTranslation) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      translation,
                      style: const TextStyle(
                        color: AppTheme.demonTextLight,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        const Text(
          'Câu hỏi đọc hiểu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        ...questions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value as Map<String, dynamic>;
          final qId = q['id'] as String? ?? 'rq_$idx';
          return _buildReadingQuestionCard(idx + 1, q, qId);
        }),
      ],
    );
  }

  Widget _buildReadingQuestionCard(int number, Map<String, dynamic> q, String qId) {
    final selectedAnswer = _readingSelectedAnswers[qId];
    final isAnswered = selectedAnswer != null;
    final correctAnswer = q['correctAnswer'] as String;
    final explanation = q['explanation'] as String?;
    final questionText = q['question'] as String? ?? q['questionText'] as String? ?? '';
    final options = q['options'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu hỏi $number',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.demonGlowPurple,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          
          ...options.map((option) {
            final isThisSelected = selectedAnswer == option;
            final isThisCorrect = option == correctAnswer;
            
            Color? backgroundColor;
            Color? borderColor;
            Color textColor = Colors.white;
            BoxShadow? glowShadow;

            if (isAnswered) {
              if (isThisCorrect) {
                backgroundColor = Colors.green.withOpacity(0.15);
                borderColor = Colors.green;
                textColor = Colors.greenAccent;
                glowShadow = BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10);
              } else if (isThisSelected) {
                backgroundColor = Colors.redAccent.withOpacity(0.15);
                borderColor = Colors.redAccent;
                textColor = Colors.redAccent;
                glowShadow = BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10);
              }
            } else {
              borderColor = Colors.white.withOpacity(0.15);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor ?? Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: glowShadow != null ? [glowShadow] : null,
                ),
                child: InkWell(
                  onTap: isAnswered
                      ? null
                      : () {
                          setState(() {
                            _readingSelectedAnswers[qId] = option as String;
                          });
                          final isCorrect = (option == correctAnswer);

                          if (!isCorrect) {
                            final user = ref.read(authProvider).user;
                            final targetLang = ref.read(languageProvider).preference?.targetLanguage;
                            if (user != null && targetLang != null) {
                              ref.read(progressProvider.notifier).consumeHeart(
                                    userId: user.id,
                                    targetLanguage: targetLang,
                                  ).then((_) {
                                final currentProgress = ref.read(progressProvider).progress;
                                if (currentProgress != null && currentProgress.hearts <= 0) {
                                  _handleZeroHearts();
                                }
                              });
                            }
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isCorrect 
                                    ? 'Chính xác! Ngươi thông minh đấy! 😈' 
                                    : 'Sai rồi! Học lại đi đệ tử! 😤',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: isCorrect ? AppTheme.demonGlowGreen : Colors.redAccent,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option as String,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: isThisSelected || (isAnswered && isThisCorrect) ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isAnswered && isThisCorrect)
                          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                        if (isAnswered && isThisSelected && !isThisCorrect)
                          const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          
          if (isAnswered && explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giải thích: $explanation',
                    style: const TextStyle(
                      color: AppTheme.demonTextMuted,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationSection(Map<String, dynamic> section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giải thích ngữ pháp',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.demonCardDark.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.demonGlowPurple.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Text(
            section['content'] as String? ?? 'Nội dung đang được cập nhật.',
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
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
        const Text(
          'Ví dụ minh họa',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final example = entry.value as String? ?? '';
          if (example.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.demonCardDark.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.demonGlowPurple.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppTheme.demonGlowPurple,
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
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
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
        color: AppTheme.demonBgGradientBot.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: AppTheme.demonGlowPurple.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.demonGlowPurple.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirstSection)
            Expanded(
              child: CustomButton(
                text: 'Quay lại',
                onPressed: () {
                  setState(() {
                    _currentSectionIndex--;
                    _currentFlashcardIndex = 0;
                    _isFlashcardFlipped = false;
                  });
                },
                isOutlined: true,
              ),
            ),
          if (!isFirstSection) const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: CustomButton(
              text: isLastSection ? 'Hoàn thành bài học' : 'Tiếp tục',
              onPressed: () {
                final sections = lesson.content!.content['sections'] as List? ?? [];
                final currentSection = sections[_currentSectionIndex] as Map<String, dynamic>;
                final isSpeakingSection = currentSection['type'] == 'speaking';
                
                if (isSpeakingSection) {
                  final items = currentSection['items'] as List? ?? [];
                  bool allDone = true;
                  for (int i = 0; i < items.length; i++) {
                    if (_speakingFeedbacks[i] == null) {
                      allDone = false;
                      break;
                    }
                  }
                  
                  if (!allDone) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '😈 Demon Teach: Ngươi dám trốn học nói sao?! Phải hoàn thành phát âm đầy đủ tất cả các câu thì ta mới cho qua! Đừng hòng lười biếng!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppTheme.errorColor,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                }

                if (isLastSection) {
                  _completeLesson(lesson);
                } else {
                  setState(() {
                    _currentSectionIndex++;
                    _currentFlashcardIndex = 0;
                    _isFlashcardFlipped = false;
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

  Widget _buildHeartsIndicator(BuildContext context, Progress progress) {
    final hasCooldown = progress.hearts < AppConstants.maxHearts;
    final countdownStr = _formatRemainingTime(progress);

    return GestureDetector(
      onTap: () => _showHeartsRefillDialog(context, progress),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF1744).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF1744).withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1744).withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite,
              color: Color(0xFFFF1744),
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              '${progress.hearts}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (hasCooldown && countdownStr.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                countdownStr,
                style: const TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRemainingTime(Progress progress) {
    if (progress.hearts >= AppConstants.maxHearts) return '';
    final nextHeartTime = progress.lastHeartRegenTime.add(AppConstants.heartRegenInterval);
    final remaining = nextHeartTime.difference(DateTime.now());
    if (remaining.isNegative) return '00:00';
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showHeartsRefillDialog(BuildContext context, Progress progress) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final progressState = ref.watch(progressProvider);
            final currentProgress = progressState.progress ?? progress;
            final isFull = currentProgress.hearts >= AppConstants.maxHearts;
            final hasEnoughSouls = currentProgress.souls >= 50;
            final isUpdating = progressState.isUpdating;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A2E).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFF1744).withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1744).withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🔮 HỒI PHỤC TIM MA PHÁP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(AppConstants.maxHearts, (index) {
                            final isFilled = index < currentProgress.hearts;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.favorite,
                                color: isFilled ? const Color(0xFFFF1744) : Colors.white24,
                                size: 28,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        if (isFull) ...[
                          const Text(
                            'Tim Ma Pháp của ngươi đã đầy tràn ma lực!',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            'Tim sẽ tự động hồi phục sau mỗi ${_formatInterval(AppConstants.heartRegenInterval)}.\nHoặc ngươi có thể dùng Linh Hồn để đổi lấy Tim ngay lập tức!',
                            style: const TextStyle(color: Color(0xFF8A7DA0), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tài sản: 👻 ${currentProgress.souls} Linh Hồn',
                                style: TextStyle(
                                  color: hasEnoughSouls ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Đóng',
                                isOutlined: true,
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                            ),
                            if (!isFull) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  text: 'Hồi phục 1 Tim (-50 Linh Hồn)',
                                  isLoading: isUpdating,
                                  onPressed: (!hasEnoughSouls || isUpdating)
                                      ? null
                                      : () async {
                                          final success = await ref
                                              .read(progressProvider.notifier)
                                              .refillHeartWithSouls(
                                                userId: currentProgress.userId,
                                                targetLanguage: currentProgress.targetLanguage,
                                              );
                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Hồi phục Tim thành công! 💖 Ma lực đã gia tăng.',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                backgroundColor: Color(0xFF43A047),
                                              ),
                                            );
                                          } else if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Hồi phục thất bại!'),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatInterval(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} phút';
    }
    return '${duration.inSeconds} giây';
  }

  void _handleZeroHearts() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final progressState = ref.watch(progressProvider);
            final currentProgress = progressState.progress;
            final hasEnoughSouls = currentProgress != null && currentProgress.souls >= 50;
            final isUpdating = progressState.isUpdating;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A2E).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '💀 HẾT TIM MA PHÁP!',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '😈 Ngươi đã kiệt sức và không còn Tim Ma Pháp để tiếp tục nghi thức học tập này! Khế ước yêu cầu ít nhất 1 Tim.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (currentProgress != null)
                          Text(
                            'Tài sản: 👻 ${currentProgress.souls} Linh Hồn',
                            style: TextStyle(
                              color: hasEnoughSouls ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Thoát bài học',
                                isOutlined: true,
                                onPressed: () {
                                  Navigator.pop(dialogContext); // Close dialog
                                  Navigator.pop(context); // Exit lesson screen
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'Đổi 50 Linh Hồn lấy 1 Tim',
                                isLoading: isUpdating,
                                onPressed: (!hasEnoughSouls || isUpdating)
                                    ? null
                                    : () async {
                                        final success = await ref
                                            .read(progressProvider.notifier)
                                            .refillHeartWithSouls(
                                              userId: currentProgress!.userId,
                                              targetLanguage: currentProgress.targetLanguage,
                                            );
                                        if (success && context.mounted) {
                                          Navigator.pop(dialogContext); // Close zero hearts dialog and continue
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Hồi phục Tim thành công! 💖 Ngươi có thể tiếp tục.',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              backgroundColor: Color(0xFF43A047),
                                            ),
                                          );
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Hồi phục thất bại!'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
