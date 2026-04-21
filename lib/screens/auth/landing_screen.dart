import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim  = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
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
    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero section ──
            Expanded(
              flex: 6,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Leaf icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.heroSubtext.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.eco_outlined,
                            color: AppColors.primaryMuted,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'Maize\nDoctor',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryMuted,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'AI-powered maize leaf disease\nclassification for farmers.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.heroSubtext,
                            height: 1.6,
                            fontFamily: 'DMSans',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Feature pills
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FeaturePill(icon: Icons.camera_alt_outlined, label: 'Photo diagnosis'),
                            _FeaturePill(icon: Icons.wifi_off_outlined,   label: 'Works offline'),
                            _FeaturePill(icon: Icons.speed_outlined,      label: 'Instant results'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Action buttons ──
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Get started
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/register'),
                      child: const Text(
                        'Get started — it\'s free',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sign in
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Sign in to my account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Helping farmers protect their crops\nwith the power of AI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.heroSubtext.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.heroSubtext, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.heroSubtext,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
