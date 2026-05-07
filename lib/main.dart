import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final authProvider = AuthProvider();
  runApp(MaizeDoctor(authProvider: authProvider));
}

class MaizeDoctor extends StatefulWidget {
  final AuthProvider authProvider;
  const MaizeDoctor({required this.authProvider, super.key});

  @override
  State<MaizeDoctor> createState() => _MaizeDoctorState();
}

class _MaizeDoctorState extends State<MaizeDoctor> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: widget.authProvider),
      ],
      child: MaterialApp.router(
        title:            'Maize Doctor',
        theme:            AppTheme.theme,
        routerConfig:     _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
