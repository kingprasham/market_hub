import 'package:get/get.dart';
import 'app_routes.dart';

// Splash
import '../../features/splash/splash_screen.dart';
import '../../features/splash/splash_binding.dart';

// Auth
import '../../features/auth/registration/ui/registration_screen.dart';
import '../../features/auth/registration/binding/registration_binding.dart';
import '../../features/auth/email_verification/ui/email_verification_screen.dart';
import '../../features/auth/email_verification/binding/email_verification_binding.dart';
import '../../features/auth/pin_setup/ui/pin_setup_screen.dart';
import '../../features/auth/pin_setup/binding/pin_setup_binding.dart';
import '../../features/auth/plan_selection/ui/plan_selection_screen.dart';
import '../../features/auth/plan_selection/binding/plan_selection_binding.dart';
import '../../features/auth/pending_approval/ui/pending_approval_screen.dart';
import '../../features/auth/pending_approval/binding/pending_approval_binding.dart';
import '../../features/auth/login/ui/login_screen.dart';
import '../../features/auth/login/binding/login_binding.dart';
import '../../features/auth/forgot_pin/ui/forgot_pin_screen.dart';
import '../../features/auth/forgot_pin/binding/forgot_pin_binding.dart';

// Main Navigation
import '../../features/navigation/ui/main_navigation.dart';
import '../../features/navigation/binding/navigation_binding.dart';

// Profile
import '../../features/profile/ui/profile_screen.dart';
import '../../features/profile/binding/profile_binding.dart';
import '../../features/profile/pages/about_us_page.dart';
import '../../features/profile/pages/contact_us_page.dart';
import '../../features/profile/pages/feedback_page.dart';
import '../../features/profile/pages/terms_page.dart';
import '../../features/profile/pages/change_pin_page.dart';

// Settings
import '../../features/settings/ui/settings_screen.dart';
import '../../features/settings/binding/settings_binding.dart';

import '../../features/spot_price/ui/spot_price_screen.dart';
import '../../features/spot_price/binding/spot_price_binding.dart';
// Spot Price Metal Detail Pages
import '../../features/spot_price/pages/copper/ui/copper_detail_page.dart';
import '../../features/spot_price/pages/copper/binding/copper_detail_binding.dart';
import '../../features/spot_price/pages/brass/ui/brass_detail_page.dart';
import '../../features/spot_price/pages/brass/binding/brass_detail_binding.dart';
import '../../features/spot_price/pages/gun_metal/ui/gun_metal_detail_page.dart';
import '../../features/spot_price/pages/gun_metal/binding/gun_metal_detail_binding.dart';
import '../../features/spot_price/pages/lead/ui/lead_detail_page.dart';
import '../../features/spot_price/pages/lead/binding/lead_detail_binding.dart';
import '../../features/spot_price/pages/nickel/ui/nickel_detail_page.dart';
import '../../features/spot_price/pages/nickel/binding/nickel_detail_binding.dart';
import '../../features/spot_price/pages/tin/ui/tin_detail_page.dart';
import '../../features/spot_price/pages/tin/binding/tin_detail_binding.dart';
import '../../features/spot_price/pages/zinc/ui/zinc_detail_page.dart';
import '../../features/spot_price/pages/zinc/binding/zinc_detail_binding.dart';
import '../../features/spot_price/pages/aluminium/ui/aluminium_detail_page.dart';
import '../../features/spot_price/pages/aluminium/binding/aluminium_detail_binding.dart';

// Alerts Detail Pages
import '../../features/alerts/pages/news_detail/ui/news_detail_page.dart';
import '../../features/alerts/pages/news_detail/binding/news_detail_binding.dart';
import '../../features/alerts/pages/pdf_viewer/ui/pdf_viewer_page.dart';
import '../../features/alerts/pages/pdf_viewer/binding/pdf_viewer_binding.dart';
import '../../features/alerts/pages/event_detail/ui/event_detail_page.dart';
import '../../features/alerts/pages/event_detail/binding/event_detail_binding.dart';
import '../../features/alerts/pages/economic_calendar/ui/economic_calendar_webview_page.dart';
import '../../features/alerts/pages/live_news/ui/live_news_webview_page.dart';

// Forex
import '../../features/forex/ui/forex_screen.dart';
import '../../features/forex/binding/forex_binding.dart';

// Future
import '../../features/future/ui/future_screen.dart';
import '../../features/future/binding/future_binding.dart';

// Watchlist
import '../../features/watchlist/ui/watchlist_screen.dart';
import '../../features/watchlist/binding/watchlist_binding.dart';

// Alerts/News
import '../../features/alerts/ui/alerts_screen.dart';
import '../../features/alerts/binding/alerts_binding.dart';

// Notifications
import '../../features/notifications/ui/notifications_page.dart';
import '../../features/notifications/binding/notifications_binding.dart';

// Search
import '../../features/search/ui/search_page.dart';
import '../../features/search/binding/search_binding.dart';

// New Pages
import '../../features/profile/pages/edit_profile_page.dart';
import '../../features/profile/pages/company_details_page.dart';
import '../../features/profile/pages/price_alerts_page.dart';
import '../../features/profile/pages/saved_items_page.dart';
import '../../features/profile/pages/subscription_page.dart';
import '../../features/profile/pages/help_faq_page.dart';
import '../../features/profile/pages/tutorial_page.dart';
import '../../features/profile/pages/privacy_policy_page.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/ui/all_updates_page.dart';
import '../../features/home/ui/ad_detail_screen.dart';

class AppPages {
  static final routes = [
    // Splash
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fade,
    ),

    // Onboarding
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fade,
    ),

    // Auth
    GetPage(
      name: AppRoutes.registration,
      page: () => const RegistrationScreen(),
      binding: RegistrationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.emailVerification,
      page: () => const EmailVerificationScreen(),
      binding: EmailVerificationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.pinSetup,
      page: () => const PinSetupScreen(),
      binding: PinSetupBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.planSelection,
      page: () => const PlanSelectionScreen(),
      binding: PlanSelectionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.pendingApproval,
      page: () => const PendingApprovalScreen(),
      binding: PendingApprovalBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.forgotPin,
      page: () => const ForgotPinScreen(),
      binding: ForgotPinBinding(),
      transition: Transition.rightToLeft,
    ),

    // Main Navigation
    GetPage(
      name: AppRoutes.main,
      page: () => const MainNavigation(),
      binding: NavigationBinding(),
      transition: Transition.fade,
    ),

    // Profile
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),

    // Settings
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
    ),

    // Profile Sub-pages
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.companyDetails,
      page: () => const CompanyDetailsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.aboutUs,
      page: () => const AboutUsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.contactUs,
      page: () => const ContactUsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.feedback,
      page: () => const FeedbackPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.terms,
      page: () => const TermsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.changePin,
      page: () => const ChangePinPage(),
      transition: Transition.rightToLeft,
    ),

    // Price Alerts & Saved Items
    GetPage(
      name: AppRoutes.priceAlerts,
      page: () => const PriceAlertsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.savedItems,
      page: () => const SavedItemsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.helpFaq,
      page: () => const HelpFaqPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.tutorial,
      page: () => const TutorialPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyPage(),
      transition: Transition.rightToLeft,
    ),

    // Spot Price
    GetPage(
      name: AppRoutes.spotPrice,
      page: () => const SpotPriceScreen(),
      binding: SpotPriceBinding(),
      transition: Transition.rightToLeft,
    ),

    // Future
    GetPage(
      name: AppRoutes.future,
      page: () => const FutureScreen(),
      binding: FutureBinding(),
      transition: Transition.rightToLeft,
    ),

    // Watchlist
    GetPage(
      name: AppRoutes.watchlist,
      page: () => const WatchlistScreen(),
      binding: WatchlistBinding(),
      transition: Transition.rightToLeft,
    ),

    // Alerts/News
    GetPage(
      name: AppRoutes.alert,
      page: () => const AlertsScreen(),
      binding: AlertsBinding(),
      transition: Transition.rightToLeft,
    ),

    // Metal Detail Pages
    GetPage(
      name: AppRoutes.copperDetail,
      page: () => const CopperDetailPage(),
      binding: CopperDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.brassDetail,
      page: () => const BrassDetailPage(),
      binding: BrassDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.gunMetalDetail,
      page: () => const GunMetalDetailPage(),
      binding: GunMetalDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.leadDetail,
      page: () => const LeadDetailPage(),
      binding: LeadDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.nickelDetail,
      page: () => const NickelDetailPage(),
      binding: NickelDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.tinDetail,
      page: () => const TinDetailPage(),
      binding: TinDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.zincDetail,
      page: () => const ZincDetailPage(),
      binding: ZincDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.aluminiumDetail,
      page: () => const AluminiumDetailPage(),
      binding: AluminiumDetailBinding(),
      transition: Transition.rightToLeft,
    ),

    // Alerts Detail Pages
    GetPage(
      name: AppRoutes.newsDetail,
      page: () => const NewsDetailPage(),
      binding: NewsDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.pdfViewer,
      page: () => const PdfViewerPage(),
      binding: PdfViewerBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.eventDetail,
      page: () => const EventDetailPage(),
      binding: EventDetailBinding(),
      transition: Transition.rightToLeft,
    ),

    // Economic Calendar WebView (Investing.com)
    GetPage(
      name: AppRoutes.economicCalendarWebView,
      page: () => const EconomicCalendarWebViewPage(),
      transition: Transition.rightToLeft,
    ),

    // Live News WebView (Trading Economics)
    GetPage(
      name: AppRoutes.liveNewsWebView,
      page: () => const LiveNewsWebViewPage(),
      transition: Transition.rightToLeft,
    ),

    // Notifications & Search
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: SearchBinding(),
      transition: Transition.rightToLeft,
    ),

    // Home
    GetPage(
      name: AppRoutes.allUpdates,
      page: () => const AllUpdatesPage(),
      transition: Transition.rightToLeft,
    ),

    // Forex - SBI TT Rates
    GetPage(
      name: AppRoutes.sbiForex,
      page: () => const ForexScreen(),
      binding: ForexBinding(),
      transition: Transition.rightToLeft,
    ),

    // Ad Detail
    GetPage(
      name: AppRoutes.adDetail,
      page: () => const AdDetailScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}

