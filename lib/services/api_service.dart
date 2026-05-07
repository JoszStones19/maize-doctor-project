import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'connectivity_service.dart';
import 'inference_service.dart';
import 'storage_service.dart';
import '../models/models.dart';

// ── Custom exceptions ──
class NotALeafException implements Exception {
  final String message;
  NotALeafException([this.message = 'Image does not appear to be a maize leaf.']);
}

class LowConfidenceException implements Exception {
  final String message;
  LowConfidenceException([this.message = 'Could not confidently identify the leaf. Try a clearer photo.']);
}

class ApiService {
  static const bool   mockMode = false;

  // Offline thresholds:
  // Below notLeafThreshold  → image is not recognisable as a maize leaf at all
  // Below confidenceThreshold → leaf detected but photo is too unclear / low quality
  // Above confidenceThreshold → show result
  static const double notLeafThreshold    = 0.50;
  static const double confidenceThreshold = 0.60;

  final InferenceService _inferenceService = InferenceService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
  ));

  // ── Main predict — uses backend URL from prefs when set, else offline ──
  Future<PredictionResult> predict(String imagePath) async {
    if (mockMode) return _mockResult();

    final savedUrl = await StorageService().getBackendUrl();
    final hasUrl   = savedUrl != null && savedUrl.isNotEmpty;

    if (hasUrl) {
      final online = await ConnectivityService.isOnline();
      if (online) {
        try {
          debugPrint('Online — using backend: $savedUrl');
          return await _predictOnline(imagePath, savedUrl);
        } catch (e) {
          if (e is NotALeafException || e is LowConfidenceException) rethrow;
          debugPrint('API failed, falling back to on-device: $e');
          return await _predictOnDevice(imagePath);
        }
      }
    }

    debugPrint('No URL configured or offline — using on-device TFLite model');
    return await _predictOnDevice(imagePath);
  }

  // ── Online prediction ──
  Future<PredictionResult> _predictOnline(String imagePath, String baseUrl) async {
    final bytes  = await File(imagePath).readAsBytes();
    final base64 = base64Encode(bytes);

    final response = await _dio.post(
      '$baseUrl/predict',
      data: {'image': base64},
      options: Options(validateStatus: (s) => s! < 500),
    );

    if (response.statusCode == 422) {
      final error = response.data['error'];
      if (error == 'not_a_leaf') throw NotALeafException(response.data['message'] as String);
    }

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }

    final result = PredictionResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    if (result.confidence < notLeafThreshold)    throw NotALeafException();
    if (result.confidence < confidenceThreshold) throw LowConfidenceException();

    return result;
  }

  // ── Offline on-device prediction ──
  Future<PredictionResult> _predictOnDevice(String imagePath) async {
    final raw  = await _inferenceService.predict(imagePath);
    final conf = raw['confidence'] as double;

    // Very low confidence → probably not a maize leaf at all
    if (conf < notLeafThreshold) throw NotALeafException();

    // Moderate confidence → photo too blurry / unclear
    if (conf < confidenceThreshold) throw LowConfidenceException();

    return PredictionResult.fromJson(raw, isOffline: true);
  }

  // ── Mock result for testing ──
  PredictionResult _mockResult() {
    return PredictionResult(
      disease:    'northern_leaf_blight',
      confidence: 0.92,
      alternatives: [
        Alternative(label: 'gray_leaf_spot', confidence: 0.05),
        Alternative(label: 'common_rust',    confidence: 0.02),
        Alternative(label: 'healthy',        confidence: 0.01),
      ],
    );
  }

  void dispose() => _inferenceService.dispose();
}
