import 'dart:math';
import 'package:flutter/material.dart';
import 'package:demon_teach/core/theme/app_theme.dart';

class DemonEmber {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  DemonEmber({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class DemonEmbersPainter extends CustomPainter {
  final List<DemonEmber> embers;
  final double animationValue;

  DemonEmbersPainter({required this.embers, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (var i = 0; i < embers.length; i++) {
      final ember = embers[i];
      // Update Y based on speed and animation
      // We use animationValue as a continuous driver but actually state should update embers
      // For simple stateless painting, we can calculate Y based on time
      final progress = (animationValue * ember.speed) % 1.0;
      final currentY = size.height - (size.height * progress) - (ember.y * size.height);
      
      // Wrap around
      final finalY = currentY < 0 ? currentY + size.height : currentY;
      
      // Sway X slightly
      final finalX = ember.x * size.width + sin(progress * pi * 4 + ember.y) * 20;

      paint.color = AppTheme.demonGlowPurple.withOpacity(ember.opacity * (0.5 + 0.5 * sin(progress * pi * 10)));
      canvas.drawCircle(Offset(finalX, finalY), ember.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DemonEmbersPainter oldDelegate) => true;
}

class DemonEmbersBackground extends StatefulWidget {
  const DemonEmbersBackground({super.key});

  @override
  State<DemonEmbersBackground> createState() => _DemonEmbersBackgroundState();
}

class _DemonEmbersBackgroundState extends State<DemonEmbersBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<DemonEmber> _embers = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) {
      _embers.add(
        DemonEmber(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 4 + 1,
          speed: _random.nextDouble() * 0.5 + 0.1,
          opacity: _random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: DemonEmbersPainter(embers: _embers, animationValue: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}
