import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme.dart';
import '../../constants/diseases.dart';
import '../../models/models.dart';
import '../../widgets/confidence_bar.dart';

class ResultsScreen extends StatefulWidget {
  final PredictionResult result;
  final String imagePath;
  const ResultsScreen({required this.result, required this.imagePath, super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim   = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disease    = kDiseases[widget.result.disease];
    final isHealthy  = widget.result.disease == 'healthy';
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
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Diagnosis Result', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.primaryMuted)),
                  const Spacer(),
                  if (widget.result.isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.heroSubtext.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, color: AppColors.heroSubtext, size: 12),
                          SizedBox(width: 4),
                          Text('Offline', style: TextStyle(color: AppColors.heroSubtext, fontSize: 11)),
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
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // Leaf image thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(widget.imagePath),
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Disease card ──
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isHealthy ? AppColors.successSurface : AppColors.dangerSurface,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: isHealthy ? AppColors.successBorder : AppColors.dangerBorder,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  isHealthy ? 'Healthy leaf' : 'Disease detected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isHealthy ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Text(
                                disease?.name ?? widget.result.disease,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${disease?.scientificName} · ${disease?.type}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),

                              // Confidence bar
                              ConfidenceBar(
                                label:      'Confidence score',
                                confidence: confidence,
                                color:      isHealthy ? AppColors.success : AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Alternatives ──
                        if (widget.result.alternatives.isNotEmpty)
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

                        // ── Description ──
                        if (disease != null)
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel('About this disease'),
                                Text(disease.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.7)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // ── Treatment ──
                        if (disease != null && !isHealthy)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.warningBorder, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Recommended treatment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning)),
                                const SizedBox(height: 6),
                                Text(disease.treatment, style: const TextStyle(fontSize: 13, color: AppColors.danger, height: 1.6)),
                                const Divider(height: 20),
                                const Text('Prevention', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning)),
                                const SizedBox(height: 6),
                                Text(disease.prevention, style: const TextStyle(fontSize: 13, color: AppColors.danger, height: 1.6)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // ── More info button ──
                        if (disease != null && !isHealthy)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/disease-info', extra: disease.name),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('More info about this disease'),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // ── Actions ──
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
                        const SizedBox(height: 8),
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
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
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.8),
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
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: AppColors.surface,
            color: AppColors.primaryLight,
            minHeight: 5,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '${(confidence * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}
