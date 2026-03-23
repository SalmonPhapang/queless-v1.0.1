import 'package:flutter/foundation.dart';
import 'package:queless/config/app_config.dart';

void log(String message) {
  if (AppConfig.kShowDebugMessages) {
    debugPrint(message);
  }
}
