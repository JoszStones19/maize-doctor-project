import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/diseases.dart';

const int kInputSize = 224;

class InferenceService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/maize_model.tflite',
      );
      _interpreter!.allocateTensors();
      _isLoaded = true;
      debugPrint('TFLite model loaded. '
          'Input: ${_interpreter!.getInputTensor(0).shape} '
          'Output: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      debugPrint('TFLite load failed: $e');
      rethrow;
    }
  }

  Float32List _preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    image = img.copyResize(image!, width: kInputSize, height: kInputSize);

    final input = Float32List(kInputSize * kInputSize * 3);
    int idx = 0;
    for (int y = 0; y < kInputSize; y++) {
      for (int x = 0; x < kInputSize; x++) {
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
    final exps   = logits.map((l) => math.exp(l - maxVal)).toList();
    final sum    = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  // If all values are in [0,1], model already applied softmax/sigmoid.
  // Real logits typically exceed 1.0 or go negative; probabilities stay in [0,1].
  bool _isAlreadyProbabilities(List<double> v) {
    return v.every((x) => x >= -0.001 && x <= 1.001);
  }

  Future<Map<String, dynamic>> predict(String imagePath) async {
    if (!_isLoaded) await loadModel();

    final input = _preprocessImage(File(imagePath));

    // ── Use low-level tensor API to guarantee the output buffer is read ──
    // The high-level run() can silently leave the buffer as zeros.
    final inputTensor = _interpreter!.getInputTensor(0);
    inputTensor.data.buffer.asFloat32List().setAll(0, input);
    _interpreter!.invoke();

    final outputTensor = _interpreter!.getOutputTensor(0);
    final rawFlat      = outputTensor.data.buffer.asFloat32List();

    // Works for both [4] and [1,4] output shapes
    final n      = kClassLabels.length;
    final rawOut = rawFlat.sublist(rawFlat.length - n)
                          .map((v) => v.toDouble())
                          .toList();

    debugPrint('TFLite raw  [${kClassLabels.join(",")}]: $rawOut');

    final probs = _isAlreadyProbabilities(rawOut)
        ? rawOut
        : _softmax(rawOut);

    debugPrint('TFLite probs[${kClassLabels.join(",")}]: $probs');

    final ranked = List.generate(n, (i) {
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
