import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme.dart';
import '../../constants/diseases.dart';
import '../../models/models.dart';
import '../../widgets/circular_confidence.dart';

class ResultsScreen extends StatefulWidget {
  final PredictionResult result;
  final String           imagePath;
  const ResultsScreen({required this.result, required this.imagePath, super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Color based on severity ──
  Color _accentColor(DiseaseInfo? disease, bool isHealthy) {
    if (isHealthy) return AppColors.success;
    switch (disease?.severity.toLowerCase()) {
      case 'high':   return AppColors.danger;
      case 'medium': return AppColors.warning;
      default:       return AppColors.primary;
    }
  }

  // ── Split treatment string into individual steps ──
  List<String> _steps(String text) {
    return text
        .split(RegExp(r'\.\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.endsWith('.') ? s : '$s.')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final disease    = kDiseases[widget.result.disease];
    final isHealthy  = widget.result.disease == 'healthy';
    final accent     = _accentColor(disease, isHealthy);
    final confidence = widget.result.confidence;

    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon:  const Icon(Icons.arrow_back, color: AppColors.primaryMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Diagnosis Result',
                    style: GoogleFonts.dmSans(
                      fontSize:   17,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.primaryMuted,
                    ),
                  ),
                  const Spacer(),
                  // Offline / Online badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:        Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.heroSubtext.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.result.isOffline ? Icons.wifi_off : Icons.cloud_done_outlined,
                          color: AppColors.heroSubtext,
                          size:  12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.result.isOffline ? 'Offline · On-device' : 'Online · Server',
                          style: const TextStyle(
                            color:    AppColors.heroSubtext,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color:        AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: FadeTransition(
                  opacity: _fade,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      children: [

                        // ── Leaf image ──
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(widget.imagePath),
                            height:  200,
                            width:   double.infinity,
                            fit:     BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Main result card ──
                        _Card(
                          child: Column(
                            children: [

                              // Status + severity badges
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _Badge(
                                    label: isHealthy ? 'Healthy leaf' : 'Disease detected',
                                    color: isHealthy ? AppColors.success : AppColors.danger,
                                    bg:    isHealthy ? AppColors.successSurface : AppColors.dangerSurface,
                                  ),
                                  if (disease != null && disease.severity != 'None')
                                    _Badge(
                                      label: '${disease.severity} severity',
                                      color: accent,
                                      bg:    accent.withValues(alpha: 0.10),
                                      icon:  disease.severity == 'High'
                                          ? Icons.warning_amber_rounded
                                          : Icons.info_outline,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Circular confidence
                              CircularConfidence(
                                confidence: confidence,
                                color:      accent,
                              ),
                              const SizedBox(height: 20),

                              // Disease name
                              Text(
                                disease?.name ?? widget.result.disease,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize:   28,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),

                              // Scientific name
                              Text(
                                '${disease?.scientificName} · ${disease?.type}',
                                style: const TextStyle(
                                  fontSize:  13,
                                  color:     AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              if (disease != null) ...[
                                const Divider(height: 28),
                                // Description
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'ABOUT',
                                    style: TextStyle(
                                      fontSize:      10,
                                      fontWeight:    FontWeight.w600,
                                      color:         AppColors.textMuted,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  disease.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color:    AppColors.textSecondary,
                                    height:   1.65,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── "What to do" card ──
                        if (disease != null && !isHealthy) ...[
                          _WhatToDoCard(disease: disease, accentColor: accent, steps: _steps),
                          const SizedBox(height: 12),
                        ],

                        // ── Healthy advice ──
                        if (isHealthy) ...[
                          Container(
                            width:   double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color:        AppColors.successSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.successBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width:  48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:        AppColors.success.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success,
                                    size:  26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your crop looks healthy!',
                                        style: TextStyle(
                                          fontSize:   15,
                                          fontWeight: FontWeight.w600,
                                          color:      AppColors.success,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'No disease detected. Continue good agronomic practices and scout regularly.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:    AppColors.success,
                                          height:   1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Alternatives ──
                        if (widget.result.alternatives.isNotEmpty) ...[
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel('Other possibilities'),
                                ...widget.result.alternatives.map((alt) {
                                  final d = kDiseases[alt.label];
                                  return _AltRow(
                                    label:      d?.name ?? alt.label,
                                    confidence: alt.confidence,
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Action buttons ──
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go('/home'),
                                child: const Text('New scan'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => context.go('/history'),
                                child: const Text('View history'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── What To Do card ──
class _WhatToDoCard extends StatelessWidget {
  final DiseaseInfo disease;
  final Color accentColor;
  final List<String> Function(String) steps;

  const _WhatToDoCard({
    required this.disease,
    required this.accentColor,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final treatSteps = steps(disease.treatment);
    final prevSteps  = steps(disease.prevention);

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color:        accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.medical_services_outlined, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'WHAT TO DO',
                style: TextStyle(
                  fontSize:      12,
                  fontWeight:    FontWeight.w700,
                  color:         accentColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Treatment steps
          const Text(
            'TREATMENT',
            style: TextStyle(
              fontSize:      10,
              fontWeight:    FontWeight.w600,
              color:         AppColors.textMuted,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          ...treatSteps.asMap().entries.map(
            (e) => _StepCard(index: e.key, text: e.value, color: accentColor),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Prevention steps
          const Text(
            'PREVENTION',
            style: TextStyle(
              fontSize:      10,
              fontWeight:    FontWeight.w600,
              color:         AppColors.textMuted,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          ...prevSteps.asMap().entries.map(
            (e) => _StepCard(index: e.key, text: e.value, color: AppColors.info),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int    index;
  final String text;
  final Color  color;
  const _StepCard({required this.index, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  26,
            height: 26,
            decoration: BoxDecoration(
              color:  color.withValues(alpha: 0.14),
              shape:  BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color:      color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color:    AppColors.textPrimary,
                height:   1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──

class _Badge extends StatelessWidget {
  final String  label;
  final Color   color;
  final Color   bg;
  final IconData? icon;
  const _Badge({required this.label, required this.color, required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color:        AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize:      10,
        fontWeight:    FontWeight.w600,
        color:         AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _AltRow extends StatelessWidget {
  final String label;
  final double confidence;
  const _AltRow({required this.label, required this.confidence});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 84,
          child: LinearProgressIndicator(
            value:           confidence,
            backgroundColor: AppColors.surface,
            color:           AppColors.primaryLight,
            minHeight:       6,
            borderRadius:    BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(confidence * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}
