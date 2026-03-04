import 'package:intl/intl.dart';

class ForexSheetData {
  final List<SbiTableRow> sbiRows;
  final List<RbiTableRow> rbiRows;
  final DateTime updatedAt;

  ForexSheetData({
    required this.sbiRows,
    required this.rbiRows,
    required this.updatedAt,
  });

  /// Month name lookup for manual parsing (case-insensitive)
  static final _monthMap = <String, int>{
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  factory ForexSheetData.fromCsv(List<List<dynamic>> csvData) {
    final sbiTableRows = <SbiTableRow>[];
    final rbiTableRows = <RbiTableRow>[];

    // SBI: A(0)=Date, B(1)=USD, C(2)=EUR, D(3)=GBP, E(4)=JPY
    // RBI: G(6)=Date, H(7)=USD, I(8)=GBP, J(9)=EUR, K(10)=JPY

    for (var i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      // Skip garbage rows (ads / footer text from the sheet)
      final firstCell = row[0].toString();
      if (_isGarbageRow(firstCell)) continue;

      // Parse SBI
      try {
        if (row.length > 4 && firstCell.isNotEmpty) {
          final date = _parseDate(firstCell);

          if (date != null) {
            final usd = _parseRate(row, 1);
            final eur = _parseRate(row, 2);
            final gbp = _parseRate(row, 3);
            final jpy = _parseRate(row, 4);

            if (usd != null && eur != null && gbp != null && jpy != null) {
              sbiTableRows.add(SbiTableRow(
                date: date,
                usd: usd,
                eur: eur,
                gbp: gbp,
                jpy: jpy,
              ));
            }
          }
        }
      } catch (_) {}

      // Parse RBI
      try {
        if (row.length > 10) {
          final rbiDateStr = row[6].toString();
          if (rbiDateStr.isNotEmpty && !_isGarbageRow(rbiDateStr)) {
            final date = _parseDate(rbiDateStr);

            if (date != null) {
              final usd = _parseRate(row, 7);
              final gbp = _parseRate(row, 8);
              final eur = _parseRate(row, 9);
              final jpy = _parseRate(row, 10);

              if (usd != null && gbp != null && eur != null && jpy != null) {
                rbiTableRows.add(RbiTableRow(
                  date: date,
                  usd: usd,
                  gbp: gbp,
                  eur: eur,
                  jpy: jpy,
                ));
              }
            }
          }
        }
      } catch (_) {}
    }

    return ForexSheetData(
      sbiRows: sbiTableRows,
      rbiRows: rbiTableRows,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if a cell value is garbage (ads / footer / header repetition)
  static bool _isGarbageRow(String val) {
    if (val.isEmpty) return true;
    final lower = val.toLowerCase();
    if (lower.contains('market hub')) return true;
    if (lower.contains('matod')) return true;
    if (lower.contains('e-mail')) return true;
    if (lower.contains('mobile:')) return true;
    if (lower.contains('website:')) return true;
    if (lower.contains('sponsored')) return true;
    if (lower.contains('premium quality')) return true;
    if (lower.startsWith('*')) return true;
    if (lower.startsWith('sbi tt sell date')) return true;
    if (lower.startsWith('date')) return true;
    return false;
  }

  static double? _parseRate(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    var val = row[index]?.toString().trim() ?? '';
    // Strip embedded junk like "*MARKET HUB*85.42"
    if (val.contains('*')) {
      final match = RegExp(r'[\d.]+').firstMatch(val);
      if (match != null) {
        val = match.group(0)!;
      } else {
        return null;
      }
    }
    val = val.replaceAll(',', '');
    if (val.isEmpty || val == '-' || val.toLowerCase() == '#ref!') return null;
    return double.tryParse(val);
  }

  /// Robust date parser that handles:
  /// - "d-MMM-yyyy"      e.g. "31-May-2025"
  /// - "dd-MMM-yyyy"     e.g. "01-Jan-2024"
  /// - "d-MMMM-yyyy"     e.g. "4-March-2026"
  /// - "dd-MMMM-yyyy"    e.g. "04-March-2026"
  /// - "yyyy-MM-dd"      e.g. "2025-05-31"
  /// - ISO 8601
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    var clean = dateStr.trim();

    // Skip header labels
    final lower = clean.toLowerCase();
    if (lower.startsWith('date') || lower.startsWith('sbi')) return null;

    // Try manual parsing: d-Month-yyyy (handles both "Mar" and "March")
    final parts = clean.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0].trim());
      final monthStr = parts[1].trim().toLowerCase();
      final year = int.tryParse(parts[2].trim());

      if (day != null && year != null && _monthMap.containsKey(monthStr)) {
        return DateTime(year, _monthMap[monthStr]!, day);
      }
    }

    // Fallback: ISO or other standard formats
    return DateTime.tryParse(clean);
  }
}

class SbiTableRow {
  final DateTime date;
  final double usd;
  final double eur;
  final double gbp;
  final double jpy;

  SbiTableRow({
    required this.date,
    required this.usd,
    required this.eur,
    required this.gbp,
    required this.jpy,
  });
}

class RbiTableRow {
  final DateTime date;
  final double usd;
  final double gbp;
  final double eur;
  final double jpy;

  RbiTableRow({
    required this.date,
    required this.usd,
    required this.gbp,
    required this.eur,
    required this.jpy,
  });
}
