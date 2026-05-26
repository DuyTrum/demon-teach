import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/bookmark_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';

/// Screen listing bookmarked vocabulary, allowing TTS audio playback
/// and running a custom review loop.
class BookmarkListScreen extends ConsumerStatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  ConsumerState<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends ConsumerState<BookmarkListScreen> {
  late final AudioPlayer _audioPlayer;
  String _searchQuery = '';
  bool _isPracticeMode = false;
  
  // Practice mode state variables
  int _practiceIndex = 0;
  bool _isCardFlipped = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Load bookmarks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(bookmarkProvider.notifier).loadBookmarks(user.id);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPronunciation(String text) async {
    final languagePref = ref.read(languageProvider).preference;
    final targetLang = languagePref?.targetLanguage ?? 'en';
    final url = '${AppConstants.apiBaseUrl}/api/tts?text=${Uri.encodeComponent(text)}&language=$targetLang';
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể phát âm thanh phát âm.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkProvider);
    final user = ref.watch(authProvider).user;
    
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        body: Center(child: Text('Vui lòng đăng nhập để xem từ vựng đã lưu.')),
      );
    }

    final filteredBookmarks = bookmarkState.bookmarks.where((fc) {
      final query = _searchQuery.toLowerCase();
      return fc.frontText.toLowerCase().contains(query) ||
             fc.backText.toLowerCase().contains(query) ||
             (fc.phonetic ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.demonGlowPurple,
        onPressed: () => _showAddBookmarkDialog(context, user.id),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (_isPracticeMode) {
              setState(() {
                _isPracticeMode = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isPracticeMode ? 'Nghi Thức Luyện Tập ⚔️' : 'Từ Vựng Yêu Thích 📖',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Demon background
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

          // Content
          SafeArea(
            child: bookmarkState.isLoading
                ? const Center(child: LoadingIndicator())
                : bookmarkState.bookmarks.isEmpty
                    ? _buildEmptyState()
                    : _isPracticeMode
                        ? _buildPracticeView(filteredBookmarks)
                        : _buildListView(filteredBookmarks, user.id),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👻', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Hành trang trống rỗng...\nHãy lưu các từ khó khi học Flashcards!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.demonTextMuted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Flashcard> items, String userId) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm từ vựng đã lưu...',
                hintStyle: const TextStyle(color: AppTheme.demonTextMuted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.demonTextMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // List View
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy từ vựng nào khớp.',
                    style: TextStyle(color: AppTheme.demonTextMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildBookmarkCard(item, userId);
                  },
                ),
        ),

        // Bottom practice trigger button
        if (items.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppTheme.demonBgGradientBot.withOpacity(0.95), AppTheme.demonBgGradientBot],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor]),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.demonGlowPurple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPracticeMode = true;
                      _practiceIndex = 0;
                      _isCardFlipped = false;
                    });
                  },
                  icon: const Icon(Icons.psychology_alt_rounded, color: Colors.white),
                  label: const Text(
                    'LUYỆN TẬP FLASHCARD',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookmarkCard(Flashcard item, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Text side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            item.frontText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.phonetic != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.phonetic!,
                              style: const TextStyle(
                                color: AppTheme.demonGlowPurple,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.backText,
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.exampleUsage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.exampleUsage,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: AppTheme.demonGlowPurple),
                      onPressed: () => _playPronunciation(item.frontText),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () async {
                        final success = await ref
                            .read(bookmarkProvider.notifier)
                            .toggleBookmark(userId, item);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã bỏ lưu từ vựng khỏi danh sách yêu thích.'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        }
                      },
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

  void _showAddBookmarkDialog(BuildContext context, String userId) {
    final formKey = GlobalKey<FormState>();
    String word = '';
    String phonetic = '';
    String translation = '';
    String example = '';
    String exampleTrans = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.demonNodeLocked,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppTheme.demonGlowPurple.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.bookmark_add_rounded, color: AppTheme.demonGlowPurple),
              SizedBox(width: 8),
              Text(
                'Thêm Từ Vựng Mới',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Từ vựng (Tiếng Anh/Nhật...) *',
                      labelStyle: TextStyle(color: AppTheme.demonTextMuted),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.demonGlowPurple),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập từ vựng';
                      }
                      return null;
                    },
                    onSaved: (val) => word = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Phiên âm (Ví dụ: /əˈbaʊt/)',
                      labelStyle: TextStyle(color: AppTheme.demonTextMuted),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.demonGlowPurple),
                      ),
                    ),
                    onSaved: (val) => phonetic = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nghĩa tiếng Việt *',
                      labelStyle: TextStyle(color: AppTheme.demonTextMuted),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.demonGlowPurple),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập nghĩa';
                      }
                      return null;
                    },
                    onSaved: (val) => translation = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Ví dụ sử dụng (nếu có)',
                      labelStyle: TextStyle(color: AppTheme.demonTextMuted),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.demonGlowPurple),
                      ),
                    ),
                    onSaved: (val) => example = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Dịch nghĩa ví dụ (nếu có)',
                      labelStyle: TextStyle(color: AppTheme.demonTextMuted),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.demonGlowPurple),
                      ),
                    ),
                    onSaved: (val) => exampleTrans = val?.trim() ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'HỦY',
                style: TextStyle(color: AppTheme.demonTextMuted, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.demonGlowPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  
                  final newFlashcard = Flashcard(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    lessonId: 'custom_vocabulary',
                    frontText: word,
                    backText: translation,
                    phonetic: phonetic.isNotEmpty ? phonetic : null,
                    exampleUsage: example,
                    exampleTranslation: exampleTrans.isNotEmpty ? exampleTrans : null,
                  );

                  final success = await ref
                      .read(bookmarkProvider.notifier)
                      .toggleBookmark(userId, newFlashcard);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success 
                              ? 'Đã thêm từ vựng thành công! 🌟' 
                              : 'Thêm từ vựng thất bại!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: success ? AppTheme.demonGlowPurple : Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('THÊM', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  Practice Mode (Subset Flashcard loop)
  // ─────────────────────────────────────────────
  Widget _buildPracticeView(List<Flashcard> items) {
    if (items.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => setState(() => _isPracticeMode = false),
          child: const Text('Quay lại danh sách', style: TextStyle(color: AppTheme.demonGlowPurple)),
        ),
      );
    }

    if (_practiceIndex >= items.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Đã hoàn thành ôn tập từ vựng yêu thích!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CustomPracticeButton(
              text: 'Quay lại danh sách',
              onPressed: () {
                setState(() {
                  _isPracticeMode = false;
                });
              },
            ),
          ],
        ),
      );
    }

    final card = items[_practiceIndex];

    return Column(
      children: [
        // Progress header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Từ thứ ${_practiceIndex + 1} / ${items.length}',
                style: const TextStyle(color: AppTheme.demonTextMuted, fontWeight: FontWeight.bold),
              ),
              Text(
                '${((_practiceIndex / items.length) * 100).toStringAsFixed(0)}% Hoàn thành',
                style: const TextStyle(color: AppTheme.demonGlowPurple, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Flip Card Player
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isCardFlipped = !_isCardFlipped;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isCardFlipped
                        ? [AppTheme.demonCardDark.withOpacity(0.85), Colors.black.withOpacity(0.7)]
                        : [AppTheme.demonCardDark.withOpacity(0.7), AppTheme.demonBgGradientTop.withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isCardFlipped ? AppTheme.secondaryColor.withOpacity(0.3) : AppTheme.demonGlowPurple.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isCardFlipped ? AppTheme.secondaryColor : AppTheme.demonGlowPurple).withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isCardFlipped) ...[
                        Text(
                          card.frontText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: AppTheme.demonGlowPurple, blurRadius: 10)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (card.phonetic != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            card.phonetic!,
                            style: const TextStyle(color: AppTheme.demonGlowPurple, fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                        ],
                        const SizedBox(height: 24),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.white, size: 30),
                          onPressed: () => _playPronunciation(card.frontText),
                        ),
                      ] else ...[
                        Text(
                          card.backText,
                          style: const TextStyle(
                            color: AppTheme.secondaryColor,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: AppTheme.secondaryColor, blurRadius: 10)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (card.exampleUsage.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              card.exampleUsage,
                              style: const TextStyle(color: Colors.white70, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 30),
                      Text(
                        _isCardFlipped ? 'Chạm để xem từ' : 'Chạm để lật nghĩa',
                        style: const TextStyle(color: AppTheme.demonTextMuted, fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: _practiceIndex > 0
                    ? () {
                        setState(() {
                          _practiceIndex--;
                          _isCardFlipped = false;
                        });
                      }
                    : null,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _practiceIndex++;
                    _isCardFlipped = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.demonGlowPurple.withOpacity(0.2),
                  side: const BorderSide(color: AppTheme.demonGlowPurple),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _practiceIndex == items.length - 1 ? 'HOÀN THÀNH' : 'TỪ TIẾP THEO',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomPracticeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomPracticeButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
        color: AppTheme.demonGlowPurple.withOpacity(0.1),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
