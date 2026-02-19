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
    
    // Support multiple date formats
    final formats = [
      DateFormat('d-MMM-yyyy'),
      DateFormat('dd-MMM-yyyy'),
      DateFormat('yyyy-MM-dd'),
    ];

    // Header index determination (optional, but let's stick to fixed indices based on user request)
    // SBI: A(0)=Date, B(1)=USD, C(2)=EUR, D(3)=GBP, E(4)=JPY
    // RBI: G(6)=Date, H(7)=USD, I(8)=GBP, J(9)=EUR, K(10)=JPY

    for (var i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      // Parse SBI
      try {
        if (row.length > 4 && row[0].toString().isNotEmpty) {
          final dateStr = row[0].toString();
          final date = _parseDate(dateStr, formats);
          
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
      } catch (e) {
        // Skip
      }

      // Parse RBI
      try {
        if (row.length > 10 && row[6].toString().isNotEmpty) {
          final dateStr = row[6].toString();
          final date = _parseDate(dateStr, formats);
          
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
      } catch (e) {
        // Skip
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
    if (val == null || val.isEmpty || val == '-' || val.toLowerCase() == '#ref!') return null;
    return double.tryParse(val);
  }

  static DateTime? _parseDate(String dateStr, List<DateFormat> formats) {
    if (dateStr.isEmpty) return null;
    
    // Clean string
    var clean = dateStr.trim();
    if (clean.startsWith('DATE:')) return null; // Skip header row if repeated
    
    for (final fmt in formats) {
      try {
        return fmt.parse(clean);
      } catch (e) {
        continue;
      }
    }
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
