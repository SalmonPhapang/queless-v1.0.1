import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:huawei_hmsavailability/huawei_hmsavailability.dart';
import 'package:queless/logger.dart';

enum MobileEnvironment { gms, hms, other }

class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  MobileEnvironment _environment = MobileEnvironment.other;
  MobileEnvironment get environment => _environment;

  bool get isHMS => _environment == MobileEnvironment.hms;
  bool get isGMS => _environment == MobileEnvironment.gms;

  Future<void> init() async {
    if (kIsWeb) {
      _environment = MobileEnvironment.other;
      return;
    }

    if (Platform.isAndroid) {
      try {
        final HmsApiAvailability hmsApi = HmsApiAvailability();

        // 0: Success, 1: No Huawei Mobile Services
        int hmsCode = await hmsApi.isHMSAvailable();

        // If HMS is available and we want to detect if it's an HMS-only device,
        // we can check if GMS is NOT available.
        // Based on the plugin, we might need a different way to check GMS
        // if isGMSAvailable is not there, or assume HMS if hmsCode is 0.

        if (hmsCode == 0) {
          _environment = MobileEnvironment.hms;
          Logger.debug('Platform Environment: HMS detected');
        } else {
          _environment = MobileEnvironment.gms; // Default to GMS for now
          Logger.debug('Platform Environment: GMS or Other detected');
        }
      } catch (e) {
        Logger.debug('Error detecting platform environment: $e');
        _environment = MobileEnvironment.other;
      }
    } else if (Platform.isIOS) {
      _environment = MobileEnvironment.other;
      Logger.debug('Platform Environment: iOS detected');
    }
  }
}
