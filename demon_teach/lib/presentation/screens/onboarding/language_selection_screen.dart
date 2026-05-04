import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/screens/onboarding/assessment_screen.dart';

/// Language selection screen for onboarding
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

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
      body: SafeArea(
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
                    Text(
                      'Welcome to Demon Teach! 👋',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Let\'s start by selecting your languages',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.spacingXl),

                    // Target Language Selection
                    Text(
                      'What language do you want to learn?',
                      style: Theme.of(context).textTheme.titleLarge,
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
                    Text(
                      'What is your native language?',
                      style: Theme.of(context).textTheme.titleLarge,
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
              child: CustomButton(
                text: 'Continue',
                onPressed:
                    _canContinue() ? () => _handleContinue(context) : null,
                isLoading: languageState.isLoading,
                width: double.infinity,
              ),
            ),
          ],
        ),
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

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final success = await ref.read(languageProvider.notifier).savePreferences(
          userId: user.id,
          targetLanguage: selectedTargetLanguage!,
          nativeLanguage: selectedNativeLanguage!,
        );

    if (success && context.mounted) {
      // Navigate to assessment screen
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AssessmentScreen(),
        ),
      );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                    ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
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
