# Market Hub - Complete Project Planning Document

## Project Overview

**Market Hub** is a real-time commodity/metal market tracking application with:
1. **Flutter Mobile App** (Android + iOS) - User-facing application
2. **Admin Dashboard** (React/Flutter Web) - Content management & user administration
3. **Backend API** - Real-time data processing with WebSocket support

---

## PART 1: FLUTTER MOBILE APP ARCHITECTURE

### 1.1 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp/GetMaterialApp configuration
│   ├── routes/
│   │   ├── app_routes.dart         # Route names
│   │   └── app_pages.dart          # GetX route bindings
│   └── bindings/
│       └── initial_binding.dart    # Initial dependencies
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart      # API endpoints
│   │   ├── color_constants.dart    # App colors
│   │   ├── text_styles.dart        # Typography
│   │   └── app_constants.dart      # General constants
│   │
│   ├── network/
│   │   ├── api_client.dart         # Dio HTTP client
│   │   ├── api_interceptor.dart    # Request/response interceptor
│   │   ├── websocket_service.dart  # WebSocket for real-time data
│   │   └── api_exceptions.dart     # Custom exceptions
│   │
│   ├── storage/
│   │   ├── local_storage.dart      # Hive wrapper
│   │   ├── secure_storage.dart     # Encrypted PIN storage
│   │   └── cache_manager.dart      # Data caching
│   │
│   ├── utils/
│   │   ├── validators.dart         # Form validation
│   │   ├── formatters.dart         # Date/number formatting
│   │   ├── helpers.dart            # Utility functions
│   │   └── device_info.dart        # Device token generation
│   │
│   ├── theme/
│   │   ├── app_theme.dart          # Light/dark theme
│   │   └── custom_colors.dart      # Theme extensions
│   │
│   └── security/
│       ├── screenshot_blocker.dart # Prevent screenshots
│       └── session_manager.dart    # Single device login
│
├── data/
│   ├── models/
│   │   ├── user/
│   │   │   ├── user_model.dart
│   │   │   ├── registration_request.dart
│   │   │   └── login_response.dart
│   │   │
│   │   ├── market/
│   │   │   ├── future_data_model.dart
│   │   │   ├── spot_price_model.dart
│   │   │   ├── fx_model.dart
│   │   │   └── reference_rate_model.dart
│   │   │
│   │   ├── content/
│   │   │   ├── news_model.dart
│   │   │   ├── circular_model.dart
│   │   │   ├── update_model.dart
│   │   │   └── economic_event_model.dart
│   │   │
│   │   ├── plan/
│   │   │   └── plan_model.dart
│   │   │
│   │   └── watchlist/
│   │       └── watchlist_item_model.dart
│   │
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── market_repository.dart
│   │   ├── content_repository.dart
│   │   ├── watchlist_repository.dart
│   │   └── profile_repository.dart
│   │
│   └── providers/
│       ├── auth_provider.dart
│       ├── market_provider.dart
│       └── content_provider.dart
│
├── features/
│   ├── splash/
│   │   ├── splash_screen.dart
│   │   └── splash_controller.dart
│   │
│   ├── auth/
│   │   ├── registration/
│   │   │   ├── ui/
│   │   │   │   └── registration_screen.dart
│   │   │   ├── controller/
│   │   │   │   └── registration_controller.dart
│   │   │   └── widgets/
│   │   │       ├── registration_form.dart
│   │   │       └── visiting_card_picker.dart
│   │   │
│   │   ├── email_verification/
│   │   │   ├── ui/
│   │   │   │   └── email_verification_screen.dart
│   │   │   ├── controller/
│   │   │   │   └── email_verification_controller.dart
│   │   │   └── widgets/
│   │   │       └── otp_input.dart
│   │   │
│   │   ├── pin_setup/
│   │   │   ├── ui/
│   │   │   │   └── pin_setup_screen.dart
│   │   │   └── controller/
│   │   │       └── pin_setup_controller.dart
│   │   │
│   │   ├── plan_selection/
│   │   │   ├── ui/
│   │   │   │   └── plan_selection_screen.dart
│   │   │   ├── controller/
│   │   │   │   └── plan_selection_controller.dart
│   │   │   └── widgets/
│   │   │       └── plan_card.dart
│   │   │
│   │   ├── pending_approval/
│   │   │   ├── ui/
│   │   │   │   └── pending_approval_screen.dart
│   │   │   └── controller/
│   │   │       └── pending_approval_controller.dart
│   │   │
│   │   └── login/
│   │       ├── ui/
│   │       │   └── login_screen.dart
│   │       ├── controller/
│   │       │   └── login_controller.dart
│   │       └── widgets/
│   │           └── pin_input.dart
│   │
│   ├── home/
│   │   ├── ui/
│   │   │   └── home_screen.dart
│   │   ├── controller/
│   │   │   └── home_controller.dart
│   │   └── widgets/
│   │       ├── greeting_header.dart
│   │       ├── update_card.dart
│   │       └── update_detail_view.dart
│   │
│   ├── future/
│   │   ├── ui/
│   │   │   └── future_screen.dart
│   │   ├── controller/
│   │   │   └── future_controller.dart
│   │   ├── pages/
│   │   │   ├── london_lme/
│   │   │   │   ├── ui/
│   │   │   │   │   └── london_lme_page.dart
│   │   │   │   ├── controller/
│   │   │   │   │   └── london_lme_controller.dart
│   │   │   │   └── widgets/
│   │   │   │       └── lme_item_card.dart
│   │   │   │
│   │   │   ├── china_shfe/
│   │   │   │   ├── ui/
│   │   │   │   │   └── china_shfe_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── china_shfe_controller.dart
│   │   │   │
│   │   │   ├── us_comex/
│   │   │   │   ├── ui/
│   │   │   │   │   └── us_comex_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── us_comex_controller.dart
│   │   │   │
│   │   │   ├── fx/
│   │   │   │   ├── ui/
│   │   │   │   │   └── fx_page.dart
│   │   │   │   ├── controller/
│   │   │   │   │   └── fx_controller.dart
│   │   │   │   └── widgets/
│   │   │   │       └── fx_card.dart
│   │   │   │
│   │   │   ├── reference_rate/
│   │   │   │   ├── ui/
│   │   │   │   │   └── reference_rate_page.dart
│   │   │   │   ├── controller/
│   │   │   │   │   └── reference_rate_controller.dart
│   │   │   │   └── pages/
│   │   │   │       ├── sbi_tt_page.dart
│   │   │   │       └── f_bill_page.dart
│   │   │   │
│   │   │   ├── stock/
│   │   │   │   ├── ui/
│   │   │   │   │   └── warehouse_stock_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── warehouse_stock_controller.dart
│   │   │   │
│   │   │   └── settlement/
│   │   │       ├── ui/
│   │   │       │   └── settlement_page.dart
│   │   │       └── controller/
│   │   │           └── settlement_controller.dart
│   │   │
│   │   └── widgets/
│   │       └── market_data_card.dart
│   │
│   ├── spot_price/
│   │   ├── ui/
│   │   │   └── spot_price_screen.dart
│   │   ├── controller/
│   │   │   └── spot_price_controller.dart
│   │   ├── pages/
│   │   │   ├── base_metal/
│   │   │   │   ├── ui/
│   │   │   │   │   └── base_metal_page.dart
│   │   │   │   ├── controller/
│   │   │   │   │   └── base_metal_controller.dart
│   │   │   │   └── widgets/
│   │   │   │       └── metal_category_card.dart
│   │   │   │
│   │   │   ├── metal_detail/
│   │   │   │   ├── ui/
│   │   │   │   │   └── metal_detail_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── metal_detail_controller.dart
│   │   │   │
│   │   │   └── bme/
│   │   │       ├── ui/
│   │   │       │   └── bme_page.dart
│   │   │       └── controller/
│   │   │           └── bme_controller.dart
│   │   │
│   │   └── widgets/
│   │       └── spot_price_card.dart
│   │
│   ├── alert/
│   │   ├── ui/
│   │   │   └── alert_screen.dart
│   │   ├── controller/
│   │   │   └── alert_controller.dart
│   │   ├── pages/
│   │   │   ├── live_feed/
│   │   │   │   ├── ui/
│   │   │   │   │   └── live_feed_page.dart
│   │   │   │   ├── controller/
│   │   │   │   │   └── live_feed_controller.dart
│   │   │   │   └── widgets/
│   │   │   │       └── news_card.dart
│   │   │   │
│   │   │   ├── news/
│   │   │   │   ├── ui/
│   │   │   │   │   └── news_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── news_controller.dart
│   │   │   │
│   │   │   ├── hindi_news/
│   │   │   │   ├── ui/
│   │   │   │   │   └── hindi_news_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── hindi_news_controller.dart
│   │   │   │
│   │   │   ├── circular/
│   │   │   │   ├── ui/
│   │   │   │   │   └── circular_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── circular_controller.dart
│   │   │   │
│   │   │   └── economic_calendar/
│   │   │       ├── ui/
│   │   │       │   └── economic_calendar_page.dart
│   │   │       └── controller/
│   │   │           └── economic_calendar_controller.dart
│   │   │
│   │   └── widgets/
│   │       ├── news_item.dart
│   │       └── news_detail_view.dart
│   │
│   ├── watchlist/
│   │   ├── ui/
│   │   │   └── watchlist_screen.dart
│   │   ├── controller/
│   │   │   └── watchlist_controller.dart
│   │   ├── pages/
│   │   │   ├── future_watchlist/
│   │   │   │   └── future_watchlist_page.dart
│   │   │   │
│   │   │   └── spot_watchlist/
│   │   │       └── spot_watchlist_page.dart
│   │   │
│   │   └── widgets/
│   │       ├── watchlist_item.dart
│   │       └── empty_watchlist.dart
│   │
│   ├── profile/
│   │   ├── ui/
│   │   │   └── profile_screen.dart
│   │   ├── controller/
│   │   │   └── profile_controller.dart
│   │   ├── pages/
│   │   │   ├── about_us/
│   │   │   │   └── about_us_page.dart
│   │   │   │
│   │   │   ├── contact_us/
│   │   │   │   └── contact_us_page.dart
│   │   │   │
│   │   │   ├── feedback/
│   │   │   │   ├── ui/
│   │   │   │   │   └── feedback_page.dart
│   │   │   │   └── controller/
│   │   │   │       └── feedback_controller.dart
│   │   │   │
│   │   │   ├── terms/
│   │   │   │   └── terms_page.dart
│   │   │   │
│   │   │   └── change_pin/
│   │   │       ├── ui/
│   │   │       │   └── change_pin_page.dart
│   │   │       └── controller/
│   │   │           └── change_pin_controller.dart
│   │   │
│   │   └── widgets/
│   │       ├── profile_header.dart
│   │       └── profile_menu_item.dart
│   │
│   └── navigation/
│       ├── ui/
│       │   └── main_navigation.dart
│       └── controller/
│           └── navigation_controller.dart
│
└── shared/
    ├── widgets/
    │   ├── buttons/
    │   │   ├── primary_button.dart
    │   │   └── secondary_button.dart
    │   │
    │   ├── inputs/
    │   │   ├── custom_text_field.dart
    │   │   ├── phone_number_field.dart
    │   │   ├── pin_input_field.dart
    │   │   └── otp_input_field.dart
    │   │
    │   ├── cards/
    │   │   ├── base_card.dart
    │   │   └── shimmer_card.dart
    │   │
    │   ├── dialogs/
    │   │   ├── confirmation_dialog.dart
    │   │   ├── error_dialog.dart
    │   │   └── loading_dialog.dart
    │   │
    │   ├── loaders/
    │   │   ├── shimmer_loader.dart
    │   │   └── circular_loader.dart
    │   │
    │   └── common/
    │       ├── app_bar.dart
    │       ├── bottom_sheet.dart
    │       ├── empty_state.dart
    │       └── error_state.dart
    │
    └── extensions/
        ├── context_extensions.dart
        ├── string_extensions.dart
        └── date_extensions.dart
```

---

## PART 2: PAGE-BY-PAGE IMPLEMENTATION PLAN

### 2.1 AUTHENTICATION FLOW (6 Screens)

#### Screen 1: Splash Screen
**File:** `features/splash/splash_screen.dart`
**Logic:**
1. Show app logo with animation
2. Check if user exists in local storage (Hive)
3. Check if user has PIN set
4. Check if user is approved by admin
5. Route accordingly:
   - No user → Registration
   - User exists, not approved → Pending Approval
   - User exists, approved, no PIN → PIN Setup
   - User exists, approved, has PIN → Login

```dart
// Flow logic:
Future<void> checkAuthState() async {
  final user = await localStorage.getUser();
  if (user == null) {
    Get.offAllNamed(Routes.REGISTRATION);
  } else if (!user.isApproved) {
    Get.offAllNamed(Routes.PENDING_APPROVAL);
  } else if (user.pin == null) {
    Get.offAllNamed(Routes.PIN_SETUP);
  } else {
    Get.offAllNamed(Routes.LOGIN);
  }
}
```

---

#### Screen 2: Registration Screen
**File:** `features/auth/registration/ui/registration_screen.dart`
**Fields:**
- Full Name (TextEditingController)
- WhatsApp Number (with country code picker)
- Phone Number (with country code picker)
- Email Address
- Visiting Card (Image picker - gallery/camera)
- Pin Code (6-digit)
- Terms & Conditions checkbox

**Validation Rules:**
```dart
class RegistrationValidator {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name too short';
    if (value.length > 50) return 'Name too long';
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone is required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Invalid phone';
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(value)) return 'Invalid email';
    return null;
  }
  
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) return 'Pincode is required';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Must be 6 digits';
    return null;
  }
}
```

**API Call:**
```dart
// POST /user/create-registration
{
  "fullName": "string",
  "whatsappNumber": "string",
  "whatsappCountryCode": "string",
  "phoneNumber": "string",
  "countryCode": "string",
  "email": "string",
  "visitingCard": "base64_image_string",
  "pincode": "string"
}
```

---

#### Screen 3: Email Verification Screen
**File:** `features/auth/email_verification/ui/email_verification_screen.dart`
**Components:**
- Email display (pre-filled, read-only)
- OTP input (4-6 digits)
- Verify OTP button
- Resend OTP button (with 30s cooldown timer)
- Change Email link

**Logic:**
```dart
class EmailVerificationController extends GetxController {
  final email = ''.obs;
  final otp = ''.obs;
  final isLoading = false.obs;
  final canResend = true.obs;
  final countdown = 0.obs;
  Timer? _timer;
  
  Future<void> verifyOTP() async {
    if (otp.value.length < 4) {
      showError('Enter valid OTP');
      return;
    }
    isLoading.value = true;
    final result = await authRepository.verifyEmail(email.value, otp.value);
    isLoading.value = false;
    
    result.fold(
      (error) => showError(error.message),
      (success) => Get.offAllNamed(Routes.PIN_SETUP),
    );
  }
  
  void startResendTimer() {
    canResend.value = false;
    countdown.value = 30;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      countdown.value--;
      if (countdown.value <= 0) {
        canResend.value = true;
        timer.cancel();
      }
    });
  }
  
  Future<void> changeEmail(String newEmail) async {
    final result = await authRepository.updateEmail(newEmail);
    result.fold(
      (error) => showError(error.message),
      (success) {
        email.value = newEmail;
        startResendTimer();
      },
    );
  }
}
```

---

#### Screen 4: PIN Setup Screen
**File:** `features/auth/pin_setup/ui/pin_setup_screen.dart`
**Components:**
- Enter PIN (4-digit masked input)
- Confirm PIN (4-digit masked input)
- Set PIN button

**Logic:**
```dart
class PinSetupController extends GetxController {
  final pin = ''.obs;
  final confirmPin = ''.obs;
  final isLoading = false.obs;
  
  Future<void> setPin() async {
    if (pin.value.length != 4) {
      showError('PIN must be 4 digits');
      return;
    }
    if (pin.value != confirmPin.value) {
      showError('PINs do not match');
      return;
    }
    
    isLoading.value = true;
    final result = await authRepository.setPin(pin.value);
    isLoading.value = false;
    
    result.fold(
      (error) => showError(error.message),
      (success) => Get.offAllNamed(Routes.PLAN_SELECTION),
    );
  }
}
```

---

#### Screen 5: Plan Selection Screen
**File:** `features/auth/plan_selection/ui/plan_selection_screen.dart`
**Components:**
- Horizontal scrollable plan cards
- Each card shows: Plan Name, Features list, Price, Duration
- Page indicator dots
- Select button

**Plan Card Structure:**
```dart
class PlanModel {
  final String id;
  final String name;
  final List<String> features;
  final double price;
  final String duration; // 'monthly', 'half-yearly', 'yearly'
  final int durationDays;
}
```

**Logic:**
```dart
class PlanSelectionController extends GetxController {
  final plans = <PlanModel>[].obs;
  final selectedPlanIndex = 0.obs;
  final isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }
  
  Future<void> fetchPlans() async {
    isLoading.value = true;
    final result = await planRepository.getPlans();
    isLoading.value = false;
    
    result.fold(
      (error) => showError(error.message),
      (planList) => plans.assignAll(planList),
    );
  }
  
  Future<void> selectPlan() async {
    final selectedPlan = plans[selectedPlanIndex.value];
    isLoading.value = true;
    final result = await planRepository.selectPlan(selectedPlan.id);
    isLoading.value = false;
    
    result.fold(
      (error) => showError(error.message),
      (success) => Get.offAllNamed(Routes.PENDING_APPROVAL),
    );
  }
}
```

---

#### Screen 6: Pending Approval Screen
**File:** `features/auth/pending_approval/ui/pending_approval_screen.dart`
**Components:**
- Waiting illustration
- "Your account is under verification" message
- "You will be notified once approved" sub-message
- Retry/Check Status button

**Logic:**
```dart
class PendingApprovalController extends GetxController {
  final isApproved = false.obs;
  final isRejected = false.obs;
  final rejectionMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    checkApprovalStatus();
    // Setup push notification listener
    setupNotificationListener();
  }
  
  Future<void> checkApprovalStatus() async {
    final result = await authRepository.checkApprovalStatus();
    result.fold(
      (error) => showError(error.message),
      (status) {
        if (status.isApproved) {
          Get.offAllNamed(Routes.LOGIN);
        } else if (status.isRejected) {
          isRejected.value = true;
          rejectionMessage.value = status.message;
          // Show re-upload option
        }
      },
    );
  }
  
  void setupNotificationListener() {
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'approval') {
        if (message.data['status'] == 'approved') {
          Get.offAllNamed(Routes.LOGIN);
        }
      }
    });
  }
}
```

---

#### Screen 7: Login Screen
**File:** `features/auth/login/ui/login_screen.dart`
**Components:**
- App logo
- "Welcome Back" title
- PIN input (4-digit masked)
- Login button
- Forgot PIN link
- "New User? Register Now" link

**Logic:**
```dart
class LoginController extends GetxController {
  final pin = ''.obs;
  final isLoading = false.obs;
  
  Future<void> login() async {
    if (pin.value.length != 4) {
      showError('Enter 4-digit PIN');
      return;
    }
    
    final storedUser = await localStorage.getUser();
    if (storedUser?.pin == pin.value) {
      // Generate device token for single device login
      final deviceToken = await DeviceInfo.generateToken();
      final result = await authRepository.login(deviceToken);
      
      result.fold(
        (error) => showError(error.message),
        (success) => Get.offAllNamed(Routes.HOME),
      );
    } else {
      showError('Incorrect PIN');
    }
  }
}
```

---

### 2.2 MAIN APPLICATION (5 Bottom Navigation Tabs)

#### Tab 1: Home Screen
**File:** `features/home/ui/home_screen.dart`
**Components:**
- Top: Greeting "Hello, {UserName}"
- Top Right: Profile icon
- Main: Admin updates list (scrollable)

**Update Card:**
```dart
class UpdateModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? pdfUrl;
  final DateTime createdAt;
}
```

**Logic:**
```dart
class HomeController extends GetxController {
  final updates = <UpdateModel>[].obs;
  final isLoading = false.obs;
  final userName = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadUserName();
    fetchUpdates();
  }
  
  Future<void> fetchUpdates() async {
    isLoading.value = true;
    final result = await contentRepository.getHomeUpdates();
    isLoading.value = false;
    
    result.fold(
      (error) => showError(error.message),
      (updateList) => updates.assignAll(updateList),
    );
  }
  
  void openUpdateDetail(UpdateModel update) {
    Get.to(() => UpdateDetailView(update: update));
  }
}
```

---

#### Tab 2: Future Screen
**File:** `features/future/ui/future_screen.dart`
**Top Tabs:**
1. Future (default)
2. Stock
3. Settlement

**Future Sub-tabs:**
1. London (LME)
2. China (SHFE)
3. US (COMEX)
4. FX
5. Reference Rate

**CRITICAL: Real-time Data Implementation**

```dart
// WebSocket Service for real-time data
class MarketWebSocketService {
  WebSocketChannel? _channel;
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  void connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://api.markethubindia.com/ws/market'),
    );
    
    _channel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data);
        _dataController.add(decoded);
      },
      onError: (error) {
        // Auto-reconnect after 3 seconds
        Future.delayed(Duration(seconds: 3), connect);
      },
    );
  }
  
  void subscribe(String channel) {
    _channel?.sink.add(jsonEncode({'action': 'subscribe', 'channel': channel}));
  }
  
  void dispose() {
    _channel?.sink.close();
    _dataController.close();
  }
}
```

**Market Data Card:**
```dart
class FutureDataModel {
  final String symbol;
  final String name;
  final double lastTradePrice;
  final double high;
  final double low;
  final double change;
  final double changePercent;
  final DateTime lastTradeTime;
}

// UI with StreamBuilder for live updates
class LMEController extends GetxController {
  final marketService = Get.find<MarketWebSocketService>();
  final lmeData = <FutureDataModel>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    marketService.subscribe('lme');
    
    marketService.dataStream
      .where((data) => data['channel'] == 'lme')
      .listen((data) {
        // Diff patching - only update changed values
        _updateData(data['payload']);
      });
  }
  
  void _updateData(List<dynamic> payload) {
    for (var item in payload) {
      final index = lmeData.indexWhere((d) => d.symbol == item['symbol']);
      if (index != -1) {
        // Update only changed fields
        lmeData[index] = FutureDataModel.fromJson(item);
      } else {
        lmeData.add(FutureDataModel.fromJson(item));
      }
    }
  }
}
```

---

#### Tab 3: Spot Price Screen
**File:** `features/spot_price/ui/spot_price_screen.dart`
**Top Tabs:**
1. Base Metal (default)
2. BME

**Base Metal Categories (Grid):**
- Copper, Brass, Gun Metal, Lead, Nickel, Tin, Zinc, Aluminium

Each category leads to a detail page with location-based spot prices.

**Structure:**
```dart
class SpotPriceModel {
  final String metalName;
  final String location;
  final double price;
  final double change;
  final DateTime updatedAt;
}
```

---

#### Tab 4: Alert Screen
**File:** `features/alert/ui/alert_screen.dart`
**Sections (Scrollable Categories):**
1. Live Feed (Auto-scraped news)
2. News (Admin-uploaded, English)
3. Hindi News (Admin-uploaded)
4. Circular (Admin-uploaded PDFs)
5. Economic Calendar (Scraped)

**Plan-Based Content Filtering:**
```dart
class AlertController extends GetxController {
  final userPlan = ''.obs;
  final news = <NewsModel>[].obs;
  
  Future<void> fetchNews() async {
    // API automatically filters based on user's plan
    final result = await contentRepository.getNews(planId: userPlan.value);
    // ...
  }
}
```

---

#### Tab 5: Watchlist Screen
**File:** `features/watchlist/ui/watchlist_screen.dart`
**Top Tabs:**
1. Future
2. Spot Price

**Watchlist Logic:**
```dart
class WatchlistController extends GetxController {
  final futureWatchlist = <String>[].obs; // List of symbol IDs
  final spotWatchlist = <String>[].obs;   // List of metal+location IDs
  
  Future<void> addToWatchlist(String itemId, String type) async {
    if (type == 'future') {
      if (!futureWatchlist.contains(itemId)) {
        futureWatchlist.add(itemId);
        await watchlistRepository.addFutureItem(itemId);
      }
    } else {
      if (!spotWatchlist.contains(itemId)) {
        spotWatchlist.add(itemId);
        await watchlistRepository.addSpotItem(itemId);
      }
    }
  }
  
  Future<void> removeFromWatchlist(String itemId, String type) async {
    if (type == 'future') {
      futureWatchlist.remove(itemId);
      await watchlistRepository.removeFutureItem(itemId);
    } else {
      spotWatchlist.remove(itemId);
      await watchlistRepository.removeSpotItem(itemId);
    }
  }
  
  bool isInWatchlist(String itemId, String type) {
    return type == 'future' 
      ? futureWatchlist.contains(itemId)
      : spotWatchlist.contains(itemId);
  }
}
```

---

### 2.3 PROFILE SECTION

**File:** `features/profile/ui/profile_screen.dart`
**Components:**
- User info header (Name, Plan, Validity)
- About Us
- Contact Us
- Feedback
- Terms & Conditions
- Logout

---

## PART 3: SECURITY IMPLEMENTATION

### 3.1 Screenshot & Screen Recording Prevention

**Android (MainActivity.kt):**
```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    )
}
```

**iOS (Runner/AppDelegate.swift):**
```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(preventCapture),
        name: UIApplication.userDidTakeScreenshotNotification,
        object: nil
    )
}
```

**Flutter Implementation:**
```dart
class ScreenshotBlocker {
  static void enable() {
    if (Platform.isAndroid) {
      // Use MethodChannel to call native code
      const platform = MethodChannel('com.markethub/security');
      platform.invokeMethod('enableSecureFlag');
    }
  }
}
```

### 3.2 Single Device Login

```dart
class SessionManager {
  static Future<void> enforceSession(String deviceToken) async {
    final storedToken = await secureStorage.getDeviceToken();
    final serverToken = await authRepository.getActiveDeviceToken();
    
    if (serverToken != null && serverToken != deviceToken) {
      // Force logout - another device logged in
      await _forceLogout();
      Get.offAllNamed(Routes.LOGIN);
      showError('Logged out: Another device logged in');
    }
  }
  
  static Future<void> _forceLogout() async {
    await secureStorage.clearPin();
    await localStorage.clearSession();
  }
}
```

---

## PART 4: ADMIN DASHBOARD (Web)

### 4.1 Dashboard Modules

1. **Dashboard Home**
   - Total users, Free trial, Subscribed, Rejected counts
   - Revenue chart
   - Recent registrations
   - Most bought plans

2. **User Management**
   - Verify pending users (Approve/Reject)
   - Free trial users list
   - Expired trial users
   - Rejected users
   - Subscribed users

3. **Content Management**
   - Home Page Updates (CRUD)
   - News (English) - CRUD with plan targeting
   - Hindi News - CRUD with plan targeting
   - Circulars - CRUD with plan targeting

4. **Market Data Management**
   - Add/Edit Reference Rates (SBI TT, F-BILL)
   - Add/Edit Warehouse Stock
   - Add/Edit Spot Prices
   - Manage Locations

5. **Plan Management**
   - Create/Edit/Delete plans
   - Assign features to plans

6. **Admin Management**
   - Add new admins
   - Manage admin permissions

7. **Feedback**
   - View user feedback
   - Respond to feedback

---

## PART 5: BACKEND API REQUIREMENTS

### 5.1 Real-time Data Architecture

```
┌─────────────────┐      ┌──────────────────┐
│  Data Sources   │      │  Backend Server  │
│  (LME, SHFE,    │─────>│  (Node.js/Go)    │
│   COMEX, etc)   │      │                  │
└─────────────────┘      │  ┌────────────┐  │
                         │  │  Scraper   │  │
                         │  │  Service   │  │
                         │  └─────┬──────┘  │
                         │        │         │
                         │  ┌─────▼──────┐  │
                         │  │   Redis    │  │
                         │  │  (Cache)   │  │
                         │  └─────┬──────┘  │
                         │        │         │
                         │  ┌─────▼──────┐  │
                         │  │ WebSocket  │  │
                         │  │  Server    │  │
                         │  └─────┬──────┘  │
                         └────────┼─────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
              ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
              │  Mobile   │ │  Mobile   │ │   Web     │
              │  Client   │ │  Client   │ │ Dashboard │
              └───────────┘ └───────────┘ └───────────┘
```

### 5.2 Required API Endpoints

**Authentication:**
```
POST   /api/auth/register
POST   /api/auth/verify-email
POST   /api/auth/resend-otp
POST   /api/auth/update-email
POST   /api/auth/set-pin
POST   /api/auth/login
POST   /api/auth/forgot-pin
POST   /api/auth/reset-pin
GET    /api/auth/check-approval
```

**Plans:**
```
GET    /api/plans
POST   /api/plans/select
```

**Home Updates:**
```
GET    /api/updates
```

**Market Data (REST + WebSocket):**
```
WS     /ws/market
GET    /api/market/lme
GET    /api/market/shfe
GET    /api/market/comex
GET    /api/market/fx
GET    /api/market/reference-rates
GET    /api/market/warehouse-stock
GET    /api/market/settlement
```

**Spot Price:**
```
GET    /api/spot/base-metals
GET    /api/spot/base-metals/:metalId
GET    /api/spot/bme
```

**Content:**
```
GET    /api/content/news
GET    /api/content/hindi-news
GET    /api/content/circulars
GET    /api/content/live-feed
GET    /api/content/economic-calendar
```

**Watchlist:**
```
GET    /api/watchlist
POST   /api/watchlist/future
DELETE /api/watchlist/future/:id
POST   /api/watchlist/spot
DELETE /api/watchlist/spot/:id
```

**Profile:**
```
GET    /api/profile
POST   /api/profile/feedback
POST   /api/profile/change-pin
```

**Admin Endpoints:**
```
GET    /api/admin/dashboard/stats
GET    /api/admin/users/pending
POST   /api/admin/users/:id/approve
POST   /api/admin/users/:id/reject
GET    /api/admin/users/free-trial
GET    /api/admin/users/expired
GET    /api/admin/users/rejected
GET    /api/admin/users/subscribed

CRUD   /api/admin/updates
CRUD   /api/admin/news
CRUD   /api/admin/hindi-news
CRUD   /api/admin/circulars
CRUD   /api/admin/plans
CRUD   /api/admin/spot-prices
CRUD   /api/admin/reference-rates
CRUD   /api/admin/warehouse-stock
CRUD   /api/admin/locations
```

---

## PART 6: DEPENDENCIES (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  get: ^4.6.6
  
  # Networking
  dio: ^5.7.0
  web_socket_channel: ^2.4.0
  pretty_dio_logger: ^1.4.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_messaging: ^15.0.0
  
  # UI Components
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  carousel_slider: ^5.0.0
  pinput: ^3.0.1
  
  # Image Handling
  image_picker: ^1.1.2
  photo_view: ^0.15.0
  
  # PDF Viewer
  flutter_pdfview: ^1.3.2
  
  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.3.1
  share_plus: ^10.1.0
  permission_handler: ^11.3.1
  connectivity_plus: ^6.0.0
  
  # WebView
  webview_flutter: ^4.10.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
```

---

## PART 7: IMPLEMENTATION PRIORITY

### Phase 1: Core Authentication (Week 1-2)
1. ✅ Splash Screen
2. ✅ Registration Screen
3. ✅ Email Verification
4. ✅ PIN Setup
5. ✅ Plan Selection
6. ✅ Pending Approval
7. ✅ Login Screen

### Phase 2: Main Navigation & Home (Week 3)
1. ✅ Bottom Navigation
2. ✅ Home Screen with Updates
3. ✅ Profile Screen
4. ✅ Basic API integration

### Phase 3: Future Section (Week 4-5)
1. ✅ WebSocket setup for real-time data
2. ✅ LME/London page
3. ✅ China/SHFE page
4. ✅ US/COMEX page
5. ✅ FX page
6. ✅ Reference Rate pages
7. ✅ Stock & Settlement pages

### Phase 4: Spot Price & Alert (Week 6-7)
1. ✅ Base Metal categories
2. ✅ Metal detail pages
3. ✅ BME section
4. ✅ Live Feed
5. ✅ News/Hindi News/Circular pages
6. ✅ Economic Calendar

### Phase 5: Watchlist & Polish (Week 8)
1. ✅ Watchlist functionality
2. ✅ Security features (screenshot block, single device)
3. ✅ UI/UX polish
4. ✅ Performance optimization

### Phase 6: Admin Dashboard (Week 9-10)
1. ✅ Dashboard home
2. ✅ User management
3. ✅ Content management
4. ✅ Market data management

---

## PART 8: KEY TECHNICAL DECISIONS

1. **State Management:** GetX (already used in reference project)
2. **Architecture:** Feature-first with clean separation
3. **Real-time Data:** WebSocket with Redis caching on backend
4. **Local Storage:** Hive for general data, FlutterSecureStorage for PIN
5. **API Client:** Dio with interceptors
6. **Navigation:** GetX named routes
7. **Forms:** Custom validators with reactive forms
8. **Images:** Cached network images with shimmer loading
9. **Error Handling:** Either pattern (Left=Error, Right=Success)

---

This document serves as the complete blueprint for building the Market Hub application. Each section contains the technical specifications, code patterns, and implementation logic needed to build the feature.
