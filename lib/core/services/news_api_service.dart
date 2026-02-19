import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../config/api_keys.dart';
import '../../data/models/content/news_model.dart';

/// Service for fetching news from GNews.io API
/// Free tier: 100 requests/day
/// Docs: https://gnews.io/docs/v4
class NewsApiService extends GetxService {
  final Dio _dio = Dio();
  
  // Cache for news
  final _englishNewsCache = <NewsModel>[].obs;
  final _hindiNewsCache = <NewsModel>[].obs;
  
  // Loading states
  final isLoadingEnglish = false.obs;
  final isLoadingHindi = false.obs;
  
  // Last fetch time for caching
  DateTime? _lastEnglishFetch;
  DateTime? _lastHindiFetch;
  
  // Cache duration (30 minutes to preserve API quota)
  static const Duration cacheDuration = Duration(minutes: 30);
  
  // Base URL for GNews API
  static const String _baseUrl = 'https://gnews.io/api/v4';
  
  // Getters
  List<NewsModel> get englishNews => _englishNewsCache;
  List<NewsModel> get hindiNews => _hindiNewsCache;
  
  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }
  
  /// Fetch English business news from India
  Future<List<NewsModel>> fetchEnglishNews({bool forceRefresh = false}) async {
    // Return cached data if still valid
    if (!forceRefresh && 
        _lastEnglishFetch != null && 
        DateTime.now().difference(_lastEnglishFetch!) < cacheDuration &&
        _englishNewsCache.isNotEmpty) {
      return _englishNewsCache;
    }
    
    if (!ApiKeys.isGNewsConfigured) {
      debugPrint('⚠️ GNews API key not configured');
      return _englishNewsCache;
    }
    
    if (isLoadingEnglish.value) return _englishNewsCache;
    
    try {
      isLoadingEnglish.value = true;
      
      final response = await _dio.get(
        '$_baseUrl/top-headlines',
        queryParameters: {
          'token': ApiKeys.gNewsApiKey,
          'category': 'business',
          'country': 'in',
          'lang': 'en',
          'max': 20,
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final articles = response.data['articles'] as List? ?? [];
        
        final newsItems = articles.map((article) => NewsModel(
          id: article['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: article['title'] ?? '',
          description: article['description'] ?? article['content'] ?? '',
          imageUrl: article['image'],
          sourceLink: article['url'],
          newsType: 'business',
          targetPlanIds: ['basic', 'premium'],
          publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
          createdAt: DateTime.now(),
        )).toList();
        
        _englishNewsCache.assignAll(newsItems);
        _lastEnglishFetch = DateTime.now();
        
        debugPrint('✅ Fetched ${newsItems.length} English news articles');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch English news: $e');
    } finally {
      isLoadingEnglish.value = false;
    }
    
    return _englishNewsCache;
  }
  
  /// Fetch Hindi business news from India
  Future<List<NewsModel>> fetchHindiNews({bool forceRefresh = false}) async {
    // Return cached data if still valid
    if (!forceRefresh && 
        _lastHindiFetch != null && 
        DateTime.now().difference(_lastHindiFetch!) < cacheDuration &&
        _hindiNewsCache.isNotEmpty) {
      return _hindiNewsCache;
    }
    
    if (!ApiKeys.isGNewsConfigured) {
      debugPrint('⚠️ GNews API key not configured');
      return _hindiNewsCache;
    }
    
    if (isLoadingHindi.value) return _hindiNewsCache;
    
    try {
      isLoadingHindi.value = true;
      
      final response = await _dio.get(
        '$_baseUrl/top-headlines',
        queryParameters: {
          'token': ApiKeys.gNewsApiKey,
          'category': 'business',
          'country': 'in',
          'lang': 'hi', // Hindi
          'max': 20,
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final articles = response.data['articles'] as List? ?? [];
        
        final newsItems = articles.map((article) => NewsModel(
          id: article['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: article['title'] ?? '',
          description: article['description'] ?? article['content'] ?? '',
          imageUrl: article['image'],
          sourceLink: article['url'],
          newsType: 'hindi',
          targetPlanIds: ['basic', 'premium'],
          publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
          createdAt: DateTime.now(),
        )).toList();
        
        _hindiNewsCache.assignAll(newsItems);
        _lastHindiFetch = DateTime.now();
        
        debugPrint('✅ Fetched ${newsItems.length} Hindi news articles');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch Hindi news: $e');
    } finally {
      isLoadingHindi.value = false;
    }
    
    return _hindiNewsCache;
  }
  
  /// Fetch both English and Hindi news
  Future<void> fetchAllNews({bool forceRefresh = false}) async {
    await Future.wait([
      fetchEnglishNews(forceRefresh: forceRefresh),
      fetchHindiNews(forceRefresh: forceRefresh),
    ]);
  }
}
