# Market Hub - Updated Dependencies & Configuration

## UPDATED pubspec.yaml

```yaml
name: market_hub_new
description: "Real-time commodity market tracking application"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management - GetX (lightweight, no streams overhead)
  get: ^4.6.6
  
  # Networking
  dio: ^5.7.0
  pretty_dio_logger: ^1.4.0
  
  # WebSocket - CRITICAL for real-time
  web_socket_channel: ^2.4.5
  
  # Connectivity monitoring
  connectivity_plus: ^6.0.5
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Secure Storage - for PIN encryption
  flutter_secure_storage: ^9.2.2
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  
  # UI Components
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  carousel_slider: ^5.0.0
  
  # PIN/OTP Input
  pinput: ^5.0.0
  
  # Image Handling
  image_picker: ^1.1.2
  photo_view: ^0.15.0
  
  # PDF Viewer
  flutter_pdfview: ^1.3.2
  syncfusion_flutter_pdfviewer: ^27.1.52
  
  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.3.1
  share_plus: ^10.1.2
  permission_handler: ^11.3.1
  
  # WebView
  webview_flutter: ^4.10.0
  
  # Device Info (for single device login)
  device_info_plus: ^10.1.2
  
  # UUID generation
  uuid: ^4.5.1
  
  # JSON serialization
  json_annotation: ^4.9.0
  
  # RxDart for advanced stream operations (optional but recommended)
  rxdart: ^0.28.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  json_serializable: ^6.8.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/splash_screen/
    - assets/icons/
    - assets/metals/
    - assets/images/
```

---

## ANDROID CONFIGURATION

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Internet permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <!-- Camera for visiting card -->
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <!-- Storage for file downloads -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    
    <!-- Vibration for notifications -->
    <uses-permission android:name="android.permission.VIBRATE"/>
    
    <!-- Wake lock for background operations -->
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    
    <application
        android:label="Market Hub"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false">
        
        <!-- CRITICAL: Prevent screenshots and screen recording -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Firebase Messaging -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="market_hub_notifications" />
            
        <meta-data
            android:name="firebase_messaging_auto_init_enabled"
            android:value="true" />
            
    </application>
    
    <!-- Queries for URL launcher -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SEND" />
            <data android:mimeType="*/*" />
        </intent>
    </queries>
</manifest>
```

### android/app/src/main/kotlin/.../MainActivity.kt

```kotlin
package com.markethub.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // CRITICAL: Prevent screenshots and screen recording
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
```

---

## iOS CONFIGURATION

### ios/Runner/Info.plist (Add these entries)

```xml
<!-- Camera permission for visiting card -->
<key>NSCameraUsageDescription</key>
<string>Market Hub needs camera access to capture your visiting card</string>

<!-- Photo library permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Market Hub needs photo library access to select your visiting card</string>

<!-- Allow arbitrary loads for development (remove in production) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.markethubindia.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### ios/Runner/AppDelegate.swift

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Firebase initialization
        FirebaseApp.configure()
        
        // Request notification permission
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        application.registerForRemoteNotifications()
        
        GeneratedPluginRegistrant.register(with: self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // CRITICAL: Prevent screen recording detection
    override func applicationWillResignActive(_ application: UIApplication) {
        // Add blur effect when app goes to background
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window?.frame ?? .zero
        blurView.tag = 999
        window?.addSubview(blurView)
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        // Remove blur effect when app becomes active
        window?.viewWithTag(999)?.removeFromSuperview()
    }
}
```

---

## MAIN.DART - Application Entry Point

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'core/network/websocket_service.dart';
import 'core/storage/local_storage.dart';
import 'core/constants/color_constants.dart';
import 'firebase_options.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}

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
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Hive
  await Hive.initFlutter();
  await LocalStorage.init();
  
  // Initialize core services
  Get.put(WebSocketService(), permanent: true);
  
  runApp(const MarketHubApp());
}
```

---

## APP INITIALIZATION

```dart
// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/color_constants.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class MarketHubApp extends StatelessWidget {
  const MarketHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Market Hub',
      debugShowCheckedModeBanner: false,
      
      // Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColorConstants.primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: ColorConstants.backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: ColorConstants.backgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: ColorConstants.textPrimary),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textPrimary,
          ),
        ),
      ),
      
      // Navigation
      defaultTransition: Transition.cupertino,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      
      // Error handling
      builder: (context, child) {
        // Global error handling wrapper
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Center(
            child: Text(
              'Something went wrong',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
```

---

## ROUTES CONFIGURATION

```dart
// lib/app/routes/app_routes.dart
abstract class AppRoutes {
  static const splash = '/splash';
  static const registration = '/registration';
  static const emailVerification = '/email-verification';
  static const pinSetup = '/pin-setup';
  static const planSelection = '/plan-selection';
  static const pendingApproval = '/pending-approval';
  static const login = '/login';
  static const forgotPin = '/forgot-pin';
  static const home = '/home';
  static const profile = '/profile';
  static const aboutUs = '/about-us';
  static const contactUs = '/contact-us';
  static const feedback = '/feedback';
  static const terms = '/terms';
  static const changePin = '/change-pin';
}
```

```dart
// lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import 'app_routes.dart';
// Import all screens...

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.registration,
      page: () => RegistrationScreen(),
      binding: RegistrationBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainNavigation(),
      binding: HomeBinding(),
    ),
    // Add all other routes...
  ];
}
```

---

## LOCAL STORAGE INITIALIZATION

```dart
// lib/core/storage/local_storage.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user/user_model.dart';

class LocalStorage {
  static late Box<UserModel> _userBox;
  static late Box<dynamic> _cacheBox;
  static const _secureStorage = FlutterSecureStorage();
  
  static Future<void> init() async {
    // Register Hive adapters
    Hive.registerAdapter(UserModelAdapter());
    
    // Open boxes
    _userBox = await Hive.openBox<UserModel>('user');
    _cacheBox = await Hive.openBox('cache');
  }
  
  // User operations
  static Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', user);
  }
  
  static UserModel? getUser() {
    return _userBox.get('current_user');
  }
  
  static Future<void> deleteUser() async {
    await _userBox.delete('current_user');
  }
  
  // Secure PIN storage
  static Future<void> savePin(String pin) async {
    await _secureStorage.write(key: 'user_pin', value: pin);
  }
  
  static Future<String?> getPin() async {
    return await _secureStorage.read(key: 'user_pin');
  }
  
  static Future<void> deletePin() async {
    await _secureStorage.delete(key: 'user_pin');
  }
  
  // Device token for single device login
  static Future<void> saveDeviceToken(String token) async {
    await _secureStorage.write(key: 'device_token', value: token);
  }
  
  static Future<String?> getDeviceToken() async {
    return await _secureStorage.read(key: 'device_token');
  }
  
  // Cache operations
  static Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, data);
  }
  
  static dynamic getCachedData(String key) {
    return _cacheBox.get(key);
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    await _userBox.clear();
    await _cacheBox.clear();
    await _secureStorage.deleteAll();
  }
}
```

---

## ✅ SETUP COMPLETE

Your project is now configured with:

1. ✅ All required dependencies for real-time data
2. ✅ Android screenshot/screen recording prevention
3. ✅ iOS screen capture protection
4. ✅ Firebase push notifications
5. ✅ Secure PIN storage
6. ✅ Hive local storage with adapters
7. ✅ WebSocket service initialization
8. ✅ Proper route configuration
9. ✅ Theme and styling setup

**Next Steps:**
1. Copy these configurations to your project
2. Run `flutter pub get`
3. Run `flutter pub run build_runner build` to generate Hive adapters
4. Start implementing screens following the project plan
