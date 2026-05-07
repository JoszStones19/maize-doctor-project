import 'package:flutter_test/flutter_test.dart';
import 'package:maize_doctor/models/models.dart';
import 'package:maize_doctor/constants/diseases.dart';

void main() {
  // ── TEST 1 — PredictionResult parses from JSON correctly ──
  test('PredictionResult parses from JSON correctly', () {
    final json = {
      'disease': 'northern_leaf_blight',
      'confidence': 0.92,
      'alternatives': [
        {'label': 'gray_leaf_spot', 'confidence': 0.05},
        {'label': 'common_rust',    'confidence': 0.02},
        {'label': 'healthy',        'confidence': 0.01},
      ],
    };
    final result = PredictionResult.fromJson(json);
    expect(result.disease,              'northern_leaf_blight');
    expect(result.confidence,           0.92);
    expect(result.alternatives.length,  3);
  });

  // ── TEST 2 — Alternative parses from JSON correctly ──
  test('Alternative parses from JSON correctly', () {
    final json = {'label': 'gray_leaf_spot', 'confidence': 0.05};
    final alt  = Alternative.fromJson(json);
    expect(alt.label,      'gray_leaf_spot');
    expect(alt.confidence, 0.05);
  });

  // ── TEST 3 — PredictionResult toJson works correctly ──
  test('PredictionResult toJson works correctly', () {
    final result = PredictionResult(
      disease:      'healthy',
      confidence:   0.99,
      alternatives: [],
    );
    final json = result.toJson();
    expect(json['disease'],    'healthy');
    expect(json['confidence'], 0.99);
  });

  // ── TEST 4 — Disease data exists for all 4 classes ──
  test('Disease data exists for all 4 classes', () {
    expect(kDiseases.containsKey('northern_leaf_blight'), true);
    expect(kDiseases.containsKey('gray_leaf_spot'),       true);
    expect(kDiseases.containsKey('common_rust'),          true);
    expect(kDiseases.containsKey('healthy'),              true);
  });

  // ── TEST 5 — Disease has required fields ──
  test('Disease has required fields', () {
    final disease = kDiseases['northern_leaf_blight']!;
    expect(disease.name,        isNotEmpty);
    expect(disease.treatment,   isNotEmpty);
    expect(disease.description, isNotEmpty);
    expect(disease.severity,    isNotEmpty);
  });

  // ── TEST 6 — ScanRecord serializes and deserializes ──
  test('ScanRecord serializes and deserializes correctly', () {
    final result = PredictionResult(
      disease:      'common_rust',
      confidence:   0.85,
      alternatives: [],
    );
    final record = ScanRecord(
      id:        '123',
      imagePath: '/test/path.jpg',
      result:    result,
      timestamp: DateTime(2026, 1, 1),
      userId:    'user_abc',
    );
    final json     = record.toJson();
    final restored = ScanRecord.fromJson(json);
    expect(restored.id,             '123');
    expect(restored.userId,         'user_abc');
    expect(restored.result.disease, 'common_rust');
  });
}
