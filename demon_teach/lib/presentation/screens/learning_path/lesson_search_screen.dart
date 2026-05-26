import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/presentation/providers/lesson_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/screens/lesson/daily_lesson_screen.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';

class LessonSearchScreen extends ConsumerStatefulWidget {
  const LessonSearchScreen({super.key});

  @override
  ConsumerState<LessonSearchScreen> createState() => _LessonSearchScreenState();
}

class _LessonSearchScreenState extends ConsumerState<LessonSearchScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedDifficulty;
  
  List<Lesson> _allLessons = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLessons();
    });
  }

  Future<void> _fetchLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final languagePref = ref.read(languageProvider).preference;
    final targetLang = languagePref?.targetLanguage ?? 'en';

    try {
      final repo = ref.read(lessonRepositoryProvider);
      final result = await repo.getLessonsByLanguage(targetLang);
      
      result.when(
        success: (lessons) {
          setState(() {
            _allLessons = lessons;
            _isLoading = false;
          });
        },
        failure: (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathState = ref.watch(learningPathProvider);
    final path = pathState.path;

    // Filter logic
    final filteredLessons = _allLessons.where((lesson) {
      final matchesSearch = lesson.metadata.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lesson.metadata.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == null || 
          lesson.metadata.category.name.toLowerCase() == _selectedCategory!.toLowerCase();
          
      final matchesDifficulty = _selectedDifficulty == null || 
          lesson.metadata.difficulty.name.toLowerCase() == _selectedDifficulty!.toLowerCase();

      return matchesSearch && matchesCategory && matchesDifficulty;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tìm Kiếm Bài Học 🔮',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
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
          const Positioned.fill(child: DemonBackgroundParticles()),

          SafeArea(
            child: Column(
              children: [
                _buildSearchAndFilters(),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: LoadingIndicator())
                      : _errorMessage != null
                          ? _buildErrorState()
                          : filteredLessons.isEmpty
                              ? _buildEmptyState()
                              : _buildLessonsList(filteredLessons, path),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final categories = ['Vocab', 'Grammar', 'Speaking', 'Listening'];
    final difficulties = ['Beginner', 'Intermediate', 'Advanced'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Input
          Container(
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
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm bài học ma thuật...',
                hintStyle: TextStyle(color: AppTheme.demonTextMuted),
                prefixIcon: Icon(Icons.search, color: AppTheme.demonTextMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Reset categories button
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('Tất cả Thể loại'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = null;
                        });
                      }
                    },
                    selectedColor: AppTheme.demonGlowPurple,
                    backgroundColor: Colors.black.withOpacity(0.3),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                ...categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_getCategoryLabel(cat)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                      selectedColor: AppTheme.demonGlowPurple,
                      backgroundColor: Colors.black.withOpacity(0.3),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Difficulty Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Reset difficulties button
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('Mọi Độ khó'),
                    selected: _selectedDifficulty == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDifficulty = null;
                        });
                      }
                    },
                    selectedColor: AppTheme.demonGlowPurple,
                    backgroundColor: Colors.black.withOpacity(0.3),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                ...difficulties.map((diff) {
                  final isSelected = _selectedDifficulty == diff;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_getDifficultyLabel(diff)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDifficulty = selected ? diff : null;
                        });
                      },
                      selectedColor: AppTheme.demonGlowPurple,
                      backgroundColor: Colors.black.withOpacity(0.3),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Lỗi: $_errorMessage',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchLessons,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Không tìm thấy bài học nào khớp với bộ lọc.',
        style: TextStyle(color: AppTheme.demonTextMuted, fontSize: 15),
      ),
    );
  }

  Widget _buildLessonsList(List<Lesson> lessons, dynamic path) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        
        // Determine lock state based on learning path
        bool isUnlocked = true;
        if (path != null) {
          final lessonIndex = path.lessonIds.indexOf(lesson.metadata.id);
          if (lessonIndex != -1) {
            isUnlocked = lessonIndex <= path.currentLessonIndex;
          }
        }

        return _buildLessonCard(lesson, isUnlocked);
      },
    );
  }

  Widget _buildLessonCard(Lesson lesson, bool isUnlocked) {
    final meta = lesson.metadata;
    final catIcon = _getCategoryIcon(meta.category.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(isUnlocked ? 0.65 : 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked 
              ? AppTheme.demonGlowPurple.withOpacity(0.2) 
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isUnlocked ? AppTheme.demonGlowPurple : Colors.grey).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isUnlocked ? AppTheme.demonGlowPurple : Colors.grey).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                isUnlocked ? catIcon : '🔒',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            title: Text(
              meta.title,
              style: TextStyle(
                color: isUnlocked ? Colors.white : AppTheme.demonTextMuted,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  meta.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white70 : AppTheme.demonTextMuted.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge(_getCategoryLabel(meta.category.name), AppTheme.demonGlowPurple),
                    const SizedBox(width: 6),
                    _buildBadge(_getDifficultyLabel(meta.difficulty.name), AppTheme.secondaryColor),
                  ],
                ),
              ],
            ),
            trailing: isUnlocked
                ? const Icon(Icons.arrow_forward_ios, color: AppTheme.demonGlowPurple, size: 16)
                : null,
            onTap: isUnlocked
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyLessonScreen(lessonId: meta.id),
                      ),
                    );
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('😈 Bài học này đang bị khóa. Hãy tiếp tục hành trình lộ trình để mở khóa!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vocab':
      case 'vocabulary':
        return '📖';
      case 'grammar':
        return '📝';
      case 'speaking':
        return '🎤';
      case 'listening':
        return '🎧';
      default:
        return '📚';
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'vocab':
      case 'vocabulary':
        return 'Từ vựng';
      case 'grammar':
        return 'Ngữ pháp';
      case 'speaking':
        return 'Nói';
      case 'listening':
        return 'Nghe';
      default:
        return category;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'basic':
        return 'Sơ cấp';
      case 'intermediate':
        return 'Trung cấp';
      case 'advanced':
        return 'Cao cấp';
      default:
        return difficulty;
    }
  }
}
