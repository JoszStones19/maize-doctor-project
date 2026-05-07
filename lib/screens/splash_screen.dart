import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2700),
    );

    // fade in → hold → fade out
    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween:  Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 36,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 44),
      TweenSequenceItem(
        tween:  Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_ctrl);

    // scale up from 0.88 during fade-in, then hold
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween:  Tween(begin: 0.88, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 36,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 64),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) {
      if (!mounted) return;
      final loggedIn = context.read<AuthProvider>().isLoggedIn;
      context.go(loggedIn ? '/home' : '/landing');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo circle
                  Container(
                    width:  108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size:  58,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 34),

                  // App name
                  Text(
                    'Maize Doctor',
                    style: GoogleFonts.playfairDisplay(
                      fontSize:   42,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.primaryMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    'Snap a leaf · Get instant diagnosis',
                    style: GoogleFonts.dmSans(
                      fontSize:   15,
                      color:      AppColors.heroSubtext,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 86),

                  // Spinner
                  SizedBox(
                    width:  22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.heroSubtext.withValues(alpha: 0.40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
