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
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final scans = await _storage.getHistory(user.uid);
    if (mounted) setState(() { _scans = scans; _loading = false; });
  }

  Future<void> _clear() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Delete all scan records? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Clear', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await _storage.clearHistory(user.uid);
      _load();
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
                    child: Text('Scan History', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.primaryMuted)),
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
    final disease    = kDiseases[scan.result.disease];
    final conf       = scan.result.confidence;
    final isHealthy  = scan.result.disease == 'healthy';
    final badgeColor = isHealthy
        ? (AppColors.successSurface, AppColors.success, AppColors.successBorder)
        : conf >= 0.85
            ? (AppColors.dangerSurface,  AppColors.danger,  AppColors.dangerBorder)
            : (AppColors.warningSurface, AppColors.warning, AppColors.warningBorder);

    final date = scan.timestamp;
    final dateStr = '${date.day} ${_month(date.month)} · ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: File(scan.imagePath).existsSync()
                  ? Image.file(File(scan.imagePath), width: 48, height: 48, fit: BoxFit.cover)
                  : Container(width: 48, height: 48, color: AppColors.primarySurface, child: const Icon(Icons.eco, color: AppColors.primaryLight)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(disease?.name ?? scan.result.disease, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.$1,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: badgeColor.$3, width: 0.5),
              ),
              child: Text('${(conf * 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: badgeColor.$2)),
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history, size: 48, color: AppColors.textMuted.withOpacity(0.4)),
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
