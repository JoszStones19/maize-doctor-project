import 'package:flutter/material.dart';
import '../constants/theme.dart';

class ConfidenceBar extends StatefulWidget {
  final double confidence;
  final String label;
  final Color color;
  const ConfidenceBar({required this.confidence, required this.label, this.color = AppColors.primary, super.key});

  @override
  State<ConfidenceBar> createState() => _ConfidenceBarState();
}

class _ConfidenceBarState extends State<ConfidenceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0, end: widget.confidence)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                '${(_anim.value * 100).round()}%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value:           _anim.value,
              minHeight:       8,
              backgroundColor: AppColors.surface,
              color:           widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
