/// API Keys Configuration
/// 
/// IMPORTANT: Replace these placeholder keys with your own API keys.
/// Sign up for free at:
/// - Metals.Dev: https://metals.dev
/// - API Ninjas: https://api-ninjas.com
/// - GNews.io: https://gnews.io (100 requests/day free)
/// 
/// For production, consider using environment variables or secure storage.
class ApiKeys {
  // Metals.Dev API Key (for LME, precious metals, spot prices)
  // Free tier: 100 requests/month, 60s update frequency
  static const String metalsDevApiKey = 'YOUR_METALS_DEV_API_KEY';
  
  // API Ninjas API Key (for COMEX commodities)
  // Free tier: 10,000 requests/month
  static const String apiNinjasApiKey = 'YOUR_API_NINJAS_API_KEY';
  
  // GNews.io API Key (for News feeds - English & Hindi)
  // Free tier: 100 requests/day
  // Sign up at: https://gnews.io/register
  static const String gNewsApiKey = 'YOUR_GNEWS_API_KEY'; // TODO: Replace with your key
  
  // ExchangeRate.Host - No API key required for basic usage
  // Free tier: Unlimited requests
  
  /// Check if API keys are configured
  static bool get areKeysConfigured {
    return metalsDevApiKey != 'YOUR_METALS_DEV_API_KEY' &&
           apiNinjasApiKey != 'YOUR_API_NINJAS_API_KEY';
  }
  
  /// Check if Metals.Dev key is configured
  static bool get isMetalsDevConfigured {
    return metalsDevApiKey != 'YOUR_METALS_DEV_API_KEY';
  }
  
  /// Check if API Ninjas key is configured
  static bool get isApiNinjasConfigured {
    return apiNinjasApiKey != 'YOUR_API_NINJAS_API_KEY';
  }
  
  /// Check if GNews key is configured
  static bool get isGNewsConfigured {
    return gNewsApiKey != 'YOUR_GNEWS_API_KEY';
  }
}
