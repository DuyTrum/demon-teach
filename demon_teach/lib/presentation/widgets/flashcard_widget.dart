import 'package:flutter/material.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:just_audio/just_audio.dart';

/// Widget to display a flashcard with flip animation
class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final bool isFlipped;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    this.isFlipped = false,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
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
    if (widget.flashcard.audioUrl == null) return;
    try {
      await _audioPlayer.setUrl(widget.flashcard.audioUrl!);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isFlipped
                ? [
                    AppTheme.accentColor.withOpacity(0.15),
                    AppTheme.accentColor.withOpacity(0.05),
                  ]
                : [
                    AppTheme.primaryColor.withOpacity(0.15),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Side indicator & Phonetic
            if (!widget.isFlipped && widget.flashcard.phonetic != null)
              Text(
                widget.flashcard.phonetic!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.2,
                    ),
              ),
            const SizedBox(height: AppTheme.spacingMd),

            // Main text
            SelectableText(
              widget.isFlipped ? widget.flashcard.backText : widget.flashcard.frontText,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
              textAlign: TextAlign.center,
            ),

            // Sino-Vietnamese Reading (only on back)
            if (widget.isFlipped && widget.flashcard.sinoVietReading != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Hán Việt: ${widget.flashcard.sinoVietReading}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],

            // Example usage
            if (widget.isFlipped) ...[
              const SizedBox(height: AppTheme.spacingXl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Ví dụ:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      widget.flashcard.exampleUsage,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    if (widget.flashcard.exampleTranslation != null) ...[
                      const Divider(height: 16),
                      Text(
                        widget.flashcard.exampleTranslation!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spacingXl),

            // Actions: Audio & Flip
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.flashcard.audioUrl != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _playAudio,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                if (widget.flashcard.audioUrl != null) const SizedBox(width: AppTheme.spacingLg),
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  widget.isFlipped ? 'Chạm để xem từ' : 'Chạm để xem nghĩa',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
