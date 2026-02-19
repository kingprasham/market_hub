import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart';
import '../../data/models/content/news_model.dart';

/// RSS News Service - Fetches news from RSS feeds (unlimited, no API limits)
/// 
/// Sources:
/// - Livemint (Indian business news)
/// - MoneyControl (Financial news)  
/// - Economic Times (Business/Economy)
/// - Business Standard (Business news)
class RssNewsService extends GetxService {
  final Dio _dio = Dio();
  
  // RSS Feed URLs
  static const List<Map<String, String>> _rssFeeds = [
    {
      'name': 'Livemint',
      'url': 'https://www.livemint.com/rss/news',
    },
    {
      'name': 'MoneyControl',
      'url': 'https://www.moneycontrol.com/rss/latestnews.xml',
    },
    {
      'name': 'Economic Times',
      'url': 'https://economictimes.indiatimes.com/rssfeedstopstories.cms',
    },
    {
      'name': 'Business Standard',
      'url': 'https://www.business-standard.com/rss/latest.rss',
    },
  ];
  
  // Cached news
  final _newsCache = <NewsModel>[].obs;
  final isLoading = false.obs;
  
  // Last fetch time
  DateTime? _lastFetch;
  
  // Cache duration (5 minutes for RSS - much shorter since no rate limits)
  static const Duration cacheDuration = Duration(minutes: 5);
  
  // Getters
  List<NewsModel> get news => _newsCache;
  
  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    // Fetch news on init
    fetchNews();
  }
  
  /// Fetch news from all RSS feeds
  Future<List<NewsModel>> fetchNews({bool forceRefresh = false}) async {
    // Return cached data if still valid
    if (!forceRefresh && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < cacheDuration &&
        _newsCache.isNotEmpty) {
      return _newsCache;
    }
    
    if (isLoading.value) return _newsCache;
    
    isLoading.value = true;
    final allNews = <NewsModel>[];
    
    try {
      // Fetch from all RSS feeds in parallel
      final futures = _rssFeeds.map((feed) => _fetchFromFeed(
        feed['url']!,
        feed['name']!,
      ));
      
      final results = await Future.wait(futures);
      
      for (final feedNews in results) {
        allNews.addAll(feedNews);
      }
      
      // Sort by date (newest first)
      allNews.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      // Remove duplicates by title similarity
      final uniqueNews = _removeDuplicates(allNews);
      
      _newsCache.assignAll(uniqueNews);
      _lastFetch = DateTime.now();
      
      debugPrint('✅ Fetched ${uniqueNews.length} news articles from RSS feeds');
    } catch (e) {
      debugPrint('❌ Failed to fetch RSS news: $e');
    } finally {
      isLoading.value = false;
    }
    
    return _newsCache;
  }
  
  /// Fetch news from a single RSS feed
  Future<List<NewsModel>> _fetchFromFeed(String url, String sourceName) async {
    final newsItems = <NewsModel>[];
    
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final xmlDoc = XmlDocument.parse(response.data.toString());
        
        // Find all item elements (works for both RSS 2.0 and Atom)
        final items = xmlDoc.findAllElements('item');
        
        for (final item in items.take(15)) { // Take first 15 from each source
          try {
            final title = _getElementText(item, 'title');
            final description = _getElementText(item, 'description') ?? 
                               _getElementText(item, 'content:encoded') ?? '';
            final link = _getElementText(item, 'link');
            final pubDate = _getElementText(item, 'pubDate');
            final imageUrl = _extractImageUrl(item);
            
            if (title != null && title.isNotEmpty) {
              newsItems.add(NewsModel(
                id: link ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: _cleanHtml(title),
                description: _cleanHtml(description),
                imageUrl: imageUrl,
                sourceLink: link,
                newsType: 'business',
                targetPlanIds: ['basic', 'premium'],
                publishedAt: _parseDate(pubDate),
                createdAt: DateTime.now(),
                sourceName: sourceName,
              ));
            }
          } catch (e) {
            // Skip malformed items
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch from $sourceName: $e');
    }
    
    return newsItems;
  }
  
  /// Get text content from an XML element
  String? _getElementText(XmlElement parent, String elementName) {
    final elements = parent.findElements(elementName);
    if (elements.isNotEmpty) {
      return elements.first.innerText.trim();
    }
    return null;
  }
  
  /// Extract image URL from item (checks multiple common RSS image formats)
  String? _extractImageUrl(XmlElement item) {
    // Check for media:content
    final mediaContent = item.findElements('media:content');
    if (mediaContent.isNotEmpty) {
      return mediaContent.first.getAttribute('url');
    }
    
    // Check for media:thumbnail
    final mediaThumbnail = item.findElements('media:thumbnail');
    if (mediaThumbnail.isNotEmpty) {
      return mediaThumbnail.first.getAttribute('url');
    }
    
    // Check for enclosure
    final enclosure = item.findElements('enclosure');
    if (enclosure.isNotEmpty) {
      final type = enclosure.first.getAttribute('type');
      if (type != null && type.startsWith('image/')) {
        return enclosure.first.getAttribute('url');
      }
    }
    
    // Try to extract image from description/content HTML
    final description = _getElementText(item, 'description') ?? '';
    final imgMatch = RegExp(r'<img[^>]+src=["'']([^"'']+)["'']').firstMatch(description);
    if (imgMatch != null && imgMatch.groupCount >= 1) {
      return imgMatch.group(1);
    }
    
    return null;
  }
  
  /// Parse date from various RSS date formats
  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }
    
    try {
      // Try standard RFC 822 format (common in RSS)
      return _parseRfc822Date(dateStr);
    } catch (e) {
      try {
        // Try ISO 8601 format
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }
  }
  
  /// Parse RFC 822 date format
  DateTime _parseRfc822Date(String dateStr) {
    // Examples:
    // "Thu, 02 Jan 2025 10:30:00 +0530"
    // "Thu, 02 Jan 2025 10:30:00 GMT"
    
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    
    final parts = dateStr.replaceAll(',', '').split(RegExp(r'\s+'));
    
    if (parts.length >= 5) {
      final day = int.tryParse(parts[1]) ?? 1;
      final month = months[parts[2]] ?? 1;
      final year = int.tryParse(parts[3]) ?? DateTime.now().year;
      final timeParts = parts[4].split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
      final second = int.tryParse(timeParts.length > 2 ? timeParts[2] : '0') ?? 0;
      
      return DateTime(year, month, day, hour, minute, second);
    }
    
    return DateTime.now();
  }
  
  /// Clean HTML tags and entities from text
  String _cleanHtml(String text) {
    // Remove HTML tags
    var cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode common HTML entities
    cleaned = cleaned
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&hellip;', '...')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–');
    
    // Clean up whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }
  
  /// Remove duplicate news items based on title similarity
  List<NewsModel> _removeDuplicates(List<NewsModel> items) {
    final seen = <String>{};
    final unique = <NewsModel>[];
    
    for (final item in items) {
      // Normalize title for comparison
      final normalizedTitle = item.title.toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      // Use first 50 chars for comparison
      final key = normalizedTitle.length > 50 
          ? normalizedTitle.substring(0, 50) 
          : normalizedTitle;
      
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(item);
      }
    }
    
    return unique;
  }
  
  /// Force refresh news
  Future<List<NewsModel>> refreshNews() async {
    return fetchNews(forceRefresh: true);
  }
}
