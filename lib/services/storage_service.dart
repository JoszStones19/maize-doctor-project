import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _key = 'maize_scan_history';

  Future<List<ScanRecord>> getHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('${_key}_$userId');
    if (raw == null) return [];
    final list  = jsonDecode(raw) as List;
    return list.map((e) => ScanRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScanRecord> saveScan({
    required String imagePath,
    required PredictionResult result,
    required String userId,
  }) async {
    final record = ScanRecord(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      result:    result,
      timestamp: DateTime.now(),
      userId:    userId,
    );

    final history = await getHistory(userId);
    history.insert(0, record);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_key}_$userId',
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );

    return record;
  }

  Future<void> deleteScan(String id, String userId) async {
    final history = await getHistory(userId);
    history.removeWhere((s) => s.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_key}_$userId',
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_key}_$userId');
  }
}
