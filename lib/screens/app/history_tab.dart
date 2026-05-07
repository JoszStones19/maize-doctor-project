import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../constants/theme.dart';
import '../../constants/diseases.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _storage = StorageService();
  List<ScanRecord> _scans = [];
  String _filter = 'all';
  bool _loading  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      // guest or signed out — stop spinner, show empty state
      if (mounted) setState(() => _loading = false);
      return;
    }
    final scans = await _storage.getHistory(auth.user!.uid);
    if (mounted) setState(() { _scans = scans; _loading = false; });
  }

  Future<void> _clear() async {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Delete all scan records? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true),  child: const Text('Clear', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _scans = []);
      await _storage.clearHistory(user.uid);
    }
  }

  List<ScanRecord> get _filtered {
    switch (_filter) {
      case 'diseased': return _scans.where((s) => s.result.disease != 'healthy').toList();
      case 'healthy':  return _scans.where((s) => s.result.disease == 'healthy').toList();
      default:         return _scans;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Scan History', style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primaryMuted)),
                  ),
                  if (_scans.isNotEmpty)
                    TextButton(onPressed: _clear, child: const Text('Clear all', style: TextStyle(color: AppColors.heroSubtext, fontSize: 13))),
                ],
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Filter tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          _FilterTab(label: 'All',      value: 'all',      current: _filter, onTap: (v) => setState(() => _filter = v)),
                          const SizedBox(width: 8),
                          _FilterTab(label: 'Diseased', value: 'diseased', current: _filter, onTap: (v) => setState(() => _filter = v)),
                          const SizedBox(width: 8),
                          _FilterTab(label: 'Healthy',  value: 'healthy',  current: _filter, onTap: (v) => setState(() => _filter = v)),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : _filtered.isEmpty
                              ? _EmptyState(filter: _filter)
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) => _HistoryItem(
                                    scan: _filtered[i],
                                    onTap: () => context.push('/results', extra: {
                                      'result':    _filtered[i].result,
                                      'imagePath': _filtered[i].imagePath,
                                    }),
                                  ),
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

class _FilterTab extends StatelessWidget {
  final String label, value, current;
  final void Function(String) onTap;
  const _FilterTab({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 0.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.primaryMuted : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ScanRecord scan;
  final VoidCallback onTap;
  const _HistoryItem({required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disease   = kDiseases[scan.result.disease];
    final conf      = scan.result.confidence;
    final isHealthy = scan.result.disease == 'healthy';
    final severity  = disease?.severity.toLowerCase() ?? 'high';

    final (bgCol, fgCol, bdCol) = isHealthy
        ? (AppColors.successSurface, AppColors.success, AppColors.successBorder)
        : severity == 'high'
            ? (AppColors.dangerSurface,  AppColors.danger,  AppColors.dangerBorder)
            : (AppColors.warningSurface, AppColors.warning, AppColors.warningBorder);

    final date    = scan.timestamp;
    final dateStr = '${date.day} ${_month(date.month)} ${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: File(scan.imagePath).existsSync()
                  ? Image.file(
                      File(scan.imagePath),
                      width:  66,
                      height: 66,
                      fit:    BoxFit.cover,
                    )
                  : Container(
                      width:  66,
                      height: 66,
                      color:  AppColors.primarySurface,
                      child:  const Icon(Icons.eco, color: AppColors.primaryLight, size: 28),
                    ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disease?.name ?? scan.result.disease,
                    style: const TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Offline / Online badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:        scan.result.isOffline
                              ? AppColors.surface
                              : AppColors.infoSurface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: scan.result.isOffline
                                ? AppColors.border
                                : AppColors.info.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              scan.result.isOffline
                                  ? Icons.wifi_off
                                  : Icons.cloud_done_outlined,
                              size:  10,
                              color: scan.result.isOffline
                                  ? AppColors.textMuted
                                  : AppColors.info,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              scan.result.isOffline ? 'Offline' : 'Online',
                              style: TextStyle(
                                fontSize: 10,
                                color: scan.result.isOffline
                                    ? AppColors.textMuted
                                    : AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Confidence badge
            Column(
              children: [
                Container(
                  width:  52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:  bgCol,
                    shape:  BoxShape.circle,
                    border: Border.all(color: bdCol, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      '${(conf * 100).round()}%',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      fgCol,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHealthy ? 'healthy' : severity,
                  style: TextStyle(fontSize: 10, color: fgCol),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isGuest = context.read<AuthProvider>().isGuest;

    if (isGuest) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to track history',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a free account to save your scans and track disease trends over time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 14),
          const Text('No scans yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            filter == 'all' ? 'Your completed scans will appear here' : 'No $filter scans found',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
