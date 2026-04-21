import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged
        .map((result) => result != ConnectivityResult.none);
  }
}
