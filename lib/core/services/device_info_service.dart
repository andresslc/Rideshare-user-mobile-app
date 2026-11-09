import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import '../utils/app_log.dart';

class DeviceInfoService {
  // Private constructor
  DeviceInfoService._privateConstructor();

  // Static instance
  static final DeviceInfoService _instance =
      DeviceInfoService._privateConstructor();

  // Factory constructor to return the same instance
  factory DeviceInfoService() {
    return _instance;
  }

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? deviceName;
  String? deviceID;

  Future<void> init() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        log(name: "DeviceInfoService", androidInfo.toString());
        deviceName = androidInfo.model;
        deviceID = androidInfo.id;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        deviceID = iosInfo.identifierForVendor ?? 'Unknown';
      }
    } catch (e) {
      deviceName = "Unknown Device";
      deviceID = "Unknown ID";
    }
  }

  String get safeDeviceName => deviceName ?? "Unknown Device";

  String get safeDeviceID => deviceID ?? "Unknown ID";
}
