import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaizeDoctor());
}

class MaizeDoctor extends StatelessWidget {
  const MaizeDoctor({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        title:            'Maize Doctor',
        theme:            AppTheme.theme,
        routerConfig:     router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
