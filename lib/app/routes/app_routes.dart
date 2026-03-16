abstract class AppRoutes {
  // Auth Routes
  static const splash = '/splash';
  static const registration = '/registration';
  static const emailVerification = '/email-verification';
  static const pinSetup = '/pin-setup';
  static const planSelection = '/plan-selection';
  static const pendingApproval = '/pending-approval';
  static const login = '/login';
  static const forgotPin = '/forgot-pin';

  // Main Routes
  static const main = '/main';
  static const home = '/home';

  // Future Routes
  static const future = '/future';
  static const londonLme = '/future/london';
  static const chinaSHFE = '/future/china';
  static const usComex = '/future/us';
  static const fx = '/future/fx';
  static const referenceRate = '/future/reference-rate';
  static const warehouseStock = '/future/stock';
  static const settlement = '/future/settlement';
  static const settlementChart = '/future/settlement-chart';

  // Forex Routes
  static const forex = '/forex';
  static const sbiForex = '/forex/sbi-rates';

  // Spot Price Routes
  static const spotPrice = '/spot';
  static const baseMetal = '/spot/base-metal';
  static const metalDetail = '/spot/metal-detail';
  static const bme = '/spot/bme';

  // Metal Detail Pages
  static const copperDetail = '/copper-detail';
  static const brassDetail = '/brass-detail';
  static const gunMetalDetail = '/gun-metal-detail';
  static const leadDetail = '/lead-detail';
  static const nickelDetail = '/nickel-detail';
  static const tinDetail = '/tin-detail';
  static const zincDetail = '/zinc-detail';
  static const aluminiumDetail = '/aluminium-detail';

  // Alert/News Routes
  static const alert = '/alert';
  static const liveFeed = '/alert/live-feed';
  static const news = '/alert/news';
  static const hindiNews = '/alert/hindi-news';
  static const circular = '/alert/circular';
  static const economicCalendar = '/alert/economic-calendar';
  static const economicCalendarWebView = '/alert/economic-calendar-webview';
  static const liveNewsWebView = '/alert/live-news-webview';
  static const newsDetail = '/alert/news-detail';
  static const pdfViewer = '/alert/pdf-viewer';
  static const eventDetail = '/alert/event-detail';

  // Watchlist Routes
  static const watchlist = '/watchlist';

  // Profile Routes
  static const profile = '/profile';
  static const settings = '/settings';
  static const editProfile = '/profile/edit';
  static const companyDetails = '/profile/company-details';
  static const aboutUs = '/profile/about-us';
  static const contactUs = '/profile/contact-us';
  static const feedback = '/profile/feedback';
  static const terms = '/profile/terms';
  static const changePin = '/profile/change-pin';
  static const subscription = '/profile/subscription';
  static const helpFaq = '/profile/help-faq';
  static const tutorial = '/profile/tutorial';
  static const privacyPolicy = '/profile/privacy-policy';

  // Notification & Search Routes
  static const notifications = '/notifications';
  static const search = '/search';

  // Additional Routes
  static const priceAlerts = '/price-alerts';
  static const savedItems = '/saved-items';
  static const adDetail = '/ad-detail';
  static const updateDetail = '/update-detail';
  static const allUpdates = '/updates';
  static const nonFerrousUpdates = '/non-ferrous-updates';
  static const onboarding = '/onboarding';
}
