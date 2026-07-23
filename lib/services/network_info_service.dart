import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reads the current Wi-Fi network name. On Android this requires location
/// permission (an OS restriction on SSID reads, unrelated to this app's own
/// needs). On macOS, reading the SSID requires an Apple entitlement that
/// itself requires a paid Apple Developer account we don't have, so it
/// always falls back to "Indisponible" there.
class NetworkInfoService {
  final _networkInfo = NetworkInfo();

  Future<String?> currentNetworkName() async {
    if (Platform.isMacOS) return null;

    if (Platform.isAndroid) {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) return null;
    }

    try {
      final name = await _networkInfo.getWifiName();
      return name?.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }
}
