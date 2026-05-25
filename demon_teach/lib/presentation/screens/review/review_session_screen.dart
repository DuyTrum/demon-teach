import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/presentation/providers/review_provider.dart';
import 'package:demon_teach/presentation/providers/flashcard_provider.dart';
import 'package:demon_teach/presentation/widgets/flashcard_widget.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';
import 'package:demon_teach/core/services/audio_feedback_service.dart';

/// Review session screen for spaced repetition (Demon Theme)
class ReviewSessionScreen extends ConsumerStatefulWidget {
  final String userId;

  const ReviewSessionScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  bool _isFlipped = false;
  DifficultyRating? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    // Load due reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadDueReviews(widget.userId);
    });
  }

  Future<void> _playSfx(String type) async {
    await ref.read(audioFeedbackServiceProvider).playSfx(type);
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    if (reviewState.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        appBar: AppBar(
          title: const Text('Phiên ôn tập', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.demonGlowPurple),
        ),
      );
    }

    if (reviewState.error != null) {
      return Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        appBar: AppBar(
          title: const Text('Phiên ôn tập', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Lỗi: ${reviewState.error}',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.demonGlowPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ref.read(reviewProvider.notifier).clearError();
                  ref.read(reviewProvider.notifier).loadDueReviews(widget.userId);
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (reviewState.dueReviews.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        appBar: AppBar(
          title: const Text('Phiên ôn tập', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: DemonBackgroundParticles()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.demonGlowGreen.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.demonGlowGreen.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  const Text(
                    'Không có mục cần ôn!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Kiến thức ác quỷ của bạn đang rất vững chắc.\nHãy quay lại sau.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.demonTextMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.demonNodeLocked,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.demonGlowGreen.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Quay lại bản đồ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (reviewState.isComplete) {
      return _buildCompletionScreen(context);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        title: Text(
          'Ôn tập ${reviewState.currentReviewNumber}/${reviewState.totalReviews}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.demonGlowPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
                ),
                child: Text(
                  'Còn lại ${reviewState.remainingReviews}',
                  style: const TextStyle(
                    color: AppTheme.demonGlowPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
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
          
          // Eerie Particles
          const Positioned.fill(child: DemonBackgroundParticles()),

          // Main Content
          SafeArea(
            child: _buildReviewContent(context, reviewState),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent(BuildContext context, ReviewState reviewState) {
    final currentReview = reviewState.currentReview;
    if (currentReview == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Progress indicator with neon glow
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.demonGlowPurple.withOpacity(0.5),
                blurRadius: 10,
              )
            ],
          ),
          child: LinearProgressIndicator(
            value: reviewState.currentReviewNumber / reviewState.totalReviews,
            backgroundColor: AppTheme.demonNodeLocked,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.demonGlowPurple),
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              children: [
                // Review type badge
                _buildReviewTypeBadge(currentReview.type),
                const SizedBox(height: AppTheme.spacingLg),
                
                // Review content (Flashcard)
                Expanded(
                  child: _buildReviewItemContent(currentReview),
                ),
                
                const SizedBox(height: AppTheme.spacingLg),
                
                // Difficulty rating buttons (shown after flip)
                AnimatedOpacity(
                  opacity: _isFlipped ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _isFlipped ? _buildDifficultyButtons() : const SizedBox.shrink(),
                ),
                
                const SizedBox(height: AppTheme.spacingMd),
                
                // Submit button
                if (_isFlipped && _selectedDifficulty != null)
                  _buildSubmitButton(reviewState),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTypeBadge(ReviewItemType type) {
    IconData icon;
    String label;
    Color color;

    switch (type) {
      case ReviewItemType.flashcard:
        icon = Icons.style;
        label = 'Thẻ từ';
        color = AppTheme.demonGlowPurple;
        break;
      case ReviewItemType.quiz:
        icon = Icons.quiz;
        label = 'Trắc nghiệm';
        color = Colors.orangeAccent;
        break;
      case ReviewItemType.listening:
        icon = Icons.headphones;
        label = 'Luyện nghe';
        color = AppTheme.demonGlowGreen;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItemContent(ReviewItem reviewItem) {
    if (reviewItem.type == ReviewItemType.flashcard) {
      return _buildFlashcardReview(reviewItem);
    }

    return Center(
      child: Text(
        'Kiểu ôn tập ${reviewItem.type.displayName} chưa được triển khai',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildFlashcardReview(ReviewItem reviewItem) {
    // Load the flashcard content
    return FutureBuilder(
      future: ref
          .read(flashcardRepositoryProvider)
          .getFlashcardById(reviewItem.contentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.demonGlowPurple));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Lỗi tải thẻ từ: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
          );
        }

        return snapshot.data!.when(
          success: (flashcard) => GestureDetector(
            onTap: () {
              if (!_isFlipped) {
                _playSfx('crystal'); // Flip sound
                setState(() {
                  _isFlipped = true;
                });
              } else {
                setState(() {
                  _isFlipped = false;
                });
              }
            },
            child: FlashcardWidget(
              flashcard: flashcard,
              isFlipped: _isFlipped,
            ),
          ),
          failure: (failure) => Center(
            child: Text('Lỗi: ${failure.message}', style: const TextStyle(color: Colors.redAccent)),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mức độ ghi nhớ của bạn?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildDifficultyButton(
                DifficultyRating.hard,
                '😰 Khó',
                Colors.redAccent,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildDifficultyButton(
                DifficultyRating.medium,
                '🤔 T.Bình',
                Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildDifficultyButton(
                DifficultyRating.easy,
                '😊 Dễ',
                AppTheme.demonGlowGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(
    DifficultyRating rating,
    String label,
    Color color,
  ) {
    final isSelected = _selectedDifficulty == rating;

    return GestureDetector(
      onTap: () {
        _playSfx('rune'); // Selection sound
        setState(() {
          _selectedDifficulty = rating;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.demonNodeLocked.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color.withOpacity(0.8),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ReviewState reviewState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: reviewState.isSubmitting
            ? null
            : () {
                _submitReview();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.demonGlowPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppTheme.demonGlowPurple,
        ),
        child: reviewState.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Gửi & Tiếp tục',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
      ),
    );
  }

  void _submitReview() {
    if (_selectedDifficulty == null) return;
    
    final reviewState = ref.read(reviewProvider);
    final isLast = !reviewState.hasNext;

    if (isLast) {
      _playSfx('victory');
    } else {
      _playSfx('whisper');
    }

    // Map difficulty to quality score
    final quality = ref
        .read(spacedRepetitionEngineProvider)
        .mapDifficultyToQuality(_selectedDifficulty!, true);

    final result = ReviewResult(
      isCorrect: true,
      quality: quality,
    );

    ref.read(reviewProvider.notifier).submitReviewResult(result: result);

    // Reset state for next card
    setState(() {
      _isFlipped = false;
      _selectedDifficulty = null;
    });
  }

  Widget _buildCompletionScreen(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      body: Stack(
        children: [
          const Positioned.fill(child: DemonBackgroundParticles()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.demonGlowPurple.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.demonGlowPurple.withOpacity(0.5),
                          blurRadius: 50,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  const Text(
                    'Đã hoàn thành ôn tập',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Bạn đã vượt qua ${reviewState.totalReviews} lượt ôn tập',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Kiến thức ác quỷ của bạn ngày càng mạnh mẽ.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.demonTextMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl * 2),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.demonNodeLocked,
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Quay lại bản đồ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
