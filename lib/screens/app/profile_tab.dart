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
  String _backendUrl = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final url  = await _storage.getBackendUrl();
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      // guest — still load URL setting, no scan history
      if (mounted) setState(() => _backendUrl = url ?? '');
      return;
    }
    final scans = await _storage.getHistory(user.uid);
    if (mounted) {
      setState(() {
        _scans      = scans;
        _backendUrl = url ?? '';
      });
    }
  }

  Future<void> _editBackendUrl() async {
    final controller = TextEditingController(text: _backendUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backend server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://your-ngrok-url.ngrok-free.app',
            helperText: 'Leave empty to use offline TFLite mode',
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _storage.setBackendUrl(result);
      if (mounted) setState(() => _backendUrl = result.trim());
    }
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign out', style: TextStyle(color: AppColors.danger))),
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
    final auth     = context.watch<AuthProvider>();
    final user     = auth.user;
    final isGuest  = auth.isGuest;
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
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? Text(
                            isGuest ? 'G' : (user?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 26, color: AppColors.primaryMuted, fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isGuest ? 'Guest' : (user?.displayName ?? 'Farmer'),
                    style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primaryMuted),
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
                      // Guest banner
                      if (isGuest) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.infoSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.info.withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person_outline, color: AppColors.info, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You\'re in Guest mode. Sign in to save scan history and sync across devices.',
                                  style: TextStyle(fontSize: 13, color: AppColors.info, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Sign in or create account'),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Stats
                      const _SectionLabel('Your scan stats'),
                      Row(
                        children: [
                          _StatCard(label: 'Total',    value: '${_scans.length}', icon: Icons.biotech_outlined,       iconColor: AppColors.primary),
                          const SizedBox(width: 8),
                          _StatCard(label: 'Diseased', value: '$diseased',        icon: Icons.coronavirus_outlined,   iconColor: AppColors.danger),
                          const SizedBox(width: 8),
                          _StatCard(label: 'Healthy',  value: '$healthy',         icon: Icons.check_circle_outline,   iconColor: AppColors.success),
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
                            const Icon(Icons.bar_chart_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Most scanned disease', style: TextStyle(fontSize: 14, color: AppColors.textSecondary))),
                            Text(_mostCommon, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Settings
                      const _SectionLabel('Settings'),
                      _SettingsCard(children: [
                        _SettingRow(
                          icon:     Icons.dns_outlined,
                          label:    'Backend server URL',
                          subtitle: _backendUrl.isEmpty ? 'Not set — offline TFLite mode' : _backendUrl,
                          onTap:    _editBackendUrl,
                        ),
                        _SettingRow(
                          icon:  Icons.notifications_outlined,
                          label: 'Scan notifications',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coming in a future update'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          ),
                        ),
                        _SettingRow(
                          icon:  Icons.share_outlined,
                          label: 'Export scan history',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coming in a future update'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Account
                      const _SectionLabel('Account'),
                      _SettingsCard(children: [
                        if (isGuest)
                          _SettingRow(
                            icon:  Icons.login,
                            label: 'Sign in',
                            onTap: () => context.go('/login'),
                          )
                        else
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
  final String  label, value;
  final IconData  icon;
  final Color     iconColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize:   28,
              fontWeight: FontWeight.w800,
              color:      AppColors.textPrimary,
              height:     1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
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
              Divider(height: 0, indent: 52, color: AppColors.border.withValues(alpha: 0.5)),
          ],
        );
      }).toList(),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool destructive;
  final VoidCallback? onTap;
  const _SettingRow({required this.icon, required this.label, this.subtitle, this.destructive = false, this.onTap});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: destructive ? AppColors.danger : AppColors.textPrimary)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}
