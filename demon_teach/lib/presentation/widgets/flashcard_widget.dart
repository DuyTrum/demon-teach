import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:just_audio/just_audio.dart';
import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/bookmark_provider.dart';

/// Widget to display a flashcard with 3D flip animation
class FlashcardWidget extends ConsumerStatefulWidget {
  final Flashcard flashcard;
  final bool isFlipped;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    this.isFlipped = false,
  });

  @override
  ConsumerState<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends ConsumerState<FlashcardWidget> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    var url = widget.flashcard.audioUrl;
    if (url == null || url.isEmpty) {
      final languageState = ref.read(languageProvider);
      final targetLang = languageState.preference?.targetLanguage ?? 'en';
      url = '/api/tts?text=${Uri.encodeComponent(widget.flashcard.frontText)}&language=$targetLang';
    }
    if (url.startsWith('/')) {
      url = '${AppConstants.apiBaseUrl}$url';
    }
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

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: widget.isFlipped ? pi : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack, // Gives a slight bounce effect
      builder: (context, double value, child) {
        bool isUnder = (value > pi / 2);
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(value),
          alignment: Alignment.center,
          child: isUnder
              ? Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _buildCardFace(isBack: true),
                )
              : _buildCardFace(isBack: false),
        );
      },
    );
  }

  Widget _buildCardFace({required bool isBack}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 400, // Fixed height so the card doesn't jump in size when flipped
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isBack ? AppTheme.demonGlowPurple.withOpacity(0.5) : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isBack
                  ? [
                      AppTheme.demonGlowPurple.withOpacity(0.2),
                      AppTheme.demonNodeLocked.withOpacity(0.8),
                    ]
                  : [
                      AppTheme.demonNodeLocked.withOpacity(0.6),
                      AppTheme.demonBgGradientTop.withOpacity(0.8),
                    ],
            ),
            boxShadow: [
              if (isBack)
                BoxShadow(
                  color: AppTheme.demonGlowPurple.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 1,
                )
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isBack && widget.flashcard.phonetic != null)
                    Text(
                      widget.flashcard.phonetic!,
                      style: TextStyle(
                        fontSize: 20,
                        color: AppTheme.demonGlowPurple,
                        letterSpacing: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (!isBack) const SizedBox(height: AppTheme.spacingMd),

                  // Main text
                  SelectableText(
                    isBack ? widget.flashcard.backText : widget.flashcard.frontText,
                    style: TextStyle(
                      fontSize: isBack ? 32 : 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: (isBack ? AppTheme.demonGlowPurple : Colors.white).withOpacity(0.5),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Sino-Vietnamese Reading (only on back)
                  if (isBack && widget.flashcard.sinoVietReading != null) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.demonGlowGreen.withOpacity(0.5)),
                      ),
                      child: Text(
                        'Hán Việt: ${widget.flashcard.sinoVietReading}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.demonGlowGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Example usage
                  if (isBack && widget.flashcard.exampleUsage.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orangeAccent),
                              const SizedBox(width: 8),
                              Text(
                                'Ví dụ:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.demonTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            widget.flashcard.exampleUsage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                          ),
                          if (widget.flashcard.exampleTranslation != null) ...[
                            const Divider(color: Colors.white24, height: 16),
                            Text(
                              widget.flashcard.exampleTranslation!,
                              style: TextStyle(
                                color: AppTheme.demonTextMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingXl),

                  // Actions: Audio & Flip Instruction
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.flashcard.frontText.isNotEmpty)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _playAudio,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.demonGlowPurple.withOpacity(0.2),
                                border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
                              ),
                              child: const Icon(
                                Icons.volume_up,
                                color: AppTheme.demonGlowPurple,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      if (widget.flashcard.frontText.isNotEmpty) const SizedBox(width: AppTheme.spacingLg),
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: AppTheme.demonTextMuted,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        isBack ? 'Chạm để lật lại' : 'Chạm để xem nghĩa',
                        style: TextStyle(
                          color: AppTheme.demonTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Consumer(
                  builder: (context, ref, _) {
                    final user = ref.watch(authProvider).user;
                    final bookmarkState = ref.watch(bookmarkProvider);
                    final isFav = bookmarkState.bookmarkedIds.contains(widget.flashcard.id);
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isFav ? AppTheme.demonGlowPurple : AppTheme.demonTextMuted,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (user != null) {
                          final success = await ref
                              .read(bookmarkProvider.notifier)
                              .toggleBookmark(user.id, widget.flashcard);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFav ? 'Đã bỏ lưu từ vựng!' : 'Đã lưu từ vựng yêu thích! 🌟',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: isFav ? Colors.redAccent : AppTheme.demonGlowPurple,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
