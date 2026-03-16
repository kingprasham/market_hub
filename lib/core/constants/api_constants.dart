/// API Constants for Market Hub App
class ApiConstants {
  // Admin Dashboard Base URL
  static const String adminBaseUrl = 'https://mehrgrewal.com/markethub/api/';
  
  // Original Base URL (for existing features)
  static const String baseUrl = 'https://api.markethubindia.com';
  static const String wsUrl = 'wss://api.markethubindia.com/ws';

  // ==================== ADMIN API ENDPOINTS ====================
  // Auth (Admin Dashboard)
  static const String adminRegister = 'register.php';
  static const String adminVerifyEmail = 'verify-email.php';
  static const String adminSetPin = 'set-pin.php';
  static const String adminLogin = 'login.php';
  static const String adminCheckStatus = 'check-status.php';
  static const String adminProfile = 'profile.php';
  static const String adminPlans = 'plans.php';
  static const String adminHomeUpdates = 'get_home_updates.php';
  static const String adminNews = 'news.php';
  static const String adminHindiNews = 'news-hindi.php';
  static const String adminCirculars = 'circulars.php';
  static const String adminLatestUpdates = 'latest-updates.php';
  static const String adminAds = 'https://mehrgrewal.com/markethub/api/get_ads.php';
  static const String adminSettings = 'settings.php';
  static const String adminFeedback = 'feedback.php';
  static const String adminForgotPin = 'forgot-pin.php';
  static const String adminVerifyResetOtp = 'verify-reset-otp.php';
  static const String adminResetPin = 'reset-pin.php';
  static const String adminUpdateProfile = 'update-profile.php';
  static const String adminHistoricalPrices = 'historical_prices.php';
  
  // Price Alerts
  static const String adminGetPriceAlerts = 'get-price-alerts.php';
  static const String adminAddPriceAlert = 'add-price-alert.php';
  static const String adminDeletePriceAlert = 'delete-price-alert.php';

  // Notifications
  static const String adminNotifications = 'get_notifications.php';

  // ==================== ORIGINAL API ENDPOINTS ====================
  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String updateEmail = '/api/auth/update-email';
  static const String setPin = '/api/auth/set-pin';
  static const String login = '/api/auth/login';
  static const String forgotPin = '/api/auth/forgot-pin';
  static const String resetPin = '/api/auth/reset-pin';
  static const String checkApproval = '/api/auth/check-approval';
  static const String logout = '/api/auth/logout';

  // Plans
  static const String plans = '/api/plans';
  static const String selectPlan = '/api/plans/select';

  // Home Updates
  static const String updates = '/api/updates';

  // Market Data
  static const String marketLme = '/api/market/lme';
  static const String marketShfe = '/api/market/shfe';
  static const String marketComex = '/api/market/comex';
  static const String marketFx = '/api/market/fx';
  static const String referenceRates = '/api/market/reference-rates';
  static const String warehouseStock = '/api/market/warehouse-stock';
  static const String settlement = '/api/market/settlement';

  // Spot Price
  static const String baseMetals = '/api/spot/base-metals';
  static const String bme = '/api/spot/bme';

  // Content
  static const String news = '/api/content/news';
  static const String hindiNews = '/api/content/hindi-news';
  static const String circulars = '/api/content/circulars';
  static const String liveFeed = '/api/content/live-feed';
  static const String economicCalendar = '/api/content/economic-calendar';

  // Watchlist
  static const String watchlist = '/api/watchlist';
  static const String watchlistFuture = '/api/watchlist/future';
  static const String watchlistSpot = '/api/watchlist/spot';
  static const String addWatchlist = '/api/watchlist/add';
  static const String removeWatchlist = '/api/watchlist';

  // Aliases for controller compatibility
  static const String lmeData = marketLme;
  static const String shfeData = marketShfe;
  static const String comexData = marketComex;
  static const String fxRates = marketFx;
  static const String spotBaseMetal = baseMetals;
  static const String spotBme = bme;

  // Profile
  static const String profile = '/api/profile';
  static const String feedback = '/api/profile/feedback';
  static const String changePin = '/api/profile/change-pin';

  // WebSocket Channels
  static const String wsMarket = '/market';
  static const String wsLme = 'lme';
  static const String wsShfe = 'shfe';
  static const String wsComex = 'comex';
  static const String wsFx = 'fx';
  static const String wsSpot = 'spot';

  // Timeouts
  static const int connectionTimeout = 60000;
  static const int receiveTimeout = 60000;
}
