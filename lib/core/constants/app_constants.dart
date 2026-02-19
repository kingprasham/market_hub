class AppConstants {
  // App Info
  static const String appName = 'Market Hub';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userKey = 'current_user';
  static const String tokenKey = 'auth_token';
  static const String pinKey = 'user_pin';
  static const String deviceTokenKey = 'device_token';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String themeKey = 'app_theme';

  // Validation
  static const int pinLength = 4;
  static const int otpLength = 4;
  static const int phoneLength = 10;
  static const int pincodeLength = 6;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Timeouts
  static const int otpResendTimeout = 30; // seconds
  static const int sessionTimeout = 30; // minutes
  static const int websocketPingInterval = 25; // seconds
  static const int websocketPongTimeout = 10; // seconds

  // Pagination
  static const int defaultPageSize = 20;

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Reconnection
  static const int maxReconnectAttempts = 10;
  static const int initialReconnectDelay = 1; // seconds
  static const int maxReconnectDelay = 32; // seconds

  // Metal Categories
  static const List<String> metalCategories = [
    'Copper',
    'Brass',
    'Gun Metal',
    'Lead',
    'Nickel',
    'Tin',
    'Zinc',
    'Aluminium',
  ];

  // Exchanges
  static const List<String> exchanges = [
    'LME',
    'SHFE',
    'COMEX',
  ];
}
