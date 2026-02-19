import 'package:intl/intl.dart';

class Formatters {
  // Currency Formatters
  static String formatPrice(double price, {String symbol = '\$', int decimals = 2}) {
    return '$symbol${price.toStringAsFixed(decimals)}';
  }

  static String formatIndianPrice(double price, {int decimals = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimals,
    );
    return formatter.format(price);
  }

  static String formatPriceWithCommas(double price, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'en_US');
    return formatter.format(price);
  }

  // Change Formatters
  static String formatChange(double change, {bool showSign = true}) {
    final sign = showSign ? (change >= 0 ? '+' : '') : '';
    return '$sign${change.toStringAsFixed(2)}';
  }

  static String formatChangePercent(double percent, {bool showSign = true}) {
    final sign = showSign ? (percent >= 0 ? '+' : '') : '';
    return '$sign${percent.toStringAsFixed(2)}%';
  }

  // Date Formatters
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  static String formatTimeShort(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateFull(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  // Phone Number Formatter
  static String formatPhoneNumber(String phone, {String countryCode = '+91'}) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '$countryCode ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    return phone;
  }

  // Volume/Quantity Formatter
  static String formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }

  // File Size Formatter
  static String formatFileSize(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }

  // Duration Formatter
  static String formatDuration(int days) {
    if (days == 30) return '1 Month';
    if (days == 90) return '3 Months';
    if (days == 180) return '6 Months';
    if (days == 365) return '1 Year';
    return '$days Days';
  }

  // Greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Truncate text
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Time ago formatter (alias for formatRelativeTime)
  static String timeAgo(DateTime dateTime) {
    return formatRelativeTime(dateTime);
  }

  // Format number with commas
  static String formatNumber(double number, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'en_US');
    return formatter.format(number);
  }

  // Format compact number (K, M, B)
  static String formatCompactNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  // Format currency
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format day of month (for calendar)
  static String formatDayOfMonth(DateTime date) {
    return DateFormat('d').format(date);
  }

  // Format month short (for calendar)
  static String formatMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }
}
