import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme.dart';
import '../../constants/diseases.dart';

class GuideTab extends StatelessWidget {
  const GuideTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Disease Guide', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.primaryMuted)),
                  const SizedBox(height: 4),
                  const Text('Tap a disease to learn more', style: TextStyle(fontSize: 13, color: AppColors.heroSubtext)),
                ],
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                  children: [
                    const _SectionLabel('Maize leaf diseases'),
                    ...kDiseases.values.map((d) => _DiseaseCard(disease: d)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.successBorder, width: 0.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Predictions are AI-assisted. Always consult a qualified agronomist for confirmed diagnosis and treatment.',
                              style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _DiseaseCard extends StatefulWidget {
  final DiseaseInfo disease;
  const _DiseaseCard({required this.disease});

  @override
  State<_DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<_DiseaseCard> {
  bool _expanded = false;

  Color get _sevColor {
    switch (widget.disease.severity.toLowerCase()) {
      case 'high':   return AppColors.danger;
      case 'medium': return AppColors.warning;
      default:       return AppColors.success;
    }
  }

  Color get _sevBg {
    switch (widget.disease.severity.toLowerCase()) {
      case 'high':   return AppColors.dangerSurface;
      case 'medium': return AppColors.warningSurface;
      default:       return AppColors.successSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.disease.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(widget.disease.scientificName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sevBg,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _sevColor.withOpacity(0.4), width: 0.5),
                  ),
                  child: Text(widget.disease.severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _sevColor)),
                ),
              ],
            ),

            if (_expanded) ...[
              const Divider(height: 20),
              _Field(label: 'Description', text: widget.disease.description),
              const SizedBox(height: 10),
              _Field(label: 'Treatment',   text: widget.disease.treatment),
              const SizedBox(height: 10),
              _Field(label: 'Prevention',  text: widget.disease.prevention),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(99)),
                child: Text(widget.disease.type, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              _expanded ? 'Tap to collapse ↑' : 'Tap to expand ↓',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, text;
  const _Field({required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
    ],
  );
}
