import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/landing_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/app/main_shell.dart';
import '../screens/app/preview_screen.dart';
import '../screens/app/results_screen.dart';
import '../screens/app/disease_info_screen.dart';
import '../models/models.dart';

final router = GoRouter(
  initialLocation: '/landing',
  redirect: (context, state) {
    final auth     = context.read<AuthProvider>();
    final loggedIn = auth.isLoggedIn;
    final onAuth   = state.matchedLocation.startsWith('/landing') ||
                     state.matchedLocation.startsWith('/login')   ||
                     state.matchedLocation.startsWith('/register') ||
                     state.matchedLocation.startsWith('/forgot');

    if (!loggedIn && !onAuth) return '/landing';
    if (loggedIn  &&  onAuth) return '/home';
    return null;
  },
  routes: [
    // ── Auth routes ──
    GoRoute(path: '/landing',  builder: (_, __) => const LandingScreen()),
    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/forgot',   builder: (_, __) => const ForgotPasswordScreen()),

    // ── App shell with bottom nav ──
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home',    builder: (_, __) => const HomeTab()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryTab()),
        GoRoute(path: '/guide',   builder: (_, __) => const GuideTab()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileTab()),
      ],
    ),

    // ── Full screen routes ──
    GoRoute(
      path: '/preview',
      builder: (context, state) => PreviewScreen(
        imagePath: state.extra as String,
      ),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => ResultsScreen(
        result: (state.extra as Map)['result'] as PredictionResult,
        imagePath: (state.extra as Map)['imagePath'] as String,
      ),
    ),
    GoRoute(
      path: '/disease-info',
      builder: (context, state) => DiseaseInfoScreen(
        diseaseName: state.extra as String,
      ),
    ),
  ],
);
