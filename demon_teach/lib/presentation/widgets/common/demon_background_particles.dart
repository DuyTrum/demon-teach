import 'dart:math';
import 'package:flutter/material.dart';

class DemonBackgroundParticles extends StatefulWidget {
  const DemonBackgroundParticles({super.key});

  @override
  State<DemonBackgroundParticles> createState() => _DemonBackgroundParticlesState();
}

class _DemonBackgroundParticlesState extends State<DemonBackgroundParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_DemonParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate 18 floating demonic embers
    for (int i = 0; i < 18; i++) {
      _particles.add(_DemonParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.02 + _random.nextDouble() * 0.03,
        size: 3.0 + _random.nextDouble() * 6.0,
        opacity: 0.15 + _random.nextDouble() * 0.35,
        color: _random.nextBool()
            ? const Color(0xFF9C7CFF) // Purple ember
            : const Color(0xFFFF5252), // Red ember
      ));
    }
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
      builder: (context, _) {
        // Update ember positions (rising upwards)
        for (var p in _particles) {
          p.y -= p.speed * 0.01;
          // Soft horizontal sway
          p.x += sin(_controller.value * 2 * pi + p.size) * 0.001;
          
          if (p.y < 0) {
            p.y = 1.0;
            p.x = _random.nextDouble();
          }
        }
        return CustomPaint(
          painter: _DemonParticlePainter(particles: _particles),
        );
      },
    );
  }
}

class _DemonParticle {
  double x;
  double y;
  final double speed;
  final double size;
  final double opacity;
  final Color color;

  _DemonParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.color,
  });
}

class _DemonParticlePainter extends CustomPainter {
  final List<_DemonParticle> particles;

  _DemonParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final dx = p.x * size.width;
      final dy = p.y * size.height;

      // Draw glowing ember
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DemonParticlePainter oldDelegate) => true;
}
