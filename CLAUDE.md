# Market Hub - Project Guide

## Project Overview
Real-time commodity market tracking app (Indian metals market). Flutter mobile app + PHP admin backend on GoDaddy shared hosting.

## Architecture

### Flutter App (lib/)
- **State Management**: GetX (controllers, reactive state, dependency injection)
- **Navigation**: GetX named routes, 5-tab bottom navigation (Home, Futures, Spot, Alerts, Profile)
- **Local Storage**: Hive (cache), FlutterSecureStorage (auth tokens, PIN)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Real-time Data**: WebSocket + Google Sheets CSV polling

### PHP Backend (admin/)
- **Hosting**: GoDaddy shared hosting at `https://mehrgrewal.com/markethub/`
- **Database**: MySQL (`market_hub` database, IST timezone)
- **Admin Panel**: `admin/pages/` — HTML/PHP dashboard for content management
- **API Endpoints**: `admin/api/` — RESTful JSON APIs for the mobile app
- **FCM**: Uses FCM V1 API with service account JWT authentication

### Data Sources
- **Google Sheets**: Spot prices (Non-Ferrous, Steel, Minor Metals, All India Rates)
- **Google Apps Script**: Monitors sheet edits, triggers webhook to `spot_price_monitor.php`
- **External APIs**: ApiNinjas (commodities), FX rates, RSS news feeds

## Key Files

### Backend (admin/)
- `api/config.php` — Core config: DB connection, FCM push functions, auth
- `api/spot_price_monitor.php` — Polls sheets for price changes, sends FCM notifications
- `api/latest-updates.php` — Combined feed of news, circulars, home updates
- `google_apps_script_webhook.js` — Google Apps Script for sheet edit monitoring
- `config/database.php` — MySQL connection (IST timezone: `SET time_zone = '+05:30'`)

### Flutter App (lib/)
- `core/services/firebase_messaging_service.dart` — FCM initialization and message routing
- `core/services/admin_api_service.dart` — HTTP client for backend APIs
- `core/storage/local_storage.dart` — Hive-based caching
- `data/models/content/news_model.dart` — NewsModel, CircularModel (content parsing)
- `data/models/content/update_model.dart` — UpdateModel (home updates)
- `features/notifications/controller/notifications_controller.dart` — Aggregates 3 sources

## Important Conventions

### Timestamps
- MySQL stores all timestamps in IST (Asia/Kolkata) without timezone markers
- PHP API returns raw IST strings like `2024-03-24 14:30:00`
- Dart parsers must NOT add 'Z' suffix — treat timezone-less strings as local time
- The correct pattern is `DateTime.parse(str)` without `.toLocal()` conversion

### Authentication
- Auth token: `base64(user_id:device_token)` — single device login enforced
- FCM V1 API: JWT with base64url encoding (NOT standard base64)
- Cron secret for monitor endpoints: `mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC`

### Notification Flow
1. Content created in admin panel → `send_content_notification()` → FCM to all users
2. Google Sheet edited → Apps Script webhook → `spot_price_monitor.php` → compare with cache → FCM
3. Flutter receives FCM → stores in LocalStorage → NotificationsController aggregates

### FCM Data Payload Types
`news`, `hindi_news`, `circular`, `home_update`, `price_alert`, `forex_update`, `futures_update`, `settlement_update`, `approval`, `subscription_update`

## Development

### Running the Flutter app
```bash
flutter run
```

### Testing notifications
```
# Test spot price monitor (triggers test notification):
curl "https://mehrgrewal.com/markethub/api/spot_price_monitor.php?key=mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC&test_notify=DELHI&debug=1"

# Debug mode (no test notification):
curl "https://mehrgrewal.com/markethub/api/spot_price_monitor.php?key=mh_cron_X7k9pL2mN4qR8vW3yB6tJ0fH5dA1sC&debug=1"
```

### Deployment
- **Flutter app**: Build APK/AAB via Android Studio
- **PHP backend**: Upload changed files via cPanel File Manager to `markethub/` on GoDaddy
- **Google Apps Script**: Edit in Google Sheets → Extensions → Apps Script

## Known Gotchas
- Google Sheets CSV export has a ~3s sync delay after edits (Apps Script adds `Utilities.sleep(3000)`)
- FCM tokens can be truncated at 255 chars in MySQL — the `users.fcm_token` column must be `TEXT` not `VARCHAR(255)`
- Plan targeting: empty `target_plans` or `["all"]` means all users; specific plan IDs restrict access
- The `ADMIN_PANEL` constant suppresses API headers when PHP files are included from admin pages
