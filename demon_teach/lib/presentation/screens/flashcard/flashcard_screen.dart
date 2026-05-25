import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/presentation/providers/flashcard_provider.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

/// Flashcard screen with flip animation and Demon Theme
class FlashcardScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final VoidCallback? onComplete;

  const FlashcardScreen({
    super.key,
    required this.lessonId,
    this.onComplete,
  });

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Load flashcards
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flashcardProvider.notifier).loadFlashcards(widget.lessonId);
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleFlip() {
    final notifier = ref.read(flashcardProvider.notifier);
    notifier.flipCard();

    if (ref.read(flashcardProvider).isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _handleNext() {
    _flipController.reverse();
    ref.read(flashcardProvider.notifier).nextCard();
  }

  void _handlePrevious() {
    _flipController.reverse();
    ref.read(flashcardProvider.notifier).previousCard();
  }

  void _handleDifficulty(DifficultyRating rating) {
    ref.read(flashcardProvider.notifier).markDifficulty(rating);
    _flipController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardProvider);

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thẻ Flashcard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (state.flashcards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.demonGlowPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${state.currentCardNumber}/${state.totalCards}',
                    style: const TextStyle(
                      color: AppTheme.demonGlowPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

          // Demon Fire Embers
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          // Main content
          SafeArea(
            child: _buildBody(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FlashcardState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null) {
      return Center(
        child: ErrorMessage(
          message: state.error!,
          onRetry: () {
            ref
                .read(flashcardProvider.notifier)
                .loadFlashcards(widget.lessonId);
          },
        ),
      );
    }

    if (state.flashcards.isEmpty) {
      return const Center(
        child: Text(
          'Không có thẻ từ vựng khả dụng cho bài học này.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppTheme.spacingSm),
        // Progress indicator
        _buildProgressIndicator(state),
        const SizedBox(height: AppTheme.spacingLg),

        // Flashcard
        Expanded(
          child: Center(
            child: _buildFlashcard(context, state),
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),
        // Navigation buttons
        _buildNavigationButtons(state),
        const SizedBox(height: AppTheme.spacingMd),

        // Difficulty buttons
        _buildDifficultyButtons(state),
        const SizedBox(height: AppTheme.spacingLg),
      ],
    );
  }

  Widget _buildProgressIndicator(FlashcardState state) {
    final progress = state.totalCards > 0 ? (state.currentCardNumber / state.totalCards) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.demonGlowPurple,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Thẻ ${state.currentCardNumber} / ${state.totalCards}',
            style: const TextStyle(
              color: AppTheme.demonTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(BuildContext context, FlashcardState state) {
    final flashcard = state.currentFlashcard;
    if (flashcard == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _handleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * math.pi;
          final isBack = angle > math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildCardBack(context, flashcard),
                  )
                : _buildCardFront(context, flashcard),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(BuildContext context, Flashcard flashcard) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.demonCardDark.withOpacity(0.7),
            AppTheme.demonBgGradientTop.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.demonGlowPurple.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  flashcard.frontText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: AppTheme.demonGlowPurple,
                        blurRadius: 10,
                      )
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (flashcard.phonetic != null && flashcard.phonetic!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    flashcard.phonetic!,
                    style: const TextStyle(
                      color: AppTheme.demonGlowPurple,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (flashcard.audioUrl != null)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.demonGlowPurple.withOpacity(0.2),
                          border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.white),
                          iconSize: 32,
                          onPressed: () {
                            // Audio playback logic (could play sound internally)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang phát âm thanh... 🔊'),
                                duration: Duration(milliseconds: 500),
                                backgroundColor: AppTheme.demonGlowPurple,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_outlined, color: AppTheme.demonTextMuted, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Chạm để lật mặt sau',
                      style: TextStyle(
                        color: AppTheme.demonTextMuted,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
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
  }

  Widget _buildCardBack(BuildContext context, Flashcard flashcard) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.demonCardDark.withOpacity(0.85),
            Colors.black.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  flashcard.backText,
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: AppTheme.secondaryColor,
                        blurRadius: 10,
                      )
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        flashcard.exampleUsage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (flashcard.exampleTranslation != null && flashcard.exampleTranslation!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          flashcard.exampleTranslation!,
                          style: TextStyle(
                            color: AppTheme.demonTextMuted,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_outlined, color: AppTheme.demonTextMuted, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Chạm để lật mặt trước',
                      style: TextStyle(
                        color: AppTheme.demonTextMuted,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
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
  }

  Widget _buildNavigationButtons(FlashcardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.hasPrevious ? AppTheme.demonGlowPurple.withOpacity(0.2) : Colors.transparent,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: 28,
              color: state.hasPrevious
                  ? Colors.white
                  : AppTheme.demonTextMuted.withOpacity(0.3),
              onPressed: state.hasPrevious ? _handlePrevious : null,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.hasNext ? AppTheme.demonGlowPurple.withOpacity(0.2) : Colors.transparent,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              iconSize: 28,
              color: state.hasNext
                  ? Colors.white
                  : AppTheme.demonTextMuted.withOpacity(0.3),
              onPressed: state.hasNext ? _handleNext : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButtons(FlashcardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          const Text(
            'Mức độ khó của từ này?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDifficultyButton(
                context,
                DifficultyRating.easy,
                Colors.green,
                state.isMarkingDifficulty,
              ),
              _buildDifficultyButton(
                context,
                DifficultyRating.medium,
                Colors.orange,
                state.isMarkingDifficulty,
              ),
              _buildDifficultyButton(
                context,
                DifficultyRating.hard,
                Colors.redAccent,
                state.isMarkingDifficulty,
              ),
            ],
          ),
          if (!state.hasNext && state.currentCardNumber == state.totalCards)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingLg),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.demonGlowPurple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Hoàn thành Flashcards 😈',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    DifficultyRating rating,
    Color color,
    bool isDisabled,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
            color: color.withOpacity(0.08),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isDisabled ? null : () => _handleDifficulty(rating),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Column(
              children: [
                Text(
                  rating.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  _getLocalizedDifficulty(rating),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedDifficulty(DifficultyRating rating) {
    switch (rating) {
      case DifficultyRating.easy:
        return "Dễ";
      case DifficultyRating.medium:
        return "Trung bình";
      case DifficultyRating.hard:
        return "Khó";
    }
  }
}
