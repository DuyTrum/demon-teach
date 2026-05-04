import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/presentation/providers/flashcard_provider.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';

/// Flashcard screen with flip animation
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
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          if (state.flashcards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: Center(
                child: Text(
                  '${state.currentCardNumber}/${state.totalCards}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, state),
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
        child: Text('No flashcards available for this lesson.'),
      );
    }

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(state),
        const SizedBox(height: AppTheme.spacingLg),

        // Flashcard
        Expanded(
          child: Center(
            child: _buildFlashcard(context, state),
          ),
        ),

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: state.currentCardNumber / state.totalCards,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Card ${state.currentCardNumber} of ${state.totalCards}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
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
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            flashcard.frontText,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (flashcard.audioUrl != null)
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  iconSize: 40,
                  onPressed: () {
                    // TODO: Play audio
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
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            'Tap to flip',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(BuildContext context, Flashcard flashcard) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              flashcard.backText,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                flashcard.exampleUsage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'Tap to flip back',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 40,
            color: state.hasPrevious
                ? AppTheme.primaryColor
                : AppTheme.textDisabledColor,
            onPressed: state.hasPrevious ? _handlePrevious : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            iconSize: 40,
            color: state.hasNext
                ? AppTheme.primaryColor
                : AppTheme.textDisabledColor,
            onPressed: state.hasNext ? _handleNext : null,
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
          Text(
            'How difficult was this card?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDifficultyButton(
                context,
                DifficultyRating.easy,
                AppTheme.successColor,
                state.isMarkingDifficulty,
              ),
              _buildDifficultyButton(
                context,
                DifficultyRating.medium,
                AppTheme.warningColor,
                state.isMarkingDifficulty,
              ),
              _buildDifficultyButton(
                context,
                DifficultyRating.hard,
                AppTheme.errorColor,
                state.isMarkingDifficulty,
              ),
            ],
          ),
          if (!state.hasNext && state.currentCardNumber == state.totalCards)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingLg),
              child: ElevatedButton(
                onPressed: widget.onComplete,
                child: const Text('Complete Flashcards'),
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
        child: ElevatedButton(
          onPressed: isDisabled ? null : () => _handleDifficulty(rating),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          ),
          child: Column(
            children: [
              Text(
                rating.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                rating.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
