import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'connectivity_service.dart';
import 'inference_service.dart';
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
  // ── CHANGE THIS TO YOUR KAGGLE/NGROK URL ──
  static const String baseUrl = 'https://calmly-floricultural-reynaldo.ngrok-free.dev';
  static const bool mockMode  = false;
  static const double confidenceThreshold = 0.45;

  final InferenceService _inferenceService = InferenceService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
  ));

  // ── Main predict — auto switches online/offline ──
  Future<PredictionResult> predict(String imagePath) async {
    if (mockMode) return _mockResult();

    final online = await ConnectivityService.isOnline();

    if (online) {
      try {
        print('🌐 Online — using Kaggle API');
        return await _predictOnline(imagePath);
      } catch (e) {
        if (e is NotALeafException || e is LowConfidenceException) rethrow;
        print('⚠️ API failed, falling back to on-device: $e');
        return await _predictOnDevice(imagePath);
      }
    } else {
      print('📴 Offline — using on-device TFLite model');
      return await _predictOnDevice(imagePath);
    }
  }

  // ── Online prediction ──
  Future<PredictionResult> _predictOnline(String imagePath) async {
    final bytes  = await File(imagePath).readAsBytes();
    final base64 = base64Encode(bytes);

    final response = await _dio.post(
      '$baseUrl/predict',
      data: {'image': base64},
      options: Options(validateStatus: (s) => s! < 500),
    );

    if (response.statusCode == 422) {
      final error = response.data['error'];
      if (error == 'not_a_leaf') throw NotALeafException(response.data['message']);
    }

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }

    final result = PredictionResult.fromJson(
      Map<String, dynamic>.from(response.data),
    );

    if (result.confidence < confidenceThreshold) {
      throw LowConfidenceException();
    }

    return result;
  }

  // ── Offline on-device prediction ──
  Future<PredictionResult> _predictOnDevice(String imagePath) async {
    final raw = await _inferenceService.predict(imagePath);

    if ((raw['confidence'] as double) < confidenceThreshold) {
      throw LowConfidenceException();
    }

    return PredictionResult.fromJson(raw, isOffline: true);
  }

  // ── Mock result for testing ──
  PredictionResult _mockResult() {
    Future.delayed(const Duration(seconds: 2));
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

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('$baseUrl/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _inferenceService.dispose();
}
