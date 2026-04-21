import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../constants/diseases.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _storage    = StorageService();
  List<ScanRecord> _scans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final scans = await _storage.getHistory(user.uid);
    if (mounted) setState(() => _scans = scans);
  }

  String get _mostCommon {
    if (_scans.isEmpty) return '—';
    final freq = <String, int>{};
    for (final s in _scans) {
      freq[s.result.disease] = (freq[s.result.disease] ?? 0) + 1;
    }
    final top = freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return kDiseases[top]?.name ?? top;
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().signOut();
      context.go('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user     = context.watch<AuthProvider>().user;
    final diseased = _scans.where((s) => s.result.disease != 'healthy').length;
    final healthy  = _scans.where((s) => s.result.disease == 'healthy').length;

    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            // Hero with user info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? Text(
                            (user?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 26, color: AppColors.primaryMuted, fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Farmer',
                    style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.primaryMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.heroSubtext)),
                ],
              ),
            ),

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
                      // Stats
                      const _SectionLabel('Your scan stats'),
                      Row(
                        children: [
                          _StatCard(label: 'Total scans',    value: '${_scans.length}'),
                          const SizedBox(width: 8),
                          _StatCard(label: 'Diseases found', value: '$diseased'),
                          const SizedBox(width: 8),
                          _StatCard(label: 'Healthy',        value: '$healthy'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Expanded(child: Text('Most scanned disease', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                            Text(_mostCommon, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Settings
                      const _SectionLabel('Settings'),
                      const _SettingsCard(children: [
                        _SettingRow(icon: Icons.dns_outlined,           label: 'Backend server URL'),
                        _SettingRow(icon: Icons.notifications_outlined, label: 'Scan notifications'),
                        _SettingRow(icon: Icons.share_outlined,         label: 'Export scan history'),
                      ]),
                      const SizedBox(height: 16),

                      // Danger
                      const _SectionLabel('Account'),
                      _SettingsCard(children: [
                        _SettingRow(
                          icon:        Icons.logout,
                          label:       'Sign out',
                          destructive: true,
                          onTap:       _signOut,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Footer
                      const Center(
                        child: Text(
                          'Maize Doctor v1.0.0\nFlutter · Firebase · PyTorch · MobileNetV2',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.8),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.8)),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.playfairDisplay(fontSize: 26, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(
      children: children.map((child) {
        final idx = children.indexOf(child);
        return Column(
          children: [
            child,
            if (idx < children.length - 1)
              Divider(height: 0, indent: 52, color: AppColors.border.withOpacity(0.5)),
          ],
        );
      }).toList(),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;
  const _SettingRow({required this.icon, required this.label, this.destructive = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: destructive ? AppColors.dangerSurface : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: destructive ? AppColors.danger : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: destructive ? AppColors.danger : AppColors.textPrimary))),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}
