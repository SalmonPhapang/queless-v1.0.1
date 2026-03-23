import 'package:flutter/foundation.dart' as foundation;
import 'dart:developer' as developer;

class Logger {
  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!foundation.kReleaseMode) {
      developer.log(message, name: 'DEBUG', error: error, stackTrace: stackTrace);
    }
  }

  static void info(String message) {
    developer.log(message, name: 'INFO');
  }

  static void warn(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(message, name: 'WARN', error: error, stackTrace: stackTrace);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(message, name: 'ERROR', error: error, stackTrace: stackTrace);
  }
}
