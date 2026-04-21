import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

enum _ErrorType { notALeaf, lowQuality, serverError, noInternet }

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  const PreviewScreen({required this.imagePath, super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _loading = false;
  final _api     = ApiService();
  final _storage = StorageService();

  Future<void> _analyse() async {
    setState(() => _loading = true);

    try {
      final result = await _api.predict(widget.imagePath);
      final user   = context.read<AuthProvider>().user;

      if (user != null) {
        await _storage.saveScan(
          imagePath: widget.imagePath,
          result:    result,
          userId:    user.uid,
        );
      }

      if (mounted) {
        context.push('/results', extra: {
          'result':    result,
          'imagePath': widget.imagePath,
        });
      }

    } on NotALeafException {
      if (mounted) _showError(_ErrorType.notALeaf);
    } on LowConfidenceException {
      if (mounted) _showError(_ErrorType.lowQuality);
    } on DioException catch (e) {
      if (mounted) {
        if (e.type == DioExceptionType.connectionError) {
          _showError(_ErrorType.noInternet);
        } else {
          _showError(_ErrorType.serverError);
        }
      }
    } catch (_) {
      if (mounted) _showError(_ErrorType.serverError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(_ErrorType type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ErrorSheet(
        type:    type,
        onRetry: () {
          Navigator.pop(context);
          if (type == _ErrorType.noInternet) {
            _analyse();
          } else {
            context.go('/home');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Preview & Analyse', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.primaryMuted)),
                ],
              ),
            ),

            // Image preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(widget.imagePath), fit: BoxFit.cover),
                      Positioned(
                        bottom: 12,
                        left: 0, right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text('Leaf detected', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom actions
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _Chip(label: File(widget.imagePath).path.split('/').last),
                      const SizedBox(width: 8),
                      const _Chip(label: 'Today'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _analyse,
                      icon: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMuted))
                          : const Icon(Icons.biotech_outlined, size: 18),
                      label: Text(_loading ? 'Analysing...' : 'Analyse leaf'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retake / choose different'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
    );
  }
}

class _ErrorSheet extends StatelessWidget {
  final _ErrorType type;
  final VoidCallback onRetry;
  const _ErrorSheet({required this.type, required this.onRetry});

  Map<String, dynamic> get _config {
    switch (type) {
      case _ErrorType.notALeaf:
        return {
          'icon': Icons.grass_outlined, 'bg': AppColors.dangerSurface, 'ic': AppColors.danger,
          'title': 'Not a maize leaf',
          'message': 'The image does not appear to be a maize leaf. Please upload a clear photo of a maize leaf and try again.',
          'btn': 'Try again',
        };
      case _ErrorType.lowQuality:
        return {
          'icon': Icons.photo_camera_outlined, 'bg': AppColors.warningSurface, 'ic': AppColors.warning,
          'title': 'Image not clear enough',
          'message': 'The photo quality is too low for a confident diagnosis. Try again in better lighting with the leaf in focus.',
          'btn': 'Take another photo',
        };
      case _ErrorType.noInternet:
        return {
          'icon': Icons.wifi_off_outlined, 'bg': AppColors.infoSurface, 'ic': AppColors.info,
          'title': 'No internet connection',
          'message': 'The app will switch to offline mode and use the on-device model instead. Results may vary slightly.',
          'btn': 'Continue offline',
        };
      case _ErrorType.serverError:
        return {
          'icon': Icons.error_outline, 'bg': AppColors.dangerSurface, 'ic': AppColors.danger,
          'title': 'Something went wrong',
          'message': 'The server could not process your request. Please check your connection and try again.',
          'btn': 'Try again',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: c['bg'] as Color, shape: BoxShape.circle),
            child: Icon(c['icon'] as IconData, color: c['ic'] as Color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(c['title'] as String, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(c['message'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onRetry, child: Text(c['btn'] as String))),
        ],
      ),
    );
  }
}
