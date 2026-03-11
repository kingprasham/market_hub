import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'core/constants/color_constants.dart';
import 'core/network/websocket_service.dart';
import 'core/storage/local_storage.dart';
import 'core/security/session_manager.dart';
import 'core/services/external_data_service.dart';
import 'core/services/google_sheets_service.dart';
import 'core/services/watchlist_service.dart';
// import 'core/services/external_apis/metals_dev_service.dart';
import 'core/services/external_apis/api_ninjas_service.dart';
import 'core/services/external_apis/fx_rates_service.dart';
import 'core/services/news_api_service.dart';
import 'core/services/rss_news_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/admin_api_service.dart';
import 'core/services/lockdown_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: ColorConstants.backgroundColor,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize local storage
  await LocalStorage.init();

  // Initialize WatchlistService for starred/favorite items with persistence
  await Get.putAsync(() => WatchlistService().init(), permanent: true);

  // Initialize core services 
  Get.put(WebSocketService(), permanent: true);

  // Initialize session manager for single device login
  await Get.putAsync(() => SessionManager().init(), permanent: true);

  // Initialize external data services for real-time data fetching
  Get.put(ExternalDataService(), permanent: true);

  // Initialize Google Sheets service for Excel data
  Get.put(GoogleSheetsService(), permanent: true);

  // Initialize real-time commodity price API services
  // MetalsDevService removed as per request (Paid API)
  await Get.putAsync(() => ApiNinjasService().init(), permanent: true);
  await Get.putAsync(() => FxRatesService().init(), permanent: true);
  
  // Initialize news API service for real-time news feeds
  Get.put(NewsApiService(), permanent: true);
  
  // Initialize RSS news service for unlimited news from Livemint, MoneyControl, etc.
  Get.put(RssNewsService(), permanent: true);

  // Initialize Firebase for push notifications
  try {
    await Firebase.initializeApp();
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Initialize Firebase Messaging service
    await Get.putAsync(() => FirebaseMessagingService().init(), permanent: true);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Admin API Service for backend communication
  await Get.putAsync(() => AdminApiService().init(), permanent: true);

  // Initialize Lockdown Service (Global App Control)
  Get.put(LockdownService(), permanent: true);

  runApp(const MarketHubApp());
}
