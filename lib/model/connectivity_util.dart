import 'package:connectivity_plus/connectivity_plus.dart';
  
Future<bool> checkInternertConnection() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult[0] != ConnectivityResult.none;
}