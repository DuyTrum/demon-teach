import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/screens/onboarding/assessment_screen.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

/// Language selection screen for onboarding or settings
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool isFromSettings;

  const LanguageSelectionScreen({
    super.key,
    this.isFromSettings = false,
  });

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String? selectedTargetLanguage;
  String? selectedNativeLanguage;

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final supportedTargetLanguages =
        ref.watch(supportedTargetLanguagesProvider);
    final supportedNativeLanguages =
        ref.watch(supportedNativeLanguagesProvider);

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
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
          // Embers
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppTheme.spacingXl),

                        // Header
                        const Text(
                          'Chào mừng đến với Demon Teach! 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: AppTheme.demonGlowPurple, blurRadius: 15),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        const Text(
                          'Hãy bắt đầu bằng việc chọn ngôn ngữ của bạn',
                          style: TextStyle(
                            color: AppTheme.demonTextMuted,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppTheme.spacingXl),

                        // Target Language Selection
                        const Text(
                          'Bạn muốn học ngôn ngữ nào?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        ...supportedTargetLanguages.map((langCode) {
                          final displayName = ref.read(
                            languageDisplayNameProvider(langCode),
                          );
                          final isSelected = selectedTargetLanguage == langCode;

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTheme.spacingSm),
                            child: _LanguageCard(
                              languageCode: langCode,
                              displayName: displayName,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedTargetLanguage = langCode;
                                });
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: AppTheme.spacingLg),

                        // Native Language Selection
                        const Text(
                          'Ngôn ngữ mẹ đẻ của bạn?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        ...supportedNativeLanguages.map((langCode) {
                          final displayName = ref.read(
                            languageDisplayNameProvider(langCode),
                          );
                          final isSelected = selectedNativeLanguage == langCode;

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTheme.spacingSm),
                            child: _LanguageCard(
                              languageCode: langCode,
                              displayName: displayName,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedNativeLanguage = langCode;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Continue Button - Fixed at bottom
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _canContinue()
                          ? const LinearGradient(colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor])
                          : null,
                      color: _canContinue() ? null : AppTheme.demonNodeLocked.withOpacity(0.4),
                      border: Border.all(
                        color: _canContinue()
                            ? AppTheme.demonGlowPurple.withOpacity(0.5)
                            : Colors.white.withOpacity(0.05),
                      ),
                      boxShadow: _canContinue()
                          ? [
                              BoxShadow(
                                color: AppTheme.demonGlowPurple.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _canContinue() && !languageState.isLoading ? () => _handleContinue(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: languageState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Tiếp tục 😈',
                              style: TextStyle(
                                color: _canContinue() ? Colors.white : AppTheme.demonTextMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    return selectedTargetLanguage != null && selectedNativeLanguage != null;
  }

  Future<void> _handleContinue(BuildContext context) async {
    if (!_canContinue()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Save preferences locally
    final success = await ref.read(languageProvider.notifier).savePreferences(
          targetLanguage: selectedTargetLanguage!,
          nativeLanguage: selectedNativeLanguage!,
        );

    if (success) {
      // Synchronize preferences to backend user profile if user is logged in
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref.read(authProvider.notifier).updateProfile(
              nativeLanguage: selectedNativeLanguage!,
              targetLanguages: [selectedTargetLanguage!],
            );
      }

      if (context.mounted) {
        if (widget.isFromSettings) {
          // Return to settings/profile
          navigator.pop(true);
        } else {
          // Navigate to assessment screen
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AssessmentScreen(),
            ),
          );
        }
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to save preferences. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

/// Language selection card widget
class _LanguageCard extends StatelessWidget {
  final String languageCode;
  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.languageCode,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.demonGlowPurple.withOpacity(0.15)
            : AppTheme.demonCardDark.withOpacity(0.5),
        border: Border.all(
          color: isSelected ? AppTheme.demonGlowPurple : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [BoxShadow(color: AppTheme.demonGlowPurple.withOpacity(0.2), blurRadius: 10)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.demonGlowPurple.withOpacity(0.2)
                            : AppTheme.demonNodeLocked.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.demonGlowPurple.withOpacity(0.4)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getFlagEmoji(languageCode),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.demonTextLight,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.demonGlowPurple,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'zh':
        return '🇨🇳';
      case 'ko':
        return '🇰🇷';
      case 'vi':
        return '🇻🇳';
      default:
        return '🌍';
    }
  }
}
