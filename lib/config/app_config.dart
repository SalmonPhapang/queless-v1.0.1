import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment {
  dev,
  stage,
  prod,
}

class AppConfig {
  static final String _env = dotenv.env['APP_ENV'] ?? 'dev';

  static final bool enableNotifications =
      dotenv.env['ENABLE_NOTIFICATIONS'] == 'true';

  static const bool kShowDebugMessages =
      bool.fromEnvironment('SHOW_DEBUG_MESSAGES', defaultValue: true);

  static final AppEnvironment environment = _parseEnvironment(_env);

  static AppEnvironment _parseEnvironment(String value) {
    switch (value.toLowerCase()) {
      case 'stage':
      case 'staging':
        return AppEnvironment.stage;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }
}

abstract class BaseOzowConfig {
  String get siteCode;
  String get privateKey;
  String get apiKey;
  String get notifyUrl;
  String get successUrl;
  String get errorUrl;
  String get cancelUrl;
  bool get isTest;
}

class DevOzowConfig implements BaseOzowConfig {
  @override
  String get siteCode => dotenv.env['OZOW_SITE_CODE'] ?? '';

  @override
  String get privateKey => dotenv.env['OZOW_PRIVATE_KEY'] ?? '';

  @override
  String get apiKey => dotenv.env['OZOW_API_KEY'] ?? '';

  @override
  String get notifyUrl => 'https://your-dev-backend.com/ozow-notify';

  @override
  String get successUrl => notifyUrl;

  @override
  String get errorUrl => notifyUrl;

  @override
  String get cancelUrl => notifyUrl;

  @override
  bool get isTest => true;
}

class StageOzowConfig implements BaseOzowConfig {
  @override
  String get siteCode => dotenv.env['OZOW_SITE_CODE'] ?? '';

  @override
  String get privateKey => dotenv.env['OZOW_PRIVATE_KEY'] ?? '';

  @override
  String get apiKey => dotenv.env['OZOW_API_KEY'] ?? '';

  @override
  String get notifyUrl => 'https://your-stage-backend.com/ozow-notify';

  @override
  String get successUrl => notifyUrl;

  @override
  String get errorUrl => notifyUrl;

  @override
  String get cancelUrl => notifyUrl;

  @override
  bool get isTest => true;
}

class ProdOzowConfig implements BaseOzowConfig {
  @override
  String get siteCode => dotenv.env['OZOW_SITE_CODE'] ?? '';

  @override
  String get privateKey => dotenv.env['OZOW_PRIVATE_KEY'] ?? '';

  @override
  String get apiKey => dotenv.env['OZOW_API_KEY'] ?? '';

  @override
  String get notifyUrl => 'https://your-backend.com/ozow-notify';

  @override
  String get successUrl => notifyUrl;

  @override
  String get errorUrl => notifyUrl;

  @override
  String get cancelUrl => notifyUrl;

  @override
  bool get isTest => false;
}

class OzowConfig {
  static final BaseOzowConfig _dev = DevOzowConfig();
  static final BaseOzowConfig _stage = StageOzowConfig();
  static final BaseOzowConfig _prod = ProdOzowConfig();

  static BaseOzowConfig get _current {
    switch (AppConfig.environment) {
      case AppEnvironment.dev:
        return _dev;
      case AppEnvironment.stage:
        return _stage;
      case AppEnvironment.prod:
        return _prod;
    }
  }

  static String get siteCode => _current.siteCode;
  static String get privateKey => _current.privateKey;
  static String get apiKey => _current.apiKey;
  static String get notifyUrl => _current.notifyUrl;
  static String get successUrl => _current.successUrl;
  static String get errorUrl => _current.errorUrl;
  static String get cancelUrl => _current.cancelUrl;
  static bool get isTest => _current.isTest;
}

abstract class BasePaystackConfig {
  String get publicKey;
  String get secretKey;
  String get currency;
  String get callbackUrl;
  String get backendVerifyUrl;
}

class DevPaystackConfig implements BasePaystackConfig {
  @override
  String get publicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';

  @override
  String get secretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';

  @override
  String get currency => 'ZAR';

  @override
  String get callbackUrl => 'https://your-dev-backend.com/paystack-callback';

  @override
  String get backendVerifyUrl => 'https://your-dev-backend.com/paystack-verify';
}

class StagePaystackConfig implements BasePaystackConfig {
  @override
  String get publicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';

  @override
  String get secretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';

  @override
  String get currency => 'ZAR';

  @override
  String get callbackUrl => 'https://your-stage-backend.com/paystack-callback';

  @override
  String get backendVerifyUrl =>
      'https://your-stage-backend.com/paystack-verify';
}

class ProdPaystackConfig implements BasePaystackConfig {
  @override
  String get publicKey => dotenv.env['PAYSTACK_PROD_PUBLIC_KEY'] ?? '';

  @override
  String get secretKey => dotenv.env['PAYSTACK_PROD_SECRET_KEY'] ?? '';

  @override
  String get currency => 'ZAR';

  @override
  String get callbackUrl => 'https://your-backend.com/paystack-callback';

  @override
  String get backendVerifyUrl => 'https://your-backend.com/paystack-verify';
}

class PaystackConfig {
  static final BasePaystackConfig _dev = DevPaystackConfig();
  static final BasePaystackConfig _stage = StagePaystackConfig();
  static final BasePaystackConfig _prod = ProdPaystackConfig();

  static BasePaystackConfig get _current {
    switch (AppConfig.environment) {
      case AppEnvironment.dev:
        return _dev;
      case AppEnvironment.stage:
        return _stage;
      case AppEnvironment.prod:
        return _prod;
    }
  }

  static String get publicKey => _current.publicKey;
  static String get secretKey => _current.secretKey;
  static String get currency => _current.currency;
  static String get callbackUrl => _current.callbackUrl;
  static String get backendVerifyUrl => _current.backendVerifyUrl;
}
