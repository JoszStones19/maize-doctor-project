import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

const List<String> _kTips = [
  'Capture the full leaf in bright, natural light',
  'Focus on the affected area — avoid blurry shots',
  'Use a plain background for cleaner predictions',
  'Take photos in the morning when light is even',
  'Ensure the leaf fills at least 70 % of the frame',
  'Healthy-looking leaves can also be scanned as a baseline',
  'Multiple scans of the same leaf improve confidence',
];

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _todayCount = 0;
  final _storage  = StorageService();

  @override
  void initState() {
    super.initState();
    _loadTodayCount();
  }

  Future<void> _loadTodayCount() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final all   = await _storage.getHistory(user.uid);
    final today = DateTime.now();
    final count = all.where((s) {
      final d = s.timestamp;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
    if (mounted) setState(() => _todayCount = count);
  }

  String get _dailyTip {
    final now = DateTime.now();
    final idx  = (now.year * 366 + now.month * 31 + now.day) % _kTips.length;
    return _kTips[idx];
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:       source,
      imageQuality: 85,
      maxWidth:     1024,
      maxHeight:    1024,
    );

    if (file != null && context.mounted) {
      context.push('/preview', extra: file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maize Doctor',
                    style: GoogleFonts.playfairDisplay(
                      fontSize:   34,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.primaryMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Snap a leaf · Get instant diagnosis',
                    style: TextStyle(fontSize: 14, color: AppColors.heroSubtext),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color:        AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Today's scan counter ──
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.08),
                              AppColors.primaryLight.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.35),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "TODAY'S SCANS",
                                    style: TextStyle(
                                      fontSize:      10,
                                      fontWeight:    FontWeight.w600,
                                      color:         AppColors.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$_todayCount',
                                        style: GoogleFonts.dmSans(
                                          fontSize:   44,
                                          fontWeight: FontWeight.w800,
                                          color:      AppColors.primary,
                                          height:     1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          _todayCount == 1 ? 'scan today' : 'scans today',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color:    AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width:  58,
                              height: 58,
                              decoration: BoxDecoration(
                                color:        AppColors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.biotech_outlined,
                                color: AppColors.primary,
                                size:  28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Upload zone ──
                      GestureDetector(
                        onTap: () => _pickImage(context, ImageSource.gallery),
                        child: Container(
                          width:   double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 34),
                          decoration: BoxDecoration(
                            color:        AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.primaryLight,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width:  58,
                                height: 58,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: AppColors.primaryMuted,
                                  size:  28,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Upload leaf photo',
                                style: TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.w600,
                                  color:      AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to choose from gallery',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'JPG or PNG · up to 10 MB',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Camera button ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(context, ImageSource.camera),
                          icon:  const Icon(Icons.camera_alt_outlined, size: 20),
                   
                          label: const Text('Take photo with camera'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Daily tip ──
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.successBorder.withValues(alpha: 0.6),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width:  38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:        AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline,
                                color: AppColors.primary,
                                size:  20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TIP OF THE DAY',
                                    style: TextStyle(
                                      fontSize:      10,
                                      fontWeight:    FontWeight.w600,
                                      color:         AppColors.primary,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _dailyTip,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color:    AppColors.textSecondary,
                                      height:   1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Tips for best results ──
                      const Text(
                        'TIPS FOR BEST RESULTS',
                        style: TextStyle(
                          fontSize:      11,
                          fontWeight:    FontWeight.w500,
                          color:         AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _TipCard(color: AppColors.primaryLight,  text: 'Capture the full leaf in bright, natural light'),
                      const _TipCard(color: Color(0xFFff8f00),        text: 'Focus on the affected area — avoid blurry shots'),
                      const _TipCard(color: Color(0xFF1565c0),        text: 'Use a plain background for cleaner predictions'),
                      const SizedBox(height: 14),

                      // ── Info box ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:        AppColors.infoSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.info, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Results are AI-assisted. Always consult an agronomist for confirmed diagnosis.',
                                style: TextStyle(fontSize: 13, color: AppColors.info, height: 1.5),
                              ),
                            ),
                          ],
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

class _TipCard extends StatelessWidget {
  final Color  color;
  final String text;
  const _TipCard({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:        AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width:  8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color:    AppColors.textSecondary,
                height:   1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
