import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/presentation/screens/onboarding/assessment_screen.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/widgets/achievement/achievement_unlock_dialog.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/lesson/daily_lesson_screen.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';

// ─── Dark Demon Theme Colors ───
const _kBgGradientTop = Color(0xFF1A0A2E);
const _kBgGradientMid = Color(0xFF16082A);
const _kBgGradientBot = Color(0xFF0D0519);
const _kNodeCompleted = Color(0xFF43A047);
const _kNodeCurrent = Color(0xFF7C4DFF);
const _kNodeLocked = Color(0xFF352A4E);
const _kGlowPurple = Color(0xFF9C7CFF);
const _kGlowGreen = Color(0xFF66BB6A);
const _kPathDone = Color(0xFF9C7CFF);
const _kPathLocked = Color(0xFF382558);
const _kCardDark = Color(0xFF1E1235);
const _kTextLight = Color(0xFFE8E0F0);
const _kTextMuted = Color(0xFF8A7DA0);

// ─── Node sizing ───
const _kNodeSize = 64.0;
const _kNodeSizeCurrent = 82.0;
const _kPathWidth = 6.0;
const _kMapHorizontalPad = 32.0;

class LearningPathScreen extends ConsumerStatefulWidget {
  const LearningPathScreen({super.key});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPath());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPath() async {
    final user = ref.read(authProvider).user;
    final languagePref = ref.read(languageProvider).preference;
    if (user != null && languagePref != null) {
      ref.read(learningPathProvider.notifier).loadLearningPath(
            userId: user.id,
            targetLanguage: languagePref.targetLanguage,
          );
    }
  }

  void _scrollToCurrentNode(int currentIndex, int total) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // Each node row is approximately 120px tall, plus header ~200px
      final targetOffset = 200.0 + currentIndex * 120.0 - 200;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pathState = ref.watch(learningPathProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Hành Trình Ác Quỷ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _kTextLight,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kTextLight),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kBgGradientTop, _kBgGradientMid, _kBgGradientBot],
          ),
        ),
        child: pathState.isLoading || pathState.isGenerating
            ? const Center(child: LoadingIndicator())
            : pathState.error != null
                ? Center(
                    child: ErrorMessage(
                      message: pathState.error!,
                      onRetry: _loadPath,
                    ),
                  )
                : pathState.path == null
                    ? _buildEmptyState()
                    : _buildAdventureMap(context, pathState),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😈', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có lộ trình nào...\nHãy tạo một lộ trình để bắt đầu!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextLight, fontSize: 16),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Tạo Lộ trình học',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssessmentScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdventureMap(BuildContext context, LearningPathState pathState) {
    final path = pathState.path!;
    final totalLessons = path.lessonIds.length;
    final currentIdx = path.currentLessonIndex;
    final percentage = path.completionPercentage;

    // Auto-scroll to current node
    _scrollToCurrentNode(currentIdx, totalLessons);

    return Stack(
      children: [
        // ─── Spooky background animated embers/particles ───
        const Positioned.fill(
          child: DemonBackgroundParticles(),
        ),
        // ─── Scrollable map ───
        SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              const SizedBox(height: 100), // space for AppBar
              // ─── Progress header ───
              _buildProgressHeader(path, percentage),
              const SizedBox(height: 24),
              // ─── Map nodes ───
              _buildMapPath(path, totalLessons, currentIdx),
              const SizedBox(height: 40),
            ],
          ),
        ),

        // ─── Bottom floating action bar ───
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBar(path, currentIdx),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Progress Header
  // ─────────────────────────────────────────────
  Widget _buildProgressHeader(dynamic path, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1235).withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _kGlowPurple.withOpacity(0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kGlowPurple.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Demonic level badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: _kGlowPurple.withOpacity(0.4)),
                      ),
                      child: const Text('😈', style: TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CẤP ĐỘ ÁC QUỶ: ${path.targetLanguage.toUpperCase()}',
                            style: const TextStyle(
                              color: Color(0xFFFF4081),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${path.proficiencyLevel.displayName} • ${path.goalType.displayName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Soul XP & Streak Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9100).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFF9100).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🔥', style: TextStyle(fontSize: 11)),
                              SizedBox(width: 4),
                              Text(
                                '7 Ngày',
                                style: TextStyle(
                                  color: Color(0xFFFF9100),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                          ),
                          child: const Text(
                            '⚡ 450 Soul XP',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Custom progress bar with demonic text
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 10,
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: const Color(0xFF2A2040),
                            valueColor: const AlwaysStoppedAnimation<Color>(_kGlowPurple),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: _kGlowPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khám phá: ${path.currentLessonIndex} / ${path.lessonIds.length} Chương',
                      style: const TextStyle(color: Color(0xFF8A7DA0), fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () => _showModifyPathSheet(context, path),
                      child: const Text(
                        '🔮 Khế ước Ác Ma',
                        style: TextStyle(
                          color: _kGlowPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
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

  // ─────────────────────────────────────────────
  //  Map Path (zigzag nodes with Duolingo-style floating side decorations)
  // ─────────────────────────────────────────────
  Widget _buildMapPath(dynamic path, int total, int currentIdx) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: List.generate(total, (index) {
        final lessonId = path.lessonIds[index];
        final isCompleted = index < currentIdx;
        final isCurrent = index == currentIdx;
        final isLocked = index > currentIdx;

        // Zigzag: even index → left, odd index → right
        final isLeft = index.isEven;

        // Parse lesson type from ID
        final parts = lessonId.split('_');
        final category = parts.length > 2 ? parts[2] : 'vocab';

        final nodeWidget = _buildMapNode(
          index: index,
          lessonId: lessonId,
          category: category,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLocked: isLocked,
        );

        final decorationWidget = _buildDecoration(index);

        return Column(
          children: [
            // Draw path line from previous node (except for first)
            if (index > 0)
              _buildPathLine(
                isLeft: isLeft,
                isCompleted: index <= currentIdx,
                screenWidth: screenWidth,
              ),
            // Row with Node on one side and decoration on the opposite
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kMapHorizontalPad),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: isLeft
                    ? [
                        nodeWidget,
                        decorationWidget,
                      ]
                    : [
                        decorationWidget,
                        nodeWidget,
                      ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  //  Duolingo-style Adventure Map Decorations
  // ─────────────────────────────────────────────
  Widget _buildDecoration(int index) {
    final decorations = [
      {'emoji': '🏰', 'name': 'Thành Ác Quỷ', 'desc': 'Quỷ Vương cai quản'},
      {'emoji': '🪦', 'name': 'Mộ Vọng Hồn', 'desc': 'Kẻ thất bại yên nghỉ'},
      {'emoji': '🦇', 'name': 'Hang Quỷ Dơi', 'desc': 'Tiếng cánh đập xào xạc'},
      {'emoji': '💀', 'name': 'Bãi Xương Khô', 'desc': 'Cốt tủy sa ngã'},
      {'emoji': '🔮', 'name': 'Vạc Phù Thủy', 'desc': 'Độc dược thông thái'},
      {'emoji': '👻', 'name': 'Hồn Ma Trơi', 'desc': 'Lửa xanh chỉ đường'},
      {'emoji': '🌋', 'name': 'Giếng Nham Thạch', 'desc': 'Nhiệt lượng hừng hực'},
      {'emoji': '🐈‍⬛', 'name': 'Mèo Ác Ma', 'desc': 'Đôi mắt rực lửa dõi theo'},
      {'emoji': '🌲', 'name': 'Rừng Gai Đen', 'desc': 'Bóng tối vây quanh'},
      {'emoji': '🥀', 'name': 'Bỉ Ngạn Hoa', 'desc': 'Lối về cõi âm'},
    ];

    final dec = decorations[index % decorations.length];
    final isFloatUp = index % 2 == 0;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardDark.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPathLocked.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dec['emoji']!, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dec['name']!,
                style: const TextStyle(
                  color: _kTextLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dec['desc']!,
                style: const TextStyle(
                  color: _kTextMuted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Apply smooth counter-floating animation for parallax feel
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, child) {
        final floatVal = _floatAnimation.value * 0.7;
        return Transform.translate(
          offset: Offset(0, isFloatUp ? floatVal : -floatVal),
          child: child,
        );
      },
      child: Opacity(
        opacity: 0.85,
        child: content,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Single Map Node
  // ─────────────────────────────────────────────
  Widget _buildMapNode({
    required int index,
    required String lessonId,
    required String category,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
  }) {
    // Locked nodes are significantly smaller to create a strong sense of hierarchy
    final nodeSize = isCurrent
        ? _kNodeSizeCurrent
        : isCompleted
            ? _kNodeSize
            : 50.0;

    final nodeColor = isCompleted
        ? _kNodeCompleted
        : isCurrent
            ? _kNodeCurrent
            : _kNodeLocked; // Darker locked background

    final glowColor = isCompleted
        ? _kGlowGreen
        : isCurrent
            ? _kGlowPurple
            : Colors.transparent;

    final icon = _getCategoryIcon(category);
    final label = _getCategoryLabel(category);

    Widget nodeCircle = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) {
        final scale = isCurrent ? _pulseAnimation.value : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: nodeColor,
          border: Border.all(
            color: isCurrent
                ? _kGlowPurple
                : isCompleted
                    ? _kGlowGreen.withOpacity(0.7)
                    : const Color(0xFF483B68), // Low saturation locked border
            width: isCurrent ? 3.5 : 2,
          ),
          boxShadow: (isCompleted || isCurrent)
              ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.6),
                    blurRadius: isCurrent ? 28 : 14,
                    spreadRadius: isCurrent ? 5 : 1.5,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 28)
              : isLocked
                  ? Opacity(
                      opacity: 0.7,
                      child: Icon(Icons.lock, color: const Color(0xFFB0A0C8), size: 20),
                    )
                  : Text(
                      icon,
                      style: const TextStyle(fontSize: 26),
                    ),
        ),
      ),
    );

    // Apply lower opacity to locked nodes to make them fade into the background
    if (isLocked) {
      nodeCircle = Opacity(
        opacity: 0.75,
        child: nodeCircle,
      );
    }

    return GestureDetector(
      onTap: isCurrent
          ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyLessonScreen()),
              )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mascot Demon Avatar (wow factor)
          if (isCurrent)
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _floatAnimation.value * 1.2), // Wider bounce amplitude
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spooky glowing eyes/aura background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1744).withOpacity(0.4),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '😈',
                      style: TextStyle(
                        fontSize: 44, // Larger wow-factor mascot
                        shadows: [
                          Shadow(
                            color: Color(0xFFFF1744),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          nodeCircle,
          const SizedBox(height: 8),
          // Label
          Text(
            '${index + 1}. $label',
            style: TextStyle(
              color: isLocked ? const Color(0xFFB0A0C8).withOpacity(0.7) : _kTextLight,
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              shadows: isCurrent
                  ? const [Shadow(color: _kGlowPurple, blurRadius: 8)]
                  : null,
            ),
          ),
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFFFF6584)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6584).withOpacity(0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'ĐANG HỌC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Path Line between nodes (zigzag connector)
  // ─────────────────────────────────────────────
  Widget _buildPathLine({
    required bool isLeft,
    required bool isCompleted,
    required double screenWidth,
  }) {
    final lineColor = isCompleted ? _kPathDone : _kPathLocked;
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: CustomPaint(
        painter: _ZigzagLinePainter(
          goingLeft: isLeft,
          color: lineColor,
          glowColor: isCompleted ? _kGlowPurple.withOpacity(0.3) : Colors.transparent,
          screenWidth: screenWidth,
          horizontalPad: _kMapHorizontalPad,
          nodeSize: _kNodeSize,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Bottom Floating Bar
  // ─────────────────────────────────────────────
  Widget _buildBottomBar(dynamic path, int currentIdx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kBgGradientBot.withOpacity(0.0),
            _kBgGradientBot.withOpacity(0.95),
            _kBgGradientBot,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: path.isCompleted
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyLessonScreen(),
                          ),
                        ),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFFF2E93)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2E93).withOpacity(0.45),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFF85C0).withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        path.isCompleted ? Icons.celebration : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        path.isCompleted
                            ? '🎉 HOÀN THÀNH TẤT CẢ!'
                            : '⚔️ BẮT ĐẦU NGHI THỨC ${currentIdx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────
  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vocab':
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
        return 'Từ vựng';
      case 'grammar':
        return 'Ngữ pháp';
      case 'speaking':
        return 'Nói';
      case 'listening':
        return 'Nghe';
      default:
        return 'Bài học';
    }
  }

  void _showModifyPathSheet(BuildContext context, path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModifyPathBottomSheet(path: path),
    );
  }
}

// ═══════════════════════════════════════════════
//  Custom Painter: Zigzag path lines
// ═══════════════════════════════════════════════
class _ZigzagLinePainter extends CustomPainter {
  final bool goingLeft;
  final Color color;
  final Color glowColor;
  final double screenWidth;
  final double horizontalPad;
  final double nodeSize;

  _ZigzagLinePainter({
    required this.goingLeft,
    required this.color,
    required this.glowColor,
    required this.screenWidth,
    required this.horizontalPad,
    required this.nodeSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _kPathWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // If glow
    if (glowColor != Colors.transparent) {
      final glowPaint = Paint()
        ..color = glowColor
        ..strokeWidth = _kPathWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      _drawPath(canvas, size, glowPaint);
    }

    _drawPath(canvas, size, paint);
  }

  void _drawPath(Canvas canvas, Size size, Paint paint) {
    final halfNode = nodeSize / 2;

    // Previous node position (opposite side)
    final prevX = goingLeft
        ? screenWidth - horizontalPad - halfNode
        : horizontalPad + halfNode;
    // Current node position
    final currX = goingLeft
        ? horizontalPad + halfNode
        : screenWidth - horizontalPad - halfNode;

    final path = Path();
    path.moveTo(prevX, 0);

    // Smooth S-curve between nodes
    path.cubicTo(
      prevX,
      size.height * 0.4,
      currX,
      size.height * 0.6,
      currX,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ZigzagLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.goingLeft != goingLeft;
  }
}

// ═══════════════════════════════════════════════
//  Modify Path Bottom Sheet (preserved from original)
// ═══════════════════════════════════════════════
class _ModifyPathBottomSheet extends ConsumerStatefulWidget {
  final dynamic path;

  const _ModifyPathBottomSheet({required this.path});

  @override
  ConsumerState<_ModifyPathBottomSheet> createState() =>
      _ModifyPathBottomSheetState();
}

class _ModifyPathBottomSheetState
    extends ConsumerState<_ModifyPathBottomSheet> {
  late ProficiencyLevel _selectedLevel;
  late GoalType _selectedGoal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.path.proficiencyLevel;
    _selectedGoal = widget.path.goalType;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: _kBgGradientBot.withOpacity(0.95),
          padding: EdgeInsets.only(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            top: AppTheme.spacingLg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              const Text(
                'Điều chỉnh lộ trình học',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: _kGlowPurple, blurRadius: 10),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Proficiency Level selection
              const Text(
                'Trình độ của bạn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: 8,
                children: ProficiencyLevel.values.map((level) {
                  final isSelected = _selectedLevel == level;
                  return ChoiceChip(
                    label: Text(level.displayName),
                    selected: isSelected,
                    selectedColor: _kGlowPurple.withOpacity(0.2),
                    backgroundColor: Colors.black.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected ? _kGlowPurple : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? _kGlowPurple : Colors.white.withOpacity(0.1),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedLevel = level;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Goal Type selection
              const Text(
                'Mục tiêu học tập',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Column(
                children: GoalType.values.map((goal) {
                  final isSelected = _selectedGoal == goal;
                  return Card(
                    elevation: 0,
                    color: isSelected
                        ? _kGlowPurple.withOpacity(0.15)
                        : _kCardDark.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? _kGlowPurple
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: ListTile(
                      leading:
                          Text(goal.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        goal.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? _kGlowPurple
                              : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        goal.description,
                        style: const TextStyle(fontSize: 12, color: _kTextMuted),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: _kGlowPurple)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedGoal = goal;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Confirm button
              CustomButton(
                text: 'Cập nhật lộ trình',
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });

                  final success = await ref
                      .read(learningPathProvider.notifier)
                      .regeneratePath(
                        newProficiencyLevel: _selectedLevel,
                        newGoalType: _selectedGoal,
                      );

                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Lộ trình học đã được cập nhật thành công!'),
                          backgroundColor: AppTheme.demonGlowGreen,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Không thể cập nhật lộ trình. Vui lòng thử lại.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Duolingo-style Background Eerie Embers
// ═══════════════════════════════════════════════
// Extracted DemonBackgroundParticles
