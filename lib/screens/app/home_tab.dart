import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:       source,
      imageQuality: 85,
      maxWidth:     1024,
      maxHeight:    1024,
    );

    if (file != null && context.mounted) {
      context.push('/preview', extra: file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maize Doctor',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Snap a leaf · Get instant diagnosis',
                    style: TextStyle(fontSize: 13, color: AppColors.heroSubtext),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upload zone
                      GestureDetector(
                        onTap: () => _pickImage(context, ImageSource.gallery),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primaryLight, width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryMuted, size: 26),
                              ),
                              const SizedBox(height: 12),
                              const Text('Upload leaf photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Text('Tap to choose from gallery', style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.7))),
                              const SizedBox(height: 4),
                              const Text('JPG or PNG · up to 10 MB', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Camera button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(context, ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take photo with camera', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tips
                      const Text(
                        'TIPS FOR BEST RESULTS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      const _TipCard(color: AppColors.primaryLight, text: 'Capture the full leaf in bright, natural light'),
                      const _TipCard(color: Color(0xFFff8f00), text: 'Focus on the affected area — avoid blurry shots'),
                      const _TipCard(color: Color(0xFF1565c0), text: 'Use a plain background for cleaner predictions'),
                      const SizedBox(height: 16),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.infoSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withOpacity(0.3), width: 0.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.info, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Results are AI-assisted. Always consult an agronomist for confirmed diagnosis.',
                                style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.5),
                              ),
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
}

class _TipCard extends StatelessWidget {
  final Color color;
  final String text;
  const _TipCard({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5))),
        ],
      ),
    );
  }
}
