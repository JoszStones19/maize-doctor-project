import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/diseases.dart';

class InferenceService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/maize_model.tflite',
      );
      _isLoaded = true;
      print('✅ On-device TFLite model loaded');
    } catch (e) {
      print('❌ TFLite load failed: $e');
      rethrow;
    }
  }

  Float32List _preprocessImage(File imageFile) {
    final bytes  = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    image = img.copyResize(image!, width: 224, height: 224);

    final input = Float32List(1 * 224 * 224 * 3);
    int idx = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        input[idx++] = (pixel.r / 255.0 - kMean[0]) / kStd[0];
        input[idx++] = (pixel.g / 255.0 - kMean[1]) / kStd[1];
        input[idx++] = (pixel.b / 255.0 - kMean[2]) / kStd[2];
      }
    }
    return input;
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps   = logits.map((l) => _exp(l - maxVal)).toList();
    final sum    = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  double _exp(double x) {
    if (x < -20) return 0.0;
    if (x > 20)  return 485165195.4;
    double result = 1.0;
    double term   = 1.0;
    for (int i = 1; i <= 10; i++) {
      term   *= x / i;
      result += term;
    }
    return result.abs();
  }

  Future<Map<String, dynamic>> predict(String imagePath) async {
    if (!_isLoaded) await loadModel();

    final imageFile = File(imagePath);
    final input     = _preprocessImage(imageFile);
    final output    = List.filled(kClassLabels.length, 0.0)
        .reshape([1, kClassLabels.length]);

    _interpreter!.run(input.reshape([1, 224, 224, 3]), output);

    final logits = List<double>.from(output[0]);
    final probs  = _softmax(logits);

    final ranked = List.generate(kClassLabels.length, (i) {
      return {'label': kClassLabels[i], 'confidence': probs[i]};
    })..sort((a, b) =>
        (b['confidence'] as double).compareTo(a['confidence'] as double));

    return {
      'disease':      ranked[0]['label'],
      'confidence':   ranked[0]['confidence'],
      'alternatives': ranked.sublist(1),
    };
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}
