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

  factory ForexSheetData.fromCsv(List<List<dynamic>> csvData) {
    final sbiTableRows = <SbiTableRow>[];
    final rbiTableRows = <RbiTableRow>[];
    
    final dateFormat = DateFormat('d-MMMM-yyyy');

    // Header is at index 0. Data starts at index 1.
    for (var i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      // Parse SBI (Col A=Date, C=USD, E=EUR, G=GBP, I=JPY)
      // Indices: 0, 2, 4, 6, 8
      try {
        if (row.length > 8 && row[0].toString().isNotEmpty) {
          final dateStr = row[0].toString();
          final date = _parseDate(dateStr, dateFormat);
          
          if (date != null) {
            final usd = _parseRate(row, 2);
            final eur = _parseRate(row, 4);
            final gbp = _parseRate(row, 6);
            final jpy = _parseRate(row, 8);

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
      } catch (e) {
        // Skip invalid rows
      }

      // Parse RBI (Col K=Date, L=USD, M=GBP, N=EUR, O=JPY)
      // Indices: 10, 11, 12, 13, 14
      try {
        if (row.length > 14 && row[10].toString().isNotEmpty) {
          final dateStr = row[10].toString();
          final date = _parseDate(dateStr, dateFormat);
          
          if (date != null) {
            final usd = _parseRate(row, 11);
            final gbp = _parseRate(row, 12);
            final eur = _parseRate(row, 13);
            final jpy = _parseRate(row, 14);

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
      } catch (e) {
        // Skip invalid rows
      }
    }

    return ForexSheetData(
      sbiRows: sbiTableRows,
      rbiRows: rbiTableRows,
      updatedAt: DateTime.now(),
    );
  }

  static double? _parseRate(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final val = row[index]?.toString().replaceAll(',', '').trim();
    if (val == null || val.isEmpty) return null;
    return double.tryParse(val);
  }

  static DateTime? _parseDate(String dateStr, DateFormat format) {
    try {
      return format.parse(dateStr);
    } catch (e) {
      return DateTime.tryParse(dateStr);
    }
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
