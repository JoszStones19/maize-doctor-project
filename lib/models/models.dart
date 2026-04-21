class Alternative {
  final String label;
  final double confidence;

  Alternative({required this.label, required this.confidence});

  factory Alternative.fromJson(Map<String, dynamic> json) => Alternative(
    label:      json['label'] as String,
    confidence: (json['confidence'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'label':      label,
    'confidence': confidence,
  };
}

class PredictionResult {
  final String disease;
  final double confidence;
  final List<Alternative> alternatives;
  final bool isOffline;

  PredictionResult({
    required this.disease,
    required this.confidence,
    required this.alternatives,
    this.isOffline = false,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json, {bool isOffline = false}) =>
      PredictionResult(
        disease:      json['disease'] as String,
        confidence:   (json['confidence'] as num).toDouble(),
        alternatives: (json['alternatives'] as List)
            .map((e) => Alternative.fromJson(e as Map<String, dynamic>))
            .toList(),
        isOffline: isOffline,
      );

  Map<String, dynamic> toJson() => {
    'disease':      disease,
    'confidence':   confidence,
    'alternatives': alternatives.map((a) => a.toJson()).toList(),
    'isOffline':    isOffline,
  };
}

class ScanRecord {
  final String id;
  final String imagePath;
  final PredictionResult result;
  final DateTime timestamp;
  final String userId;

  ScanRecord({
    required this.id,
    required this.imagePath,
    required this.result,
    required this.timestamp,
    required this.userId,
  });

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
    id:        json['id'] as String,
    imagePath: json['imagePath'] as String,
    result:    PredictionResult.fromJson(json['result'] as Map<String, dynamic>),
    timestamp: DateTime.parse(json['timestamp'] as String),
    userId:    json['userId'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id':        id,
    'imagePath': imagePath,
    'result':    result.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'userId':    userId,
  };
}
