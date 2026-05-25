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

  Widget _buildVocabularySection(Map<String, dynamic> section) {
    final items = section['items'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Từ vựng mới',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...items
            .map((item) => _buildVocabularyCard(item as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildVocabularyCard(Map<String, dynamic> item) {
    final word = item['word'] as String;
    final languageState = ref.read(languageProvider);
    final targetLang = languageState.preference?.targetLanguage ?? 'en';
    
    var audioUrl = item['audioUrl'] as String?;
    if (audioUrl != null && audioUrl.startsWith('/')) {
      audioUrl = '${AppConstants.apiBaseUrl}$audioUrl';
    } else if (audioUrl == null) {
      audioUrl = '${AppConstants.apiBaseUrl}/api/tts?text=${Uri.encodeComponent(word)}&language=$targetLang';
    }

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
          Row(
            children: [
              Expanded(
                child: Text(
                  word,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.demonGlowPurple,
                    fontSize: 22,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.white70),
                onPressed: () => _playAudio(audioUrl),
              ),
            ],
          ),
          if (item['pronunciation'] != null && (item['pronunciation'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '/${item['pronunciation']}/',
              style: const TextStyle(
                color: AppTheme.demonTextMuted,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            item['translation'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
    final selectedAnswer = _practiceSelectedAnswers[number];
    final isAnswered = selectedAnswer != null;
    final correctAnswer = exercise['correctAnswer'] as String;

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
          Text(
            'Câu hỏi $number',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.demonGlowPurple,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            exercise['question'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...(exercise['options'] as List).map((option) {
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
          }),
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
            section['content'] as String,
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
          final example = entry.value as String;
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
