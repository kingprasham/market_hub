/// Models for Non-Ferrous spot price data parsed from the Google Sheet "FOR APP" tab.
/// The sheet has two sections:
///   Top (rows 1-29): City-based entries across columns (Delhi, Mumbai, Hyderabad, etc.)
///     Within each city, metal name headers (e.g. COPPER, BRASS) appear as rows with
///     a name but NO prices, followed by item rows with prices.
///   Bottom (rows 31+): Delhi-only metal sections (Brass, Gun Metal, Lead, Nickel, Aluminium, Zinc, Tin)

class NonFerrousSheetData {
  final List<CityData> cities;
  final List<DelhiMetalSection> delhiSections;
  final DateTime fetchedAt;

  const NonFerrousSheetData({
    required this.cities,
    required this.delhiSections,
    required this.fetchedAt,
  });

  /// Get list of city names (for filter pills)
  List<String> get cityNames => cities.map((c) => c.cityName).toList();

  /// Get data for a specific city
  CityData? getCityData(String cityName) {
    try {
      return cities.firstWhere(
        (c) => c.cityName.toUpperCase() == cityName.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse the CSV from the FOR APP sheet
  factory NonFerrousSheetData.fromCsv(List<List<dynamic>> rows, {DateTime? fetchedAt}) {
    if (rows.isEmpty) {
      return NonFerrousSheetData(
        cities: [],
        delhiSections: [],
        fetchedAt: fetchedAt ?? DateTime.now(),
      );
    }

    // ─── Column mapping based on sheet structure ───
    final cityConfigs = <_CityConfig>[
      _CityConfig('DELHI', nameCol: 0, price1Col: 1, price2Col: 2),
      _CityConfig('MUMBAI', nameCol: 4, price1Col: 5),
      _CityConfig('HYDERABAD', nameCol: 7, price1Col: 8),
      _CityConfig('AHMEDABAD', nameCol: 10, price1Col: 11),
      _CityConfig('PUNE', nameCol: 13, price1Col: 14),
      _CityConfig('CHENNAI', nameCol: 16, price1Col: 17),
      _CityConfig('JODHPUR', nameCol: 19, price1Col: 20),
      _CityConfig('KOLKATA', nameCol: 22, price1Col: 23),
      _CityConfig('JAMNAGAR', nameCol: 25, price1Col: 26),
      _CityConfig('JAGADHRI', nameCol: 28, price1Col: 29),
      _CityConfig('MORADABAD', nameCol: 30, price1Col: 31),
      _CityConfig('HATHRAS', nameCol: 32, price1Col: 33),
      _CityConfig('JALANDHAR', nameCol: 34, price1Col: 35),
    ];

    // Known metal section headers that appear within city columns
    final knownMetalHeaders = {
      'COPPER', 'BRASS', 'ALUMINIUM', 'GUN METAL', 'ZINC', 'STEEL',
      'NICKEL', 'TIN', 'LEAD', 'NICKEL CATHODE',
    };

    // Bottom section headers (Delhi-only expanded sections from row 31+)
    final bottomSectionHeaders = {
      'BRASS', 'GUN METAL', 'LEAD', 'NICKEL CATHODE', 'ALUMINIUM', 'ZINC', 'TIN',
    };

    // ─── Find where bottom section starts ───
    int bottomSectionStart = rows.length;
    for (int i = 25; i < rows.length; i++) {
      final row = rows[i];
      if (row.isNotEmpty) {
        final firstCell = _clean(row[0]);
        if (bottomSectionHeaders.contains(firstCell.toUpperCase()) && _isEmptyAfterCol3(row)) {
          bottomSectionStart = i;
          break;
        }
      }
    }

    // ─── Parse top section: city-based entries with section grouping ───
    // For each city, collect raw entries first, then group into sections
    final cityRawEntries = <String, List<_RawEntry>>{};
    for (final cfg in cityConfigs) {
      cityRawEntries[cfg.cityName] = [];
    }

    for (int i = 1; i < bottomSectionStart; i++) {
      final row = rows[i];
      for (final cfg in cityConfigs) {
        final rawName = _safeGet(row, cfg.nameCol);
        if (rawName.isEmpty) continue;

        final name = rawName;
        final p1 = _parsePrice(_safeGet(row, cfg.price1Col));
        final p2 = cfg.price2Col != null ? _parsePrice(_safeGet(row, cfg.price2Col!)) : null;

        // Determine if this is a header or a data row
        final cleanedName = _clean(name).toUpperCase();
        final isHeader = knownMetalHeaders.contains(cleanedName) && p1 == null && p2 == null;

        cityRawEntries[cfg.cityName]!.add(_RawEntry(
          name: name,
          price1: p1,
          price2: p2,
          isHeader: isHeader,
          price1Label: cfg.price2Col != null ? 'Buy' : 'Price',
          price2Label: cfg.price2Col != null ? 'Sell' : null,
        ));
      }
    }

    // Now group each city's raw entries into sections
    final cities = <CityData>[];
    for (final cfg in cityConfigs) {
      final rawEntries = cityRawEntries[cfg.cityName]!;
      if (rawEntries.isEmpty) continue;

      final sections = <CityMetalSection>[];
      String currentHeader = 'General'; // Default section if items appear before any header
      List<MetalItem> currentItems = [];

      for (final entry in rawEntries) {
        if (entry.isHeader) {
          // Save previous section if it has items
          if (currentItems.isNotEmpty) {
            sections.add(CityMetalSection(
              sectionName: _titleCase(currentHeader),
              items: List.from(currentItems),
            ));
          }
          currentHeader = _clean(entry.name);
          currentItems = [];
        } else if (entry.price1 != null || entry.price2 != null) {
          // Data row with at least one price
          currentItems.add(MetalItem(
            name: _clean(entry.name),
            price1: entry.price1,
            price2: entry.price2,
            price1Label: entry.price1Label,
            price2Label: entry.price2Label,
          ));
        }
        // Rows with a name but no prices and not a known header are sub-headers (e.g. "COPPER SCRAP (ARM)")
        // We include them as items with no prices — the UI can style them differently
        else {
          currentItems.add(MetalItem(
            name: _clean(entry.name),
            price1: null,
            price2: null,
            price1Label: entry.price1Label,
            price2Label: entry.price2Label,
            isSubHeader: true,
          ));
        }
      }
      // Save last section
      if (currentItems.isNotEmpty) {
        sections.add(CityMetalSection(
          sectionName: _titleCase(currentHeader),
          items: List.from(currentItems),
        ));
      }

      if (sections.isNotEmpty) {
        cities.add(CityData(cityName: cfg.cityName, sections: sections));
      }
    }

    // ─── Parse bottom section (rows 31+): Delhi-only metal sections ───
    final delhiSections = <DelhiMetalSection>[];
    String? currentSectionName;
    List<MetalItem> currentItems = [];

    for (int i = bottomSectionStart; i < rows.length; i++) {
      final row = rows[i];
      final firstCell = _clean(row.isNotEmpty ? row[0].toString() : '');

      if (firstCell.isEmpty) continue;

      if (bottomSectionHeaders.contains(firstCell.toUpperCase()) && _isEmptyAfterCol3(row)) {
        if (currentSectionName != null && currentItems.isNotEmpty) {
          delhiSections.add(DelhiMetalSection(
            sectionName: currentSectionName,
            items: List.from(currentItems),
          ));
        }
        currentSectionName = _titleCase(firstCell);
        currentItems = [];
      } else if (currentSectionName != null) {
        final name = firstCell;
        final p1 = _parsePrice(_safeGet(row, 1));
        final p2 = _parsePrice(_safeGet(row, 2));
        if (name.isNotEmpty && (p1 != null || p2 != null)) {
          currentItems.add(MetalItem(
            name: name,
            price1: p1,
            price2: p2,
            price1Label: 'Buy',
            price2Label: 'Sell',
          ));
        }
      }
    }

    if (currentSectionName != null && currentItems.isNotEmpty) {
      delhiSections.add(DelhiMetalSection(
        sectionName: currentSectionName,
        items: List.from(currentItems),
      ));
    }

    return NonFerrousSheetData(
      cities: cities,
      delhiSections: delhiSections,
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  // ─── Helpers ───

  static String _clean(dynamic val) {
    if (val == null) return '';
    return val.toString().replaceAll('*', '').replaceAll(':', '').trim();
  }

  static String _safeGet(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    final val = row[index]?.toString().trim() ?? '';
    return val;
  }

  static double? _parsePrice(String val) {
    if (val.isEmpty) return null;
    final cleaned = val.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static bool _isEmptyAfterCol3(List<dynamic> row) {
    for (int i = 4; i < row.length && i < 10; i++) {
      final val = row.length > i ? row[i]?.toString().trim() ?? '' : '';
      if (val.isNotEmpty) return false;
    }
    return true;
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// A section of metal items within a city (e.g. Copper section, Brass section)
class CityMetalSection {
  final String sectionName;
  final List<MetalItem> items;

  const CityMetalSection({required this.sectionName, required this.items});
}

/// Data for a single city — grouped into metal sections
class CityData {
  final String cityName;
  final List<CityMetalSection> sections;

  const CityData({required this.cityName, required this.sections});

  /// Flat list of all items across all sections
  List<MetalItem> get allItems =>
      sections.expand((s) => s.items).toList();
}

/// A single metal/product entry with 1 or 2 prices
class MetalItem {
  final String name;
  final double? price1;
  final double? price2;
  final String price1Label;
  final String? price2Label;
  final bool isSubHeader;
  final DateTime? lastUpdated;

  const MetalItem({
    required this.name,
    this.price1,
    this.price2,
    this.price1Label = 'Price',
    this.price2Label,
    this.isSubHeader = false,
    this.lastUpdated,
  });

  String get displayPrice1 => price1 != null ? '₹${price1!.toStringAsFixed(0)}' : '--';
  String get displayPrice2 => price2 != null ? '₹${price2!.toStringAsFixed(0)}' : '--';
}

/// A Delhi-only metal section (from bottom rows)
class DelhiMetalSection {
  final String sectionName;
  final List<MetalItem> items;

  const DelhiMetalSection({required this.sectionName, required this.items});
}

/// Internal: raw parsed entry before grouping
class _RawEntry {
  final String name;
  final double? price1;
  final double? price2;
  final bool isHeader;
  final String price1Label;
  final String? price2Label;

  const _RawEntry({
    required this.name,
    this.price1,
    this.price2,
    this.isHeader = false,
    this.price1Label = 'Price',
    this.price2Label,
  });
}

/// Internal config for column mapping
class _CityConfig {
  final String cityName;
  final int nameCol;
  final int price1Col;
  final int? price2Col;

  const _CityConfig(this.cityName, {required this.nameCol, required this.price1Col, this.price2Col});
}
