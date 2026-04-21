import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../services/connectivity_service.dart';

export 'home_tab.dart';
export 'history_tab.dart';
export 'guide_tab.dart';
export 'profile_tab.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({required this.child, super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    ConnectivityService.isOnline().then((v) => setState(() => _isOnline = v));
    ConnectivityService.onConnectivityChanged.listen((v) {
      if (mounted) setState(() => _isOnline = v);
    });
  }

  int _locationToIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/history')) return 1;
    if (loc.startsWith('/guide'))   return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0: context.go('/home');    break;
      case 1: context.go('/history'); break;
      case 2: context.go('/guide');   break;
      case 3: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _locationToIndex(context);

    return Scaffold(
      body: Column(
        children: [
          // ── Connectivity banner ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isOnline ? 0 : 32,
            color: AppColors.warning,
            child: _isOnline ? null : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Offline — using on-device model',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTap,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primarySurface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon:         Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon:         Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppColors.primary),
            label: 'Guide',
          ),
          NavigationDestination(
            icon:         Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
