import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // connectivity_plus v6+ returns List<ConnectivityResult>
  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);
  }

  static Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged
        .map((results) => results.isNotEmpty &&
            results.any((r) => r != ConnectivityResult.none));
  }
}
