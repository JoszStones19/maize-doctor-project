import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';

class CircularConfidence extends StatefulWidget {
  final double confidence;
  final Color  color;

  const CircularConfidence({
    required this.confidence,
    required this.color,
    super.key,
  });

  @override
  State<CircularConfidence> createState() => _CircularConfidenceState();
}

class _CircularConfidenceState extends State<CircularConfidence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(begin: 0, end: widget.confidence).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final pct = (_anim.value * 100).round();
        return SizedBox(
          width:  156,
          height: 156,
          child: CustomPaint(
            painter: _ArcPainter(progress: _anim.value, color: widget.color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pct%',
                    style: GoogleFonts.dmSans(
                      fontSize:   40,
                      fontWeight: FontWeight.w800,
                      color:      widget.color,
                      height:     1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'confidence',
                    style: TextStyle(
                      fontSize:      11,
                      color:         AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final radius = cx - 10;
    const sw     = 13.0;

    // Background track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color      = color.withValues(alpha: 0.13)
        ..strokeWidth = sw
        ..style      = PaintingStyle.stroke
        ..strokeCap  = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0.005) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color      = color
          ..strokeWidth = sw
          ..style      = PaintingStyle.stroke
          ..strokeCap  = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
