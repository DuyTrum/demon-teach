import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:demon_teach/core/constants/app_constants.dart';

/// Service to handle UI sound effects and haptic feedback
class AudioFeedbackService {
  final AudioPlayer _audioPlayer;

  AudioFeedbackService() : _audioPlayer = AudioPlayer();

  /// Play sound effect and trigger haptics
  Future<void> playSfx(String type) async {
    // 1. Trigger haptic feedback
    switch (type) {
      case 'crystal':
        HapticFeedback.lightImpact();
        break;
      case 'rune':
        HapticFeedback.mediumImpact();
        break;
      case 'whisper':
        HapticFeedback.selectionClick();
        break;
      case 'victory':
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.vibrate();
    }

    // 2. Build backend SFX url
    final String url = '${AppConstants.apiBaseUrl}/api/sfx/$type';

    try {
      // Re-create player if it was disposed, or just play if initialized
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      // Fallback silently if audio fails (e.g. no network or server down)
      debugPrint('AudioFeedbackService Error: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

/// Provider for AudioFeedbackService
final audioFeedbackServiceProvider = Provider<AudioFeedbackService>((ref) {
  final service = AudioFeedbackService();
  ref.onDispose(() => service.dispose());
  return service;
});
