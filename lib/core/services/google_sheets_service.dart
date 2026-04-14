import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/models/market/spot_bulletin_model.dart';
import '../../data/models/market/non_ferrous_sheet_data.dart';
import '../../data/models/content/update_model.dart';
import '../../data/models/market/ferrous_price_model.dart';
import '../../data/models/market/minor_price_model.dart';
import 'package:csv/csv.dart';

/// Service for fetching data from Google Sheets
/// Supports public sheets via CSV export or backend API
class GoogleSheetsService extends GetxService {
  final Dio _dio = Dio();

  // Cache for sheet data
  final _sheetsCache = <String, SheetData>{}.obs;

  // Cache for parsed spot bulletin
  final _spotBulletin = Rxn<SpotBulletinModel>();

  // Loading state
  final isLoading = false.obs;

  // News from Sheets
  final allIndiaNews = <UpdateModel>[].obs;

  // Ferrous Data
  final ferrousHeaders = <String>[].obs;
  final ferrousPrices = <String, List<FerrousPriceModel>>{}.obs;

  // Minor Data
  final minorSubCategories = <String>[].obs;
  final minorPrices = <String, List<MinorPriceModel>>{}.obs;

  // Non-Ferrous Data
  final nonFerrousData = Rxn<NonFerrousSheetData>();

  // Futures Data (LME Warehouse & Settlement)
  final lmeWarehouseData = <LmeWarehouseModel>[].obs;
  final warehouseDate = ''.obs;
  final settlementData = <SettlementModel>[].obs;

  // Timestamps from Apps Script
  final sheetTimestamps = <String, DateTime>{}.obs;
  DateTime? globalLastUpdated;

  // Last update time (used for cache management)
  // ignore: unused_field
  DateTime? _lastUpdate;

  // Auto-refresh timer
  Timer? _refreshTimer;

  // Refresh interval (15 seconds)
  static const int refreshIntervalSeconds = 15;

  // Your Google Sheet ID
  static const String defaultSheetId = '1BClDDU2oqGyhHyiDw0Kh1GZo8vcdKqNE2zq1gLkS0mw';
  static const String ferrousSheetId = '1MGL9LrQn0M3WiHZYWnuGNukgqglezk3zWkzak2OXwg4';
  
  // Minor Data Sheet
  // TODO: Replace with actual GID for "Sheet5" or "Minor and Ferro" tab
  static const String minorSheetId = '1sOs1Hp8aPf6VjpAg9vhpY_kjxgOAgtx0ue9HbDgmvmM';
  static const String minorSheetGid = '1353908069';

  // Non-Ferrous Data Sheet (FOR APP tab)
  static const String nonFerrousSheetId = '1VrCzC-sDcri5hO_TWfpHGx3ua7iaScLAtf-CFwQYBsI';
  static const String nonFerrousSheetGid = '365100361';

  // Sheet GIDs from the spreadsheet
  static const Map<String, String> sheetGids = {
    'DELHI': '0',
    'COPY': '1756865285',
    'PEST': '365963497',
    'OTHER_RATE': '638650819',
    'ALL_INDIA_MSG': '1389141339',
    'BME': '0', // Using DELHI sheet for BME data, update GID if there's a separate BME sheet
  };

  /// COPY sheet column mapping - exact column index to product configuration
  /// Based on the actual Excel structure: Row 1 = Headers, Row 2 = Current prices
  /// Column indices are 0-based (A=0, B=1, etc.)
  static const List<CopyColumnConfig> copyColumnMapping = [
    // Copper columns (A-J, indices 0-9)
    CopyColumnConfig(index: 0, header: 'BHATTHI (DELHI)', metal: 'Copper', subtype: 'Bhatti Scrap', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 1, header: 'PLANT (BHIWADI)', metal: 'Copper', subtype: 'Plant Scrap', city: 'Bhiwadi', isCash: true),
    CopyColumnConfig(index: 2, header: 'CC ROD+', metal: 'Copper', subtype: 'CC Rod', city: 'Delhi', isCash: true, pairedWith: 3),
    CopyColumnConfig(index: 3, header: 'CC ROD', metal: 'Copper', subtype: 'CC Rod', city: 'Delhi', isCash: false),
    CopyColumnConfig(index: 4, header: 'SUPER D+', metal: 'Copper', subtype: 'Super D', city: 'Delhi', isCash: true, pairedWith: 5),
    CopyColumnConfig(index: 5, header: 'SUPER D', metal: 'Copper', subtype: 'Super D', city: 'Delhi', isCash: false),
    CopyColumnConfig(index: 6, header: 'CCR+ (BHIWADI)', metal: 'Copper', subtype: 'CCR 8mm', city: 'Bhiwadi', isCash: true, pairedWith: 7),
    CopyColumnConfig(index: 7, header: 'CCR (DELHI)', metal: 'Copper', subtype: 'CCR 8mm', city: 'Delhi', isCash: false),
    CopyColumnConfig(index: 8, header: 'ZERO+', metal: 'Copper', subtype: 'Zero Grade', city: 'Delhi', isCash: true, pairedWith: 9),
    CopyColumnConfig(index: 9, header: 'ZERO', metal: 'Copper', subtype: 'Zero Grade', city: 'Delhi', isCash: false),
    // Brass columns (K-M, indices 10-12)
    CopyColumnConfig(index: 10, header: 'PURJA', metal: 'Brass', subtype: 'Purja', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 11, header: 'HONEY', metal: 'Brass', subtype: 'Honey', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 12, header: 'CHADRI', metal: 'Brass', subtype: 'Chadri', city: 'Delhi', isCash: true),
    // Aluminium columns (N-R, indices 13-17)
    CopyColumnConfig(index: 13, header: 'BARTAN', metal: 'Aluminium', subtype: 'Bartan', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 14, header: 'WIRE', metal: 'Aluminium', subtype: 'Wire Scrap', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 15, header: 'INGOT', metal: 'Aluminium', subtype: 'Company Ingot', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 16, header: 'ROD', metal: 'Aluminium', subtype: 'Company Rod', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 17, header: 'LOCAL ROD', metal: 'Aluminium', subtype: 'Local Rod', city: 'Delhi', isCash: true),
    // Lead columns (S-V, indices 18-21)
    CopyColumnConfig(index: 18, header: 'HARD/SOFT', metal: 'Lead', subtype: 'Hard/Soft', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 19, header: 'BLACK', metal: 'Lead', subtype: 'Black', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 20, header: 'WHITE', metal: 'Lead', subtype: 'White', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 21, header: 'PP', metal: 'Lead', subtype: 'PP Grade', city: 'Delhi', isCash: true),
    // Gun Metal columns (W-Y, indices 22-24)
    CopyColumnConfig(index: 22, header: 'LOCAL', metal: 'Gun Metal', subtype: 'Local', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 23, header: 'MIX', metal: 'Gun Metal', subtype: 'Mix', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 24, header: 'JALANDHAR', metal: 'Gun Metal', subtype: 'Jalandhar', city: 'Delhi', isCash: true),
    // Zinc columns (Z-AI, indices 25-34)
    CopyColumnConfig(index: 25, header: 'HZL', metal: 'Zinc', subtype: 'India HZL', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 26, header: 'IMP', metal: 'Zinc', subtype: 'Imported KZ', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 27, header: 'AZ', metal: 'Zinc', subtype: 'Australia', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 28, header: 'ZAMAK-3', metal: 'Zinc', subtype: 'Zamak-3', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 29, header: 'ZAMAK-5', metal: 'Zinc', subtype: 'Zamak-5', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 30, header: 'PMI', metal: 'Zinc', subtype: 'PMI', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 31, header: 'DROSS', metal: 'Zinc', subtype: 'Dross', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 32, header: 'TUKADI (BIG)', metal: 'Zinc', subtype: 'Tukadi (Big)', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 33, header: 'TUKADI (MIX)', metal: 'Zinc', subtype: 'Tukadi (Mix)', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 34, header: 'DIE CAST', metal: 'Zinc', subtype: 'Die Cast', city: 'Delhi', isCash: true),
    // Nickel columns (AJ-AK, indices 35-36)
    CopyColumnConfig(index: 35, header: 'RUSSIA', metal: 'Nickel', subtype: 'Russian Cathode', city: 'Delhi', isCash: true),
    CopyColumnConfig(index: 36, header: 'NORWAY', metal: 'Nickel', subtype: 'Norway Cathode', city: 'Delhi', isCash: true),
    // Tin column (AL, index 37)
    CopyColumnConfig(index: 37, header: 'INDONESIA', metal: 'Tin', subtype: 'Indonesia', city: 'Delhi', isCash: true),
  ];

  /// PEST sheet column mapping - exact column index to product name for historical data
  /// Column A = DATE (index 0), then product columns
  static const List<PestColumnConfig> pestColumnMapping = [
    // Skip column 0 (DATE)
    PestColumnConfig(index: 1, header: 'SCRAP+', metal: 'Copper', product: 'Copper Scrap (Cash)', displayName: 'Scrap+'),
    PestColumnConfig(index: 2, header: 'SCRAP', metal: 'Copper', product: 'Copper Scrap (Credit)', displayName: 'Scrap'),
    PestColumnConfig(index: 3, header: 'CCROD+', metal: 'Copper', product: 'Copper CC Rod (Cash)', displayName: 'CC Rod+'),
    PestColumnConfig(index: 4, header: 'CCROD', metal: 'Copper', product: 'Copper CC Rod (Credit)', displayName: 'CC Rod'),
    PestColumnConfig(index: 5, header: 'SUPER D', metal: 'Copper', product: 'Copper Super D', displayName: 'Super D'),
    PestColumnConfig(index: 6, header: 'CCR+', metal: 'Copper', product: 'Copper CCR 8mm (Cash)', displayName: 'CCR+'),
    PestColumnConfig(index: 7, header: 'CCR', metal: 'Copper', product: 'Copper CCR 8mm (Credit)', displayName: 'CCR'),
    PestColumnConfig(index: 8, header: 'ZERO', metal: 'Copper', product: 'Copper Zero Grade', displayName: 'Zero'),
    PestColumnConfig(index: 9, header: 'BHATTHI', metal: 'Copper', product: 'Copper Bhatti Scrap', displayName: 'Bhatti'),
    PestColumnConfig(index: 10, header: 'PLANT', metal: 'Copper', product: 'Copper Plant Scrap', displayName: 'Plant'),
    PestColumnConfig(index: 11, header: 'PURJA', metal: 'Brass', product: 'Brass Purja', displayName: 'Purja'),
    PestColumnConfig(index: 12, header: 'HONEY', metal: 'Brass', product: 'Brass Honey', displayName: 'Honey'),
    PestColumnConfig(index: 13, header: 'CHADRI', metal: 'Brass', product: 'Brass Chadri', displayName: 'Chadri'),
    PestColumnConfig(index: 14, header: 'BARTAN', metal: 'Aluminium', product: 'Aluminium Bartan', displayName: 'Bartan'),
    PestColumnConfig(index: 15, header: 'WIRE', metal: 'Aluminium', product: 'Aluminium Wire', displayName: 'Wire'),
    PestColumnConfig(index: 16, header: 'INGOT', metal: 'Aluminium', product: 'Aluminium Ingot', displayName: 'Ingot'),
    PestColumnConfig(index: 17, header: 'LOCAL', metal: 'Gun Metal', product: 'Gun Metal Local', displayName: 'Local'),
    PestColumnConfig(index: 18, header: 'MIX', metal: 'Gun Metal', product: 'Gun Metal Mix', displayName: 'Mix'),
    PestColumnConfig(index: 19, header: 'JALANDHAR', metal: 'Gun Metal', product: 'Gun Metal Jalandhar', displayName: 'Jalandhar'),
    PestColumnConfig(index: 20, header: 'HZL', metal: 'Zinc', product: 'Zinc HZL', displayName: 'HZL'),
    PestColumnConfig(index: 21, header: 'IMP', metal: 'Zinc', product: 'Zinc Imported', displayName: 'Imported'),
    PestColumnConfig(index: 22, header: 'AZ', metal: 'Zinc', product: 'Zinc Australia', displayName: 'AZ'),
    PestColumnConfig(index: 23, header: 'ZAMAK-3', metal: 'Zinc', product: 'Zinc Zamak-3', displayName: 'Zamak-3'),
    PestColumnConfig(index: 24, header: 'ZAMAK-5', metal: 'Zinc', product: 'Zinc Zamak-5', displayName: 'Zamak-5'),
    PestColumnConfig(index: 25, header: 'PMI', metal: 'Zinc', product: 'Zinc PMI', displayName: 'PMI'),
    PestColumnConfig(index: 26, header: 'DROSS', metal: 'Zinc', product: 'Zinc Dross', displayName: 'Dross'),
    PestColumnConfig(index: 27, header: 'TUKADI', metal: 'Zinc', product: 'Zinc Tukadi', displayName: 'Tukadi'),
    PestColumnConfig(index: 28, header: 'DIE CAST', metal: 'Zinc', product: 'Zinc Die Cast', displayName: 'Die Cast'),
    PestColumnConfig(index: 29, header: 'HARD', metal: 'Lead', product: 'Lead Hard', displayName: 'Hard'),
    PestColumnConfig(index: 30, header: 'SOFT', metal: 'Lead', product: 'Lead Soft', displayName: 'Soft'),
    PestColumnConfig(index: 31, header: 'BLACK', metal: 'Lead', product: 'Lead Black', displayName: 'Black'),
    PestColumnConfig(index: 32, header: 'WHITE', metal: 'Lead', product: 'Lead White', displayName: 'White'),
    PestColumnConfig(index: 33, header: 'PP', metal: 'Lead', product: 'Lead PP', displayName: 'PP'),
    PestColumnConfig(index: 34, header: 'RUSSIA', metal: 'Nickel', product: 'Nickel Russia', displayName: 'Russia'),
    PestColumnConfig(index: 35, header: 'NORWAY', metal: 'Nickel', product: 'Nickel Norway', displayName: 'Norway'),
    PestColumnConfig(index: 36, header: 'INDONESIA', metal: 'Tin', product: 'Tin Indonesia', displayName: 'Indonesia'),
  ];

  // Cache for specific data types
  final _otherRates = <String, List<CityRate>>{}.obs;
  final _allIndiaRates = <String, List<CityRate>>{}.obs;
  final _priceHistory = <String, List<PriceHistoryEntry>>{}.obs;
  final _bmeRates = <BmeRate>[].obs;

  // Getter for spot bulletin
  SpotBulletinModel? get spotBulletin => _spotBulletin.value;
  Rx<SpotBulletinModel?> get spotBulletinRx => _spotBulletin;

  // Getters for other data
  Map<String, List<CityRate>> get otherRates => _otherRates;
  Map<String, List<CityRate>> get allIndiaRates => _allIndiaRates;
  Map<String, List<PriceHistoryEntry>> get priceHistory => _priceHistory;
  List<BmeRate> get bmeRates => _bmeRates;
  RxList<BmeRate> get bmeRatesRx => _bmeRates;

  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    debugPrint('GoogleSheetsService: onInit - starting auto-initialization');
    initialize();
  }

  /// Initialize and start auto-refresh
  Future<void> initialize({String? sheetId, List<String>? sheetNames}) async {
    await fetchAllSheets(sheetId: sheetId, sheetNames: sheetNames);
    _startAutoRefresh(sheetId: sheetId, sheetNames: sheetNames);
  }

  void _startAutoRefresh({String? sheetId, List<String>? sheetNames}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(seconds: refreshIntervalSeconds),
      (_) => fetchAllSheets(sheetId: sheetId, sheetNames: sheetNames),
    );
  }

  /// Fetch all sheets from the Google Sheet
  Future<Map<String, SheetData>> fetchAllSheets({
    String? sheetId,
    List<String>? sheetNames,
  }) async {
    if (isLoading.value) return _sheetsCache;

    // Only show loading if we have NO cached sheets at all
    if (_sheetsCache.isEmpty) {
      isLoading.value = true;
    }

    final id = sheetId ?? defaultSheetId;

    try {
      // Fetch all sheets using their GIDs
      final sheetsToFetch = sheetNames ?? sheetGids.keys.toList();

      final futures = sheetsToFetch.map((name) {
        final gid = sheetGids[name];
        if (gid != null) {
          return _fetchSheetByGid(id, name, gid);
        }
        return _fetchSheet(id, name);
      });

      final results = await Future.wait(futures);

      for (int i = 0; i < sheetsToFetch.length; i++) {
        if (results[i] != null) {
          _sheetsCache[sheetsToFetch[i]] = results[i]!;
        }
      }

      // Parse specific sheets into structured data
      await _parseAllSheetData();

      _lastUpdate = DateTime.now();
      return _sheetsCache;
    } catch (e) {
      debugPrint('Error fetching sheets: $e');
      return _sheetsCache;
    } finally {
      isLoading.value = false;
    }
  }

  /// Parse all sheet data into structured formats
  Future<void> _parseAllSheetData() async {
    // Parse COPY sheet first (primary data source with structured format)
    _parseCopySheet();

    // Parse DELHI sheet for additional spot bulletin data
    await parseSpotBulletin(sheetName: 'DELHI');

    // Parse OTHER_RATE sheet for city-wise rates
    _parseOtherRates();

    // Parse ALL_INDIA_MSG sheet for all-India rates
    _parseAllIndiaRates();

    // Parse BME rates (Bullion/Gold/Silver) from OTHER_RATE or dedicated BME sheet
    _parseBmeRates();

    // Parse PEST sheet for price history (graphs)
    _parsePriceHistory();

    // Fetch and parse Ferrous data
    await fetchFerrousData();
    
    // Fetch and parse Non-Ferrous data
    await fetchNonFerrousData();

    // Fetch Timestamps
    await fetchTimestamps();

    // Fetch and parse Minor data
    await fetchMinorData();

    // Fetch Futures Data
    await fetchFuturesData();
  }

  /// Fetch a sheet by GID
  Future<SheetData?> _fetchSheetByGid(String sheetId, String sheetName, String gid) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Using /export?format=csv is often more reliable than gviz/tq for updates
      final csvUrl = 'https://docs.google.com/spreadsheets/d/$sheetId/export?format=csv&gid=$gid&t=$timestamp';
      debugPrint('Fetching sheet $sheetName matching gid $gid with timestamp $timestamp');

      final response = await _dio.get(
        csvUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final csvData = response.data.toString();
        debugPrint('Received ${csvData.length} chars for sheet $sheetName');

        return _parseCsvToSheetData(sheetName, csvData);
      } else {
        debugPrint('Failed to fetch sheet $sheetName: status=${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching sheet $sheetName (gid: $gid): $e');
    }
    return null;
  }

  /// Fetch a single sheet by name
  Future<SheetData?> _fetchSheet(String sheetId, String sheetName) async {
    try {
      final csvUrl = 'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&sheet=$sheetName';

      final response = await _dio.get(
        csvUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final csvData = response.data.toString();
        return _parseCsvToSheetData(sheetName, csvData);
      }
    } catch (e) {
      debugPrint('Error fetching sheet $sheetName via CSV: $e');

      // Try JSON export
      try {
        final jsonUrl = 'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:json&sheet=$sheetName';

        final response = await _dio.get(
          jsonUrl,
          options: Options(responseType: ResponseType.plain),
        );

        if (response.statusCode == 200 && response.data != null) {
          return _parseJsonToSheetData(sheetName, response.data.toString());
        }
      } catch (jsonError) {
        debugPrint('Error fetching sheet $sheetName via JSON: $jsonError');
      }
    }

    return null;
  }

  /// Parse CSV data to SheetData
  SheetData _parseCsvToSheetData(String sheetName, String csvData) {
    if (csvData.isEmpty) {
      return SheetData(name: sheetName, headers: [], rows: []);
    }

    final rows = <List<String>>[];
    var currentRow = <String>[];
    var currentCell = StringBuffer();
    var inQuotes = false;

    // Normalize line endings to \n
    final data = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    for (int i = 0; i < data.length; i++) {
      final char = data[i];

      if (char == '"') {
        if (inQuotes && i + 1 < data.length && data[i + 1] == '"') {
          // Double quote inside quotes means a literal quote
          currentCell.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
      } else if (char == '\n' && !inQuotes) {
        currentRow.add(currentCell.toString().trim());
        if (currentRow.any((cell) => cell.isNotEmpty)) {
          rows.add(List.from(currentRow));
        }
        currentRow.clear();
        currentCell.clear();
      } else {
        currentCell.write(char);
      }
    }

    // Add final row if not empty
    if (currentRow.isNotEmpty || currentCell.isNotEmpty) {
      if (currentCell.isNotEmpty) {
        currentRow.add(currentCell.toString().trim());
      }
      if (currentRow.any((cell) => cell.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    if (rows.isEmpty) {
      return SheetData(name: sheetName, headers: [], rows: []);
    }

    // First row is headers
    final headers = rows.removeAt(0);

    return SheetData(
      name: sheetName,
      headers: headers,
      rows: rows,
      lastUpdated: DateTime.now(),
    );
  }

  /// Parse Google Visualization API JSON response
  SheetData _parseJsonToSheetData(String sheetName, String jsonData) {
    try {
      final startIndex = jsonData.indexOf('{');
      final endIndex = jsonData.lastIndexOf('}') + 1;

      if (startIndex < 0 || endIndex <= startIndex) {
        return SheetData(name: sheetName, headers: [], rows: []);
      }

      final jsonString = jsonData.substring(startIndex, endIndex);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final table = json['table'] as Map<String, dynamic>?;
      if (table == null) {
        return SheetData(name: sheetName, headers: [], rows: []);
      }

      final cols = table['cols'] as List<dynamic>? ?? [];
      final headers = cols
          .map((col) => (col['label'] ?? '').toString())
          .toList();

      final rowsData = table['rows'] as List<dynamic>? ?? [];
      final rows = <List<String>>[];

      for (final row in rowsData) {
        final cells = (row['c'] as List<dynamic>?) ?? [];
        final rowValues = <String>[];

        for (final cell in cells) {
          if (cell == null) {
            rowValues.add('');
          } else {
            final value = cell['v'] ?? cell['f'] ?? '';
            rowValues.add(value.toString());
          }
        }

        rows.add(rowValues);
      }

      return SheetData(
        name: sheetName,
        headers: headers,
        rows: rows,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
      return SheetData(name: sheetName, headers: [], rows: []);
    }
  }

  /// Parse the COPY sheet which contains structured tabular data
  /// Uses exact column index mapping based on the actual Excel structure
  void _parseCopySheet() {
    final sheet = _sheetsCache['COPY'];
    if (sheet == null || sheet.isEmpty) {
      debugPrint('COPY sheet is empty or not loaded');
      return;
    }

    debugPrint('=== PARSING COPY SHEET ===');
    debugPrint('Headers count: ${sheet.headers.length}');
    debugPrint('Rows count: ${sheet.rows.length}');

    if (sheet.headers.isNotEmpty) {
      debugPrint('First 15 headers: ${sheet.headers.take(15).toList()}');
    }
    if (sheet.rows.isNotEmpty) {
      debugPrint('First row (first 15 values): ${sheet.rows[0].take(15).toList()}');
    }

    if (sheet.rows.isEmpty) return;

    // Get values from the first data row
    final values = sheet.rows[0];
    final headers = sheet.headers;

    // Group entries by metal
    final metalEntries = <String, List<MetalPriceEntry>>{};

    // First, try to find the actual column indices by matching headers
    final headerToIndex = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].trim().toUpperCase();
      if (header.isNotEmpty) {
        headerToIndex[header] = i;
      }
    }

    debugPrint('Header to index mapping (first 20): ${headerToIndex.entries.take(20).map((e) => '${e.key}:${e.value}').toList()}');

    // Process using header matching with fallback to index-based mapping
    for (final config in copyColumnMapping) {
      int colIndex = config.index;

      // Try to find by header name first (more reliable if columns are shifted)
      for (final entry in headerToIndex.entries) {
        if (_headerMatches(entry.key, config.header)) {
          colIndex = entry.value;
          break;
        }
      }

      if (colIndex < values.length) {
        final priceStr = values[colIndex].trim();
        final price = _parseSinglePrice(priceStr);

        if (price != null && price > 0) {
          debugPrint('  Found: ${config.header} (col $colIndex) -> ${config.metal} ${config.subtype} (${config.city}) = $price');

          // Find credit price if this is a cash column with a pair
          double? creditPrice;
          if (config.isCash && config.pairedWith != null && config.pairedWith! < values.length) {
            creditPrice = _parseSinglePrice(values[config.pairedWith!]);
          }

          metalEntries.putIfAbsent(config.metal, () => []);

          // For paired columns, create a single entry with both prices
          if (config.isCash) {
            final displaySubtype = config.subtype;
            metalEntries[config.metal]!.add(MetalPriceEntry(
              metalName: config.metal,
              subtype: displaySubtype,
              city: config.city,
              cashPrice: price,
              creditPrice: creditPrice,
              unit: 'Rs/Kg',
            ));
          } else if (config.pairedWith == null) {
            // This is a standalone credit column without a cash pair
            metalEntries[config.metal]!.add(MetalPriceEntry(
              metalName: config.metal,
              subtype: config.subtype,
              city: config.city,
              cashPrice: price,
              unit: 'Rs/Kg',
            ));
          }
          // Skip credit columns that are paired with cash columns
        }
      }
    }

    // Also try to extract any additional prices by scanning all headers
    _extractAdditionalPrices(headers, values, metalEntries);

    // Build metal sections
    final metalSections = <MetalSection>[];
    for (final entry in metalEntries.entries) {
      if (entry.value.isNotEmpty) {
        final uniqueSubtypes = entry.value.map((e) => e.subtype).toSet();
        metalSections.add(MetalSection(
          metalName: entry.key,
          subtypes: uniqueSubtypes.map((s) => MetalSubtype(name: s)).toList(),
          entries: entry.value,
        ));
      }
    }

    if (metalSections.isNotEmpty) {
      // Collect all unique cities
      final allCities = <String>{};
      for (final section in metalSections) {
        for (final entry in section.entries) {
          allCities.add(entry.city);
        }
      }

      final bulletin = SpotBulletinModel(
        bulletinDate: _formatDate(DateTime.now()),
        marketName: 'Delhi',
        metalSections: metalSections,
        cities: allCities.toList()..sort(),
      );
      _spotBulletin.value = bulletin;

      debugPrint('=== COPY SHEET PARSED SUCCESSFULLY ===');
      debugPrint('Total metal sections: ${metalSections.length}');
      for (final section in metalSections) {
        debugPrint('  ${section.metalName}: ${section.entries.length} entries');
        for (final entry in section.entries.take(3)) {
          debugPrint('    - ${entry.subtype}: ${entry.priceDisplay}');
        }
      }
    }
  }

  /// Check if a header matches the expected pattern
  bool _headerMatches(String actual, String expected) {
    final actualClean = actual.replaceAll(RegExp(r'[^A-Za-z0-9+]'), '').toUpperCase();
    final expectedClean = expected.replaceAll(RegExp(r'[^A-Za-z0-9+]'), '').toUpperCase();

    // Exact match
    if (actualClean == expectedClean) return true;

    // Contains match
    if (actualClean.contains(expectedClean) || expectedClean.contains(actualClean)) return true;

    // Special handling for common variations
    if (expected.contains('BHATTHI') && actual.contains('BHATT')) return true;
    if (expected.contains('CC ROD') && (actual.contains('CCROD') || actual.contains('CC ROD'))) return true;
    if (expected.contains('CCR') && actual.contains('CCR')) return true;

    return false;
  }

  /// Extract additional prices by scanning headers for known patterns
  void _extractAdditionalPrices(
    List<String> headers,
    List<String> values,
    Map<String, List<MetalPriceEntry>> metalEntries,
  ) {
    for (int i = 0; i < headers.length && i < values.length; i++) {
      final header = headers[i].trim().toUpperCase();
      if (header.isEmpty) continue;

      final price = _parseSinglePrice(values[i]);
      if (price == null || price <= 0) continue;

      // Check if we already have this entry
      bool alreadyProcessed = false;
      for (final config in copyColumnMapping) {
        if (_headerMatches(header, config.header)) {
          alreadyProcessed = true;
          break;
        }
      }
      if (alreadyProcessed) continue;

      // Try to identify metal and subtype from header
      final result = _identifyMetalFromHeader(header);
      if (result != null) {
        final metal = result['metal']!;
        final subtype = result['subtype']!;
        final city = result['city'] ?? 'Delhi';

        metalEntries.putIfAbsent(metal, () => []);

        // Avoid duplicates
        final exists = metalEntries[metal]!.any((e) =>
          e.subtype == subtype && e.city == city
        );

        if (!exists) {
          metalEntries[metal]!.add(MetalPriceEntry(
            metalName: metal,
            subtype: subtype,
            city: city,
            cashPrice: price,
            unit: 'Rs/Kg',
          ));
          debugPrint('  Additional: $header -> $metal $subtype ($city) = $price');
        }
      }
    }
  }

  /// Identify metal and subtype from a header string
  Map<String, String>? _identifyMetalFromHeader(String header) {
    final h = header.toLowerCase();

    // Copper patterns
    if (h.contains('arm') || h.contains('bhatti') || h.contains('scrap')) {
      return {'metal': 'Copper', 'subtype': 'Bhatti Scrap'};
    }
    if (h.contains('plant')) return {'metal': 'Copper', 'subtype': 'Plant Scrap', 'city': 'Bhiwadi'};

    // More patterns can be added as needed

    return null;
  }

  double? _parseSinglePrice(String priceStr) {
    if (priceStr.isEmpty) return null;

    final cleaned = priceStr
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('+', '')
        .replaceAll('Rs', '')
        .replaceAll('₹', '')
        .replaceAll('*', '')
        .replaceAll('"', '')
        .trim();

    // Handle formats like "1111+/1171" or "1111/1171"
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      return double.tryParse(parts[0].trim());
    }

    return double.tryParse(cleaned);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Parse the DELHI sheet into a structured SpotBulletinModel
  Future<SpotBulletinModel?> parseSpotBulletin({String sheetName = 'DELHI'}) async {
    final sheet = _sheetsCache[sheetName];
    if (sheet == null || sheet.isEmpty) {
      await fetchAllSheets(sheetNames: [sheetName]);
      final fetchedSheet = _sheetsCache[sheetName];
      if (fetchedSheet == null || fetchedSheet.isEmpty) {
        // Already parsed COPY sheet, return that
        return _spotBulletin.value;
      }
      return _parseDelhiSheet(fetchedSheet);
    }
    return _parseDelhiSheet(sheet);
  }

  SpotBulletinModel _parseDelhiSheet(SheetData sheet) {
    // If we already have data from COPY sheet, keep it
    final existingBulletin = _spotBulletin.value;
    if (existingBulletin != null && existingBulletin.metalSections.isNotEmpty) {
      debugPrint('=== DELHI SHEET: Using existing COPY data (${existingBulletin.metalSections.length} sections) ===');
      return existingBulletin;
    }

    debugPrint('=== PARSING DELHI SHEET with ${sheet.rows.length} rows ===');
    // DELHI sheet parsing fallback if COPY fails
    return SpotBulletinModel.empty();
  }

  /// Parse OTHER_RATE sheet into city-wise rates
  void _parseOtherRates() {
    final sheet = _sheetsCache['OTHER_RATE'];
    if (sheet == null || sheet.isEmpty) return;

    debugPrint('=== PARSING OTHER_RATE SHEET ===');
    debugPrint('Rows: ${sheet.rows.length}');

    final rates = <String, List<CityRate>>{};
    String? currentCity;

    for (final row in sheet.rows) {
      if (row.isEmpty) continue;

      final firstCell = row[0].trim().toUpperCase().replaceAll('*', '');

      // Check if this is a city header
      if (_isKnownCity(firstCell)) {
        currentCity = _capitalizeCity(firstCell);
        rates[currentCity] = [];
        debugPrint('  Found city: $currentCity');
        continue;
      }

      // Parse rate row
      if (currentCity != null && row.length >= 2) {
        final metalName = row[0].trim();
        final priceStr = row[1].trim();

        if (metalName.isNotEmpty && priceStr.isNotEmpty) {
          final price = _parseSinglePrice(priceStr);
          if (price != null && price > 0) {
            rates[currentCity]!.add(CityRate(
              city: currentCity,
              metalName: metalName,
              price: price,
              unit: 'Rs/Kg',
              lastUpdated: DateTime.now(),
            ));
          }
        }
      }
    }

    _otherRates.assignAll(rates);
    debugPrint('OTHER_RATE parsed: ${rates.length} cities');
    for (final entry in rates.entries) {
      debugPrint('  ${entry.key}: ${entry.value.length} rates');
    }
  }

  bool _isKnownCity(String cell) {
    final cities = [
      'delhi', 'mumbai', 'ahmedabad', 'kolkata', 'chennai', 'jaipur',
      'bhiwadi', 'pune', 'hyderabad', 'nagpur', 'jamnagar', 'bangalore',
      'ludhiana', 'jalandhar', 'indore', 'raipur', 'gurgaon', 'noida',
      'jodhpur', 'coimbatore', 'salem', 'bhandara', 'bilaspur', 'bhavnagar',
      'rajkot', 'surat', 'vadodara', 'lucknow', 'kanpur', 'patna',
    ];
    return cities.contains(cell.toLowerCase().replaceAll('*', '').trim());
  }

  String _capitalizeCity(String city) {
    if (city.isEmpty) return city;
    final cleaned = city.replaceAll('*', '').trim();
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }

  /// Parse ALL_INDIA_MSG sheet into all-India rates by metal
  /// Detects *METAL_NAME* pattern headers for section grouping
  void _parseAllIndiaRates() {
    final sheet = _sheetsCache['ALL_INDIA_MSG'];
    if (sheet == null || sheet.isEmpty) return;

    debugPrint('=== PARSING ALL_INDIA_MSG SHEET ===');
    debugPrint('Rows: ${sheet.rows.length}');

    final rates = <String, List<CityRate>>{};
    String? currentMetal;

    for (final row in sheet.rows) {
      if (row.isEmpty) continue;

      final firstCell = row[0].trim();
      
      // Check for *METAL_NAME* pattern (section headers)
      if (_isMetalSectionHeader(firstCell)) {
        currentMetal = _extractMetalName(firstCell);
        if (currentMetal != null) {
          rates[currentMetal] = [];
          debugPrint('  Found metal section: $currentMetal (from: $firstCell)');
        }
        continue;
      }
      
      // Parse rate row
      if (currentMetal != null && rates.containsKey(currentMetal)) {
        String cityOrType = firstCell;
        double? price;

        if (row.length >= 2) {
          price = _parseSinglePrice(row[1].toString().trim());
        }

        // Also check for comma-separated values in first cell
        if (price == null && firstCell.contains(',')) {
          final parts = firstCell.split(',');
          if (parts.length >= 2) {
            cityOrType = parts[0].trim();
            price = _parseSinglePrice(parts[1].trim());
          }
        }

        if (price != null && price > 0 && cityOrType.isNotEmpty) {
          // Don't add if it looks like another metal header
          if (!_isMetalSectionHeader(cityOrType) && !_isMetalName(cityOrType.replaceAll('*', ''))) {
            rates[currentMetal]!.add(CityRate(
              city: cityOrType,
              metalName: currentMetal!,
              price: price,
              unit: 'Rs/Kg',
              lastUpdated: DateTime.now(),
            ));
          }
        }
      }
    }

    _allIndiaRates.assignAll(rates);
    
    // Parse news items
    final newsItems = <UpdateModel>[];
    final now = DateTime.now();

    for (int i = 0; i < sheet.rows.length; i++) {
       final row = sheet.rows[i];
       if (row.isEmpty) continue;

       final text = row[0].trim();
       if (text.isEmpty) continue;
       
       // Skip if it looks like a rate row (contains numbers/prices)
       final hasDigits = text.contains(RegExp(r'[0-9]'));
       final isShort = text.length < 20;

       if (hasDigits && isShort) continue;

       if (text.length > 20 || !hasDigits) {
          newsItems.add(UpdateModel(
             id: 'news_${now.millisecondsSinceEpoch}_$i',
             title: 'Market Update',
             description: text,
             category: 'Market Update',
             timestamp: now,
             isImportant: text.contains('IMPORTANT') || text.contains('URGENT') || text.contains('*'),
          ));
       }
    }
    
    if (newsItems.isNotEmpty) {
      allIndiaNews.assignAll(newsItems);
    }
    
    debugPrint('ALL_INDIA_MSG parsed: ${rates.length} metals, ${newsItems.length} news items');
    for (final entry in rates.entries) {
      debugPrint('  ${entry.key}: ${entry.value.length} entries');
    }
  }

  /// Fetch and parse Ferrous data from new sheet
  Future<void> fetchFerrousData() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final csvUrl = 'https://docs.google.com/spreadsheets/d/$ferrousSheetId/export?format=csv&gid=1842451283&t=$timestamp';
      debugPrint('Fetching Ferrous data from: $csvUrl');

      final response = await _dio.get(
        csvUrl,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        _parseFerrousSheet(response.data.toString());
      }
    } catch (e) {
      debugPrint('Error fetching Ferrous data: $e');
    }
  }

  Future<void> fetchMinorData() async {
    try {
      if (minorSheetGid == '0') return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = 'https://docs.google.com/spreadsheets/d/$minorSheetId/export?format=csv&gid=$minorSheetGid&t=$timestamp';
      debugPrint('Fetching Minor data from: $url');
      
      final response = await _dio.get(url, options: Options(responseType: ResponseType.plain));
      
      if (response.statusCode == 200) {
        await _parseMinorSheet(response.data.toString());
      } else {
        debugPrint('Failed to fetch Minor data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching Minor data: $e');
    }
  }

  /// Fetch and parse Non-Ferrous data from "FOR APP" sheet
  Future<void> fetchNonFerrousData() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = 'https://docs.google.com/spreadsheets/d/$nonFerrousSheetId/export?format=csv&gid=$nonFerrousSheetGid&t=$timestamp';
      debugPrint('Fetching Non-Ferrous data from: $url');

      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200 && response.data != null) {
        final csvData = response.data.toString();
        final rows = const CsvToListConverter().convert(csvData);
        if (rows.isNotEmpty) {
          DateTime fetchedAt = DateTime.now();
          // Try to find a date string in the first few rows (A1-A5 or similar)
          for (int i = 0; i < 5 && i < rows.length; i++) {
            for (final cell in rows[i]) {
              final str = cell.toString().trim();
              if (_looksLikeDate(str)) {
                fetchedAt = _parseDate(str);
                debugPrint('Found Non-Ferrous sheet date: $fetchedAt');
                break;
              }
            }
          }

          final parsed = NonFerrousSheetData.fromCsv(rows, fetchedAt: fetchedAt);
          nonFerrousData.value = parsed;
          debugPrint('Non-Ferrous data loaded: ${parsed.cities.length} cities, ${parsed.delhiSections.length} Delhi sections');
          for (final city in parsed.cities) {
            debugPrint('  ${city.cityName}: ${city.allItems.length} items');
          }
        }
      } else {
        debugPrint('Failed to fetch Non-Ferrous data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching Non-Ferrous data: $e');
    }
  }

  Future<void> _parseMinorSheet(String csvData) async {
    try {
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
      if (rows.isEmpty) return;

      // Reset data
      minorSubCategories.clear();
      minorPrices.clear();
      
      debugPrint('=== PARSING MINOR SHEET ===');
      
      if (rows.length < 3) return; 

      final categoryRow = rows[0];
      final headerRow = rows[1];
      
      // Iterate columns and detect blocks
      for (int col = 0; col < categoryRow.length; col++) {
         String categoryName = categoryRow[col]?.toString().trim() ?? '';
         
         if (categoryName.isNotEmpty) {
             // Found a category block start
             // Check if enough columns exist
             if (col + 4 >= headerRow.length) continue;
             
             // Extract data for this category
             final categoryItems = <MinorPriceModel>[];
             
             for (int r = 2; r < rows.length; r++) {
                 final row = rows[r];
                 if (col >= row.length) continue;
                 
                 final item = row.length > col ? row[col]?.toString().trim() : '';
                 if (item == null || item.isEmpty) continue; 
                 
                 final quality = row.length > col + 1 ? row[col + 1]?.toString().trim() ?? '' : '';
                 final price = row.length > col + 2 ? row[col + 2]?.toString().trim() ?? '' : '';
                 final unit = row.length > col + 3 ? row[col + 3]?.toString().trim() ?? '' : '';
                 final date = row.length > col + 4 ? row[col + 4]?.toString().trim() ?? '' : '';
                 
                 if (price.isEmpty) continue; 
                 
                 categoryItems.add(MinorPriceModel(
                     category: categoryName,
                     item: item,
                     quality: quality,
                     price: price,
                     unit: unit,
                     date: date,
                     parsedDate: _parseDate(date),
                 ));
             }
             
             if (categoryItems.isNotEmpty) {
                 minorPrices[categoryName] = categoryItems;
                 minorSubCategories.add(categoryName);
             }
         }
      }
      
      debugPrint('Parsed Minor Categories: ${minorSubCategories.length}');
      minorSubCategories.refresh();
      minorPrices.refresh();

    } catch (e) {
      debugPrint('Error parsing Minor sheet: $e');
    }
  }

  void _parseFerrousSheet(String csvData) {
    debugPrint('=== PARSING FERROUS SHEET ===');
    final sheet = _parseCsvToSheetData('Ferrous', csvData);
    if (sheet.rows.isEmpty) return;

    // Headers are in Row 0 (implicitly handled by _parseCsvToSheetData creating headers from line 0)
    // But wait, _parseCsvToSheetData treats Row 0 as headers for the whole table.
    // In this sheet, headers are spanned or specific to blocks.
    // Let's re-examine row 0 from the raw csv or use sheet.headers if they aligned.
    
    // The sheet structure has headers like INGOT at index 0, BILLET at index 5, SCRAP at 9 etc.
    // Since _parseCsvToSheetData uses comma separation, empty cells between blocks will be empty strings in headers.
    
    final headers = sheet.headers; 
    // We need to identify block start indices
    final blockIndices = <String, int>{};
    
    for (int i = 0; i < headers.length; i++) {
        final header = headers[i].trim().toUpperCase();
        if (header.isNotEmpty && !['APP', 'WHATSAPP', 'STEEL TRADE'].contains(header)) {
            // Found a potential category header
            blockIndices[header] = i;
        }
    }
    
    // Some headers might be in the first row of data if the CSV parser took an empty row as headers?
    // Actually standard CSV export: Row 1 is headers.
    
    // Let's iterate and extract data
    final parsedData = <String, List<FerrousPriceModel>>{};
    final foundHeaders = <String>[];

    blockIndices.forEach((category, startIndex) {
        // Data for this block is in columns: startIndex (City), startIndex+1 (Price)
        // We iterate rows
        final prices = <FerrousPriceModel>[];
        
        for (final row in sheet.rows) {
            if (startIndex + 1 < row.length) {
                final city = row[startIndex].trim();
                final priceStr = row[startIndex + 1].trim();
                
                if (city.isNotEmpty && priceStr.isNotEmpty) {
                    final price = _parseSinglePrice(priceStr);
                    if (price != null) {
                        // Check if there's a date column (usually 5th column in the block)
                        DateTime lastUpdated = DateTime.now();
                        if (startIndex + 4 < row.length) {
                            final dateStr = row[startIndex + 4].trim();
                            if (_looksLikeDate(dateStr)) {
                                lastUpdated = _parseDate(dateStr);
                            }
                        }

                        prices.add(FerrousPriceModel(
                            category: category,
                            city: city,
                            price: price,
                            lastUpdated: lastUpdated,
                        ));
                    }
                }
            }
        }
        
        if (prices.isNotEmpty) {
             // Clean up category name (remove : etc)
             final cleanCategory = category.replaceAll(':', '').trim();
             parsedData[cleanCategory] = prices;
             foundHeaders.add(cleanCategory);
             debugPrint('  Found Ferrous Category: $cleanCategory (${prices.length} items)');
        }
    });
    
    ferrousPrices.assignAll(parsedData);
    ferrousHeaders.assignAll(foundHeaders);
  }



  /// Check if a cell contains a metal section header pattern like *BRASS*, *ZINC*, etc.
  bool _isMetalSectionHeader(String cell) {
    final trimmed = cell.trim();
    // Check for *METAL* pattern
    if (trimmed.startsWith('*') && trimmed.endsWith('*')) {
      final content = trimmed.replaceAll('*', '').trim();
      return _isMetalName(content);
    }
    // Also check for just metal names at start of sections
    return _isMetalName(trimmed.replaceAll('*', '').trim()) &&
           (trimmed.contains('*') || trimmed == trimmed.toUpperCase());
  }

  /// Extract metal name from a section header
  String? _extractMetalName(String cell) {
    final content = cell.replaceAll('*', '').trim();
    return _normalizeMetal(content);
  }

  bool _isMetalName(String cell) {
    final metals = ['brass', 'aluminium', 'aluminum', 'zinc', 'gun metal', 'gunmetal', 'copper', 'lead', 'nickel', 'tin', 'steel', 'stainless'];
    final lower = cell.toLowerCase().replaceAll('*', '').trim();
    return metals.any((m) => lower == m || lower.contains(m));
  }

  String? _normalizeMetal(String name) {
    final lower = name.toLowerCase().replaceAll('*', '').trim();
    if (lower.contains('copper')) return 'Copper';
    if (lower.contains('brass')) return 'Brass';
    if (lower.contains('aluminium') || lower.contains('aluminum')) return 'Aluminium';
    if (lower.contains('zinc')) return 'Zinc';
    if (lower.contains('lead')) return 'Lead';
    if (lower.contains('gun') || lower.contains('gunmetal')) return 'Gun Metal';
    if (lower.contains('nickel')) return 'Nickel';
    if (lower.contains('tin')) return 'Tin';
    if (lower.contains('steel') || lower.contains('stainless')) return 'Stainless Steel';
    if (_isMetalName(lower)) return name;
    return null;
  }

  /// Parse BME rates (Bullion - Gold/Silver) from OTHER_RATE sheet
  void _parseBmeRates() {
    final sheet = _sheetsCache['OTHER_RATE'];
    if (sheet == null || sheet.isEmpty) {
      debugPrint('⚠️  OTHER_RATE sheet not found or empty');
      return;
    }

    debugPrint('=== PARSING BME RATES FROM OTHER_RATE SHEET ===');
    debugPrint('Total rows: ${sheet.rows.length}');
    debugPrint('Headers count: ${sheet.headers.length}');
    if (sheet.headers.isNotEmpty) {
      debugPrint('Headers (first 10): ${sheet.headers.take(10).toList()}');
    }

    final rates = <BmeRate>[];
    DateTime lastUpdated = DateTime.now();

    // Try to find a date string in the first few rows
    for (int i = 0; i < 5 && i < sheet.rows.length; i++) {
      for (final cell in sheet.rows[i]) {
        final str = cell.toString().trim();
        if (_looksLikeDate(str)) {
          lastUpdated = _parseDate(str);
          debugPrint('Found BME sheet date: $lastUpdated');
          break;
        }
      }
    }

    // Try to identify city columns from headers
    final cityColumns = <String, List<int>>{}; // city -> list of column indices
    for (int i = 0; i < sheet.headers.length; i++) {
      final header = sheet.headers[i].trim().toUpperCase();

      // Check for city names in headers
      if (header.contains('MUMBAI') || header.contains('BOMBAY')) {
        cityColumns.putIfAbsent('Mumbai', () => []).add(i);
      } else if (header.contains('DELHI') || header.contains('NCR')) {
        cityColumns.putIfAbsent('Delhi', () => []).add(i);
      } else if (header.contains('AHMEDABAD') || header.contains('AMDAVAD')) {
        cityColumns.putIfAbsent('Ahmedabad', () => []).add(i);
      } else if (header.contains('KOLKATA') || header.contains('CALCUTTA')) {
        cityColumns.putIfAbsent('Kolkata', () => []).add(i);
      } else if (header.contains('CHENNAI') || header.contains('MADRAS')) {
        cityColumns.putIfAbsent('Chennai', () => []).add(i);
      } else if (header.contains('BHIWADI') || header.contains('BHIWANDI')) {
        cityColumns.putIfAbsent('Bhiwadi', () => []).add(i);
      } else if (header.contains('JAIPUR')) {
        cityColumns.putIfAbsent('Jaipur', () => []).add(i);
      }
    }

    debugPrint('City columns detected: ${cityColumns.keys.toList()}');

    // Look for BME/Bullion data in OTHER_RATE sheet
    for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;

      final productName = row.isNotEmpty ? row[0].trim() : '';
      final productLower = productName.toLowerCase();
      final productUpper = productName.toUpperCase();

      // Check if this is Gold or Silver (including Hindi names)
      if (productLower.contains('gold') || productLower.contains('सोना') ||
          productLower.contains('silver') || productLower.contains('चांदी') ||
          productUpper.contains('GOLD') || productUpper.contains('SILVER')) {

        debugPrint('  Found BME row at index $rowIndex: "$productName"');

        // Extract metal details
        String metalName = 'Gold';
        String purity = '999';

        // Determine metal type
        if (productLower.contains('silver') || productLower.contains('चांदी')) {
          metalName = 'Silver';
          purity = '999'; // Default for silver
        }

        // Extract purity from product name
        if (productLower.contains('916') || productName.contains('916')) {
          purity = '916';
        } else if (productLower.contains('995') || productName.contains('995')) {
          purity = '995';
        } else if (productLower.contains('999') || productName.contains('999')) {
          purity = '999';
        } else if (productLower.contains('22k') || productLower.contains('22 k')) {
          purity = '22K';
        } else if (productLower.contains('24k') || productLower.contains('24 k')) {
          purity = '24K';
        }

        debugPrint('    Metal: $metalName, Purity: $purity');

        // Parse prices using detected city columns
        if (cityColumns.isNotEmpty) {
          for (final cityEntry in cityColumns.entries) {
            final city = cityEntry.key;
            final columns = cityEntry.value;

            // Try all column indices for this city
            for (final colIdx in columns) {
              if (colIdx < row.length) {
                final priceStr = row[colIdx].trim();
                final price = _parseSinglePrice(priceStr);

                if (price != null && price > 0) {
                  final rate = BmeRate(
                    id: '${metalName.toLowerCase()}_${purity}_${city.toLowerCase()}_${lastUpdated.millisecondsSinceEpoch}_$rowIndex',
                    metalName: metalName,
                    purity: purity,
                    price: price,
                    unit: metalName == 'Silver' ? 'Rs/Kg' : 'Rs/10gm',
                    city: city,
                    change: 0.0,
                    changePercent: 0.0,
                    lastUpdated: lastUpdated,
                  );
                  rates.add(rate);
                  debugPrint('    ✅ $city: ₹$price ${rate.unit}');
                  break; // Use first valid price for this city
                }
              }
            }
          }
        } else {
          // Fallback: try columns 1, 2, 3 as Mumbai, Delhi, Ahmedabad
          final defaultCities = ['Mumbai', 'Delhi', 'Ahmedabad'];
          for (var cityIndex = 0; cityIndex < defaultCities.length && cityIndex + 1 < row.length; cityIndex++) {
            final priceStr = row[cityIndex + 1].trim();
            final price = _parseSinglePrice(priceStr);

            if (price != null && price > 0) {
              final city = defaultCities[cityIndex];
              final rate = BmeRate(
                id: '${metalName.toLowerCase()}_${purity}_${city.toLowerCase()}_${lastUpdated.millisecondsSinceEpoch}_$rowIndex',
                metalName: metalName,
                purity: purity,
                price: price,
                unit: metalName == 'Silver' ? 'Rs/Kg' : 'Rs/10gm',
                city: city,
                change: 0.0,
                changePercent: 0.0,
                lastUpdated: lastUpdated,
              );
              rates.add(rate);
              debugPrint('    ✅ $city: ₹$price ${rate.unit}');
            }
          }
        }
      }
    }

    // If no data found in OTHER_RATE, log warning
    if (rates.isEmpty) {
      debugPrint('⚠️  No BME data found in OTHER_RATE sheet');
    }

    _bmeRates.assignAll(rates);
    debugPrint('✅ BME rates parsed: ${rates.length} total rates');

    // Log summary by city and metal
    final byCityMetal = <String, int>{};
    for (final rate in rates) {
      final key = '${rate.city} ${rate.metalName}';
      byCityMetal[key] = (byCityMetal[key] ?? 0) + 1;
    }
    for (final entry in byCityMetal.entries) {
      debugPrint('  ${entry.key}: ${entry.value} rates');
    }
  }

  /// Parse PEST sheet for price history (time series data for graphs)
  /// Uses exact column mapping for reliable product identification
  void _parsePriceHistory() {
    final sheet = _sheetsCache['PEST'];
    if (sheet == null || sheet.isEmpty) return;

    debugPrint('=== PARSING PEST SHEET FOR PRICE HISTORY ===');
    debugPrint('Headers: ${sheet.headers.length}, Rows: ${sheet.rows.length}');

    if (sheet.headers.isNotEmpty) {
      debugPrint('PEST Headers (first 20): ${sheet.headers.take(20).toList()}');
    }

    final history = <String, List<PriceHistoryEntry>>{};

    // Build column mapping from headers
    final columnConfig = <int, PestColumnConfig>{};

    // First, try to match headers to our predefined config
    for (int i = 0; i < sheet.headers.length; i++) {
      final header = sheet.headers[i].trim().toUpperCase();
      if (header.isEmpty || header == 'DATE') continue;

      // Find matching config
      PestColumnConfig? matched;
      for (final config in pestColumnMapping) {
        if (_pestHeaderMatches(header, config.header)) {
          matched = config;
          break;
        }
      }

      if (matched != null) {
        columnConfig[i] = matched;
        debugPrint('  Mapped column $i ($header) -> ${matched.product}');
      } else {
        // Create a dynamic config for unmatched columns
        final dynamicConfig = _createDynamicPestConfig(header, i);
        if (dynamicConfig != null) {
          columnConfig[i] = dynamicConfig;
          debugPrint('  Dynamic column $i ($header) -> ${dynamicConfig.product}');
        }
      }
    }

    debugPrint('Total PEST columns mapped: ${columnConfig.length}');

    // Parse each row as a date entry
    int validDates = 0;
    for (final row in sheet.rows) {
      if (row.isEmpty) continue;

      final dateStr = row[0].trim();
      if (dateStr.isEmpty || !_looksLikeDate(dateStr)) continue;

      final date = _parseDate(dateStr);
      validDates++;

      // Parse prices for each mapped column
      for (final entry in columnConfig.entries) {
        final colIdx = entry.key;
        final config = entry.value;

        if (colIdx >= row.length) continue;

        final priceStr = row[colIdx].trim();
        final price = _parseSinglePrice(priceStr);

        if (price != null && price > 0) {
          history.putIfAbsent(config.product, () => []);
          history[config.product]!.add(PriceHistoryEntry(
            date: date,
            price: price,
            productName: config.product,
            metal: config.metal,
            displayName: config.displayName,
          ));
        }
      }
    }

    // Sort by date
    for (final key in history.keys) {
      history[key]!.sort((a, b) => a.date.compareTo(b.date));
    }

    _priceHistory.assignAll(history);
    debugPrint('PEST parsed: $validDates dates, ${history.length} products with history');
  }

  /// Fetch true timestamps from the _timestamps hidden sheet
  Future<void> fetchTimestamps() async {
    try {
      // It exists in the default/Non-Ferrous sheet
      final sheet = await _fetchSheet(nonFerrousSheetId, '_timestamps');
      if (sheet == null) return;

      final newTimestamps = <String, DateTime>{};

      // Try to parse global last updated from D2 (which is row index 0 in our data rows)
      final globalStr = sheet.getCell(0, 'Global Last Updated') ?? '';
      if (globalStr.isNotEmpty) {
        globalLastUpdated = _parseTimestampString(globalStr);
      }

      // Read all data rows (starting from index 0)
      for (int i = 0; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length >= 2) {
          final sheetName = row[0].trim();
          final timeStr = row[1].trim(); // Format: dd-MM-yyyy HH:mm:ss
          
          if (sheetName.isNotEmpty && timeStr.isNotEmpty) {
            final parsedTime = _parseTimestampString(timeStr);
            if (parsedTime != null) {
              newTimestamps[sheetName] = parsedTime;
            }
          }
        }
      }
      sheetTimestamps.assignAll(newTimestamps);
      debugPrint('Timestamps parsed: ${newTimestamps.length} sheets');

    } catch (e) {
      debugPrint('Error fetching timestamps: $e');
    }
  }

  DateTime? _parseTimestampString(String timeStr) {
    try {
      // Expected Format from Script: dd-MM-yyyy HH:mm:ss
      final parts = timeStr.trim().split(' ');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length == 3) {
          return DateTime(
            int.parse(dateParts[2]), // Y
            int.parse(dateParts[1]), // M
            int.parse(dateParts[0]), // D
            int.parse(timeParts[0]), // h
            int.parse(timeParts[1]), // m
            int.parse(timeParts[2]), // s
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Check if a PEST header matches expected pattern
  bool _pestHeaderMatches(String actual, String expected) {
    final a = actual.replaceAll(RegExp(r'[^A-Za-z0-9+]'), '').toUpperCase();
    final e = expected.replaceAll(RegExp(r'[^A-Za-z0-9+]'), '').toUpperCase();
    return a == e || a.contains(e) || e.contains(a);
  }

  /// Create a dynamic PEST config for unmatched headers
  PestColumnConfig? _createDynamicPestConfig(String header, int index) {
    final h = header.toLowerCase();

    String? metal;
    String displayName = header;

    // Try to identify metal from header
    if (h.contains('scrap') || h.contains('ccr') || h.contains('super') || h.contains('zero') ||
        h.contains('cc rod') || h.contains('bhatthi') || h.contains('plant')) {
      metal = 'Copper';
    } else if (h.contains('purja') || h.contains('honey') || h.contains('chadri')) {
      metal = 'Brass';
    } else if (h.contains('bartan') || h.contains('wire') || h.contains('ingot') ||
               (h.contains('rod') && !h.contains('cc'))) {
      metal = 'Aluminium';
    } else if (h.contains('hzl') || h.contains('imp') || h.contains('az') ||
               h.contains('zamak') || h.contains('pmi') || h.contains('dross') ||
               h.contains('tukadi') || h.contains('die')) {
      metal = 'Zinc';
    } else if (h.contains('lead') || h.contains('pp') || h.contains('batt') ||
               h.contains('hard') || h.contains('soft') || h.contains('black') || h.contains('white')) {
      metal = 'Lead';
    } else if (h.contains('russia') || h.contains('norway') || h.contains('jinchuan')) {
      metal = 'Nickel';
    } else if (h.contains('indo') || h.contains('indonesia') || h.contains('tin')) {
      metal = 'Tin';
    } else if (h.contains('local') || h.contains('mix') || h.contains('jalandhar')) {
      metal = 'Gun Metal';
    }

    if (metal != null) {
      return PestColumnConfig(
        index: index,
        header: header,
        metal: metal,
        product: '$metal $displayName',
        displayName: displayName,
      );
    }

    return null;
  }

  bool _looksLikeDate(String str) {
    // Check for date-like patterns
    return RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}').hasMatch(str) ||
           RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}').hasMatch(str);
  }

  DateTime _parseDate(String dateStr) {
    try {
      // First, try ISO 8601 format (standard)
      final isoResult = DateTime.tryParse(dateStr);
      if (isoResult != null) {
        return isoResult;
      }

      // Handle various formats
      // 2023-07-11 00:00:00 or 11/07/2023 or 11-07-23
      String cleanedDate = dateStr.trim();
      if (cleanedDate.contains(' ')) {
        cleanedDate = cleanedDate.split(' ')[0];
      }

      // Handle Google Sheets Date() format: Date(2025,9,10) where month is 0-indexed
      final dateMatch = RegExp(r'Date\((\d+),(\d+),(\d+)\)').firstMatch(cleanedDate);
      if (dateMatch != null) {
        final year = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!) + 1; // Add 1 because month is 0-indexed
        final day = int.parse(dateMatch.group(3)!);
        return DateTime(year, month, day);
      }

      final parts = cleanedDate.split(RegExp(r'[/\-\.]'));
      if (parts.length == 3) {
        int day, month, year;

        // Check if first part is a 4-digit year (YYYY-MM-DD or ISO format)
        if (parts[0].length == 4) {
          year = int.tryParse(parts[0]) ?? DateTime.now().year;
          month = int.tryParse(parts[1]) ?? 1;
          day = int.tryParse(parts[2]) ?? 1;
        } else {
          // Format is either DD-MM-YYYY or MM-DD-YYYY
          final first = int.tryParse(parts[0]) ?? 1;
          final second = int.tryParse(parts[1]) ?? 1;
          year = int.tryParse(parts[2]) ?? DateTime.now().year;
          if (year < 100) year += 2000;

          // Detect format based on values:
          // - If second > 12, it must be day, so format is MM-DD-YYYY
          // - If first > 12, it must be day, so format is DD-MM-YYYY
          // - Otherwise ambiguous, assume MM-DD-YYYY (American/Google Sheets format)
          if (second > 12) {
            // second is definitely day (>12), so first is month: MM-DD-YYYY
            month = first;
            day = second;
          } else if (first > 12) {
            // first is definitely day (>12), so second is month: DD-MM-YYYY
            day = first;
            month = second;
          } else {
            // Both <= 12, ambiguous - default to MM-DD-YYYY (American format)
            month = first;
            day = second;
          }
        }

        // Validate the values before creating DateTime
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year > 1900) {
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      // Silent failure - just return current date as fallback
    }
    return DateTime.now();
  }

  // ============ PUBLIC API METHODS ============

  /// Get data for a specific sheet
  SheetData? getSheet(String sheetName) => _sheetsCache[sheetName];

  /// Get all cached sheets
  Map<String, SheetData> get allSheets => _sheetsCache;

  /// Get sheet data as list of maps
  List<Map<String, String>> getSheetAsMaps(String sheetName) {
    final sheet = _sheetsCache[sheetName];
    if (sheet == null) return [];
    return sheet.toMapList();
  }

  /// Get all metal entries for a specific metal
  List<MetalPriceEntry> getMetalEntries(String metalName) {
    final bulletin = _spotBulletin.value;
    if (bulletin == null) return [];

    final section = bulletin.getMetalSection(metalName);
    return section?.entries ?? [];
  }

  /// Get entries for a specific metal and city
  List<MetalPriceEntry> getMetalEntriesForCity(String metalName, String city) {
    final entries = getMetalEntries(metalName);
    return entries.where((e) => e.city.toLowerCase() == city.toLowerCase()).toList();
  }

  /// Get all available cities
  List<String> getAvailableCities() {
    final bulletin = _spotBulletin.value;
    return bulletin?.cities ?? SpotMetalConfig.defaultCities;
  }

  /// Get all available metals
  List<String> getAvailableMetals() {
    final bulletin = _spotBulletin.value;
    return bulletin?.metalCategories ?? SpotMetalConfig.metals.map((m) => m.name).toList();
  }

  /// Get subtypes for a specific metal
  List<String> getMetalSubtypes(String metalName) {
    final bulletin = _spotBulletin.value;
    if (bulletin == null) {
      final metalInfo = SpotMetalConfig.getMetalInfo(metalName);
      return metalInfo?.subtypes ?? [];
    }
    final section = bulletin.getMetalSection(metalName);
    return section?.subtypeNames ?? [];
  }

  /// Get rates for a specific city from OTHER_RATE
  List<CityRate> getCityRates(String city) {
    return _otherRates[city] ?? [];
  }

  /// Get all cities with rates
  List<String> getCitiesWithRates() {
    return _otherRates.keys.toList();
  }

  /// Get all-India rates for a metal
  List<CityRate> getAllIndiaRatesForMetal(String metal) {
    // Try exact match first
    if (_allIndiaRates.containsKey(metal)) {
      return _allIndiaRates[metal]!;
    }
    // Try case-insensitive match
    for (final key in _allIndiaRates.keys) {
      if (key.toLowerCase() == metal.toLowerCase()) {
        return _allIndiaRates[key]!;
      }
    }
    return [];
  }

  /// Get price history for a product
  List<PriceHistoryEntry> getPriceHistory(String productName) {
    // Exact match first
    if (_priceHistory.containsKey(productName)) {
      return _priceHistory[productName]!;
    }
    // Try case-insensitive partial match
    for (final key in _priceHistory.keys) {
      if (key.toLowerCase() == productName.toLowerCase()) {
        return _priceHistory[key]!;
      }
    }
    return [];
  }

  /// Get price history for a specific metal
  List<PriceHistoryEntry> getPriceHistoryForMetal(String metalName) {
    final metalLower = metalName.toLowerCase();
    for (final entry in _priceHistory.entries) {
      // Check if the product belongs to this metal
      final productLower = entry.key.toLowerCase();
      if (productLower.startsWith(metalLower) ||
          (entry.value.isNotEmpty && entry.value.first.metal?.toLowerCase() == metalLower)) {
        return entry.value;
      }
    }
    return [];
  }

  /// Get price history for any product containing keyword
  List<PriceHistoryEntry> getPriceHistoryByKeyword(String keyword) {
    final keywordLower = keyword.toLowerCase();
    for (final entry in _priceHistory.entries) {
      if (entry.key.toLowerCase().contains(keywordLower)) {
        return entry.value;
      }
    }
    return [];
  }

  /// Get all products with price history
  List<String> getProductsWithHistory() {
    return _priceHistory.keys.toList();
  }

  /// Get all products with price history for a specific metal
  List<String> getProductsWithHistoryForMetal(String metalName) {
    final metalLower = metalName.toLowerCase();
    final matching = <String>[];

    for (final entry in _priceHistory.entries) {
      final productLower = entry.key.toLowerCase();
      // Check if product name starts with metal name or if the stored metal matches
      if (productLower.startsWith(metalLower) ||
          (entry.value.isNotEmpty && entry.value.first.metal?.toLowerCase() == metalLower)) {
        matching.add(entry.key);
      }
    }

    return matching;
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  // Futures Sheet (LME Warehouse & Settlement)
  static const String futuresSheetId = '1sOs1Hp8aPf6VjpAg9vhpY_kjxgOAgtx0ue9HbDgmvmM';
  static const String futuresSheetGid = '914913757';
  
  // Store C3M data separately or linked to symbol, accessible globally
  final lmeC3MData = <String, double>{}.obs;

  Future<void> fetchFuturesData() async {
    // Show loading to provide feedback during refreshes
    isLoading.value = true;
    try {
      // Parse the new sheet directly
      final sheet = await _fetchSheetByGid(futuresSheetId, 'FUTURES', futuresSheetGid);
      if (sheet == null) return;

      _parseLmeWarehouseData(sheet);
      _parseSettlementData(sheet);
    } catch (e) {
      debugPrint('Error fetching futures data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _parseLmeWarehouseData(SheetData sheet) {
      // Parse left side (Cols A-L, indices 0-11)
      final data = <LmeWarehouseModel>[];

      // Extract date from header rows
      // User confirmed: "in warehouse the k and l column one is the date, the n column date is for settlement"
      // Column K = index 10, Column L = index 11
      String? foundDate;
      final datePattern = RegExp(r'\d{1,2}[-./\\]\d{1,2}[-./\\]\d{2,4}');
      
      for (int i = 0; i < sheet.rows.length && i < 5; i++) {
        final row = sheet.rows[i];
        
        // Prioritize Column K (10) and L (11) as they are the Warehouse specific dates
        final indicesToCheck = [10, 11, 9, 12, 13]; // Search K, L then others
        for (final j in indicesToCheck) {
          if (j < row.length) {
            final cell = row[j].trim();
            final match = datePattern.firstMatch(cell);
            if (match != null) {
              foundDate = match.group(0) ?? cell;
              break;
            }
          }
        }
        if (foundDate != null) break;
      }
      
      if (foundDate != null) {
        warehouseDate.value = foundDate;
      }
      
      // Look for C3M data across ALL rows first (Column AA = index 26, Column AF = index 31)
      // Sheet structure: AA=Symbol, AB=Bid, AC=Ask, AD=Last, AE=Final, AF=C3M
      for (final row in sheet.rows) {
        if (row.length > 31) {
          final rightSymbol = row[26].trim().toUpperCase();
          if (rightSymbol.isNotEmpty && const ['CU', 'AL', 'ZN', 'PB', 'NI', 'SN', 'AA'].contains(rightSymbol)) {
            final c3mValue = _parseSinglePrice(row[31]) ?? 0.0;
            lmeC3MData[rightSymbol] = c3mValue;
          }
        }
      }
    // Find header row starting with SYMBOL (usually row 3, index 2)
    int startRow = -1;
    for (int i = 0; i < sheet.rows.length; i++) {
      if (sheet.rows[i].isNotEmpty && sheet.rows[i][0].trim().toUpperCase() == 'SYMBOL') {
        startRow = i + 1;
        break;
      }
    }

    if (startRow == -1) return;

    for (int i = startRow; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      
      final symbol = row[0].trim();
      
      // Stop or skip if not a valid symbol (e.g. CONMET, MARKET HUB, or empty)
      if (symbol.isEmpty || 
          symbol.contains('CONMET') || 
          symbol.contains('MARKET HUB') || 
          symbol == 'SYMBOL') {
        continue;
      }

      // Ensure row has enough columns (up to AE = index 30 for C3M)
      if (row.length < 12) continue;

      try {

        data.add(LmeWarehouseModel(
          symbol: symbol,
          last: _parseSinglePrice(row[1]) ?? 0.0,
          inStock: _parseSinglePrice(row[2]) ?? 0.0,
          outStock: _parseSinglePrice(row[3]) ?? 0.0,
          change: _parseSinglePrice(row[4]) ?? 0.0,
          chnPercent: row[5].trim(),
          cwr: _parseSinglePrice(row[6]) ?? 0.0,
          cwrChange: _parseSinglePrice(row[7]) ?? 0.0,
          cwrChnPercent: row[8].trim(),
          liveWr: _parseSinglePrice(row[9]) ?? 0.0,
          liveWrChange: _parseSinglePrice(row[10]) ?? 0.0,
          liveWrChnPercent: row[11].trim(),
        ));
      } catch (e) {
        debugPrint('Error parsing LME row $i: $e');
      }
    }
    
    lmeWarehouseData.assignAll(data);
  }

  void _parseSettlementData(SheetData sheet) {
    // Parse right side (Cols O-S, Indices 14-18)
    // Date may be in Col T (index 19) or Col N (index 13)
    final data = <SettlementModel>[];
    String blockDate = ''; // Shared date for the settlement block

    for (int i = 0; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.length < 15) continue; // Need at least up to O (index 14) for Metal

      final metal = row[14].trim();
      if (metal.isEmpty) continue;
      
      // Skip obvious headers or noise
      final metalUpper = metal.toUpperCase();
      if (metalUpper == 'SYMBOL' || metalUpper == 'METAL' || metalUpper == 'DATE' || 
          metalUpper.contains('SETTELMENT') || metalUpper.contains('MARKET HUB')) {
        continue;
      }

      // Check if it looks like a price in Col P
      final bidCash = row.length > 15 ? row[15].trim() : '';
      if (bidCash.isEmpty || bidCash.toUpperCase() == 'BID' || bidCash.toUpperCase() == 'CASH') {
        continue;
      }

      // Try to extract date from Col T (index 19), then Col N (index 13)
      String rowDate = '';
      if (row.length > 19 && row[19].trim().isNotEmpty) {
        rowDate = row[19].trim();
      } else if (row.length > 13 && row[13].trim().isNotEmpty) {
        final candidate = row[13].trim();
        // Only use it if it looks like a date (contains / or - or digit)
        if (candidate.contains('/') || candidate.contains('-') || RegExp(r'^\d').hasMatch(candidate)) {
          rowDate = candidate;
        }
      }
      
      // Track block-level date
      if (rowDate.isNotEmpty && blockDate.isEmpty) {
        blockDate = rowDate;
      }

      try {
        data.add(SettlementModel(
          date: rowDate.isNotEmpty ? rowDate : blockDate,
          metal: metal,
          bidCash: _parseSinglePrice(row[15]) ?? 0.0, // P
          askCash: row.length > 16 ? _parseSinglePrice(row[16]) ?? 0.0 : 0.0, // Q
          bid3M: row.length > 17 ? _parseSinglePrice(row[17]) ?? 0.0 : 0.0, // R
          ask3M: row.length > 18 ? _parseSinglePrice(row[18]) ?? 0.0 : 0.0, // S
        ));
      } catch (e) {
         debugPrint('Error parsing Settlement row $i: $e');
      }
    }

    // Sort according to user requested sequence
    final order = {
      'COPPER': 1,
      'TIN': 2,
      'LEAD': 3,
      'ZINC': 4,
      'ALUMINIUM': 5,
      'NICKEL': 6,
      'AL. ALLOY': 7,
      'NASAAC': 8,
      'COBALT': 9,
    };

    data.sort((a, b) {
      final aName = a.metal.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
      final bName = b.metal.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
      
      final aOrder = order[aName] ?? 99;
      final bOrder = order[bName] ?? 99;
      
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return aName.compareTo(bName);
    });

    settlementData.assignAll(data);

    // Derive CASH-3M spreads for the London LME tab.
    // Primary source is column Z/AE (already populated in _parseLmeWarehouseData).
    // This adds/overwrites from settlement data so the London tab stays populated
    // even when the sheet's far-right columns shift or are empty.
    const metalToSymbol = {
      'COPPER': 'CU',
      'ALUMINIUM': 'AL',
      'ZINC': 'ZN',
      'NICKEL': 'NI',
      'LEAD': 'PB',
      'TIN': 'SN',
      'AL. ALLOY': 'AA',
      'NASAAC': 'AA', // fallback alias
    };

    for (final model in data) {
      final key = model.metal.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
      final symbol = metalToSymbol[key];
      if (symbol == null) continue;
      // C3M is sourced exclusively from the Spread C3M section (column AF).
      // No fallback calculation — if not present, it shows as N/A in the app.
    }
  }


}

class LmeWarehouseModel {
  final String symbol;
  final double last;
  final double inStock;
  final double outStock;
  final double change;
  final String chnPercent;
  final double cwr;
  final double cwrChange;
  final String cwrChnPercent;
  final double liveWr;
  final double liveWrChange;
  final String liveWrChnPercent;

  LmeWarehouseModel({
    required this.symbol,
    required this.last,
    required this.inStock,
    required this.outStock,
    required this.change,
    required this.chnPercent,
    required this.cwr,
    required this.cwrChange,
    required this.cwrChnPercent,
    required this.liveWr,
    required this.liveWrChange,
    required this.liveWrChnPercent,
  });
}

class SettlementModel {
  final String date;
  final String metal;
  final double bidCash;
  final double askCash;
  final double bid3M;
  final double ask3M;

  SettlementModel({
    required this.date,
    required this.metal,
    required this.bidCash,
    required this.askCash,
    required this.bid3M,
    required this.ask3M,
  });
}

class SheetData {
  final String name;
  final List<String> headers;
  final List<List<String>> rows;
  final DateTime? lastUpdated;

  SheetData({
    required this.name,
    required this.headers,
    required this.rows,
    this.lastUpdated,
  });

  List<Map<String, String>> toMapList() {
    return rows.map((row) {
      final map = <String, String>{};
      for (int i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i];
      }
      return map;
    }).toList();
  }

  String? getCell(int rowIndex, String columnName) {
    if (rowIndex < 0 || rowIndex >= rows.length) return null;
    final columnIndex = headers.indexOf(columnName);
    if (columnIndex < 0 || columnIndex >= rows[rowIndex].length) return null;
    return rows[rowIndex][columnIndex];
  }

  int get rowCount => rows.length;
  int get columnCount => headers.length;
  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;

  @override
  String toString() => 'SheetData(name: $name, rows: ${rows.length}, cols: ${headers.length})';
}

class BmeRate {
  final String id;
  final String metalName;
  final String purity;
  final double price;
  final String unit;
  final String city;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;

  BmeRate({
    required this.id,
    required this.metalName,
    required this.purity,
    required this.price,
    required this.unit,
    required this.city,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });
}

/// Configuration for a COPY sheet column
class CopyColumnConfig {
  final int index;
  final String header;
  final String metal;
  final String subtype;
  final String city;
  final bool isCash;
  final int? pairedWith; // Index of the paired credit column

  const CopyColumnConfig({
    required this.index,
    required this.header,
    required this.metal,
    required this.subtype,
    required this.city,
    required this.isCash,
    this.pairedWith,
  });
}

/// Configuration for a PEST sheet column
class PestColumnConfig {
  final int index;
  final String header;
  final String metal;
  final String product;
  final String displayName;

  const PestColumnConfig({
    required this.index,
    required this.header,
    required this.metal,
    required this.product,
    required this.displayName,
  });
}


/// Represents a city-wise rate entry
class CityRate {
  final String city;
  final String metalName;
  final double price;
  final double? creditPrice;
  final String unit;
  final DateTime lastUpdated;

  CityRate({
    required this.city,
    required this.metalName,
    required this.price,
    this.creditPrice,
    required this.unit,
    required this.lastUpdated,
  });

  String get priceDisplay {
    if (creditPrice != null && creditPrice! > 0) {
      return '₹${price.toStringAsFixed(0)}/${creditPrice!.toStringAsFixed(0)}';
    }
    return '₹${price.toStringAsFixed(0)}';
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'metalName': metalName,
    'price': price,
    'creditPrice': creditPrice,
    'unit': unit,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

/// Represents a price history entry
class PriceHistoryEntry {
  final DateTime date;
  final double price;
  final String productName;
  final String? metal;
  final String? displayName;

  PriceHistoryEntry({
    required this.date,
    required this.price,
    required this.productName,
    this.metal,
    this.displayName,
  });

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'price': price,
    'productName': productName,
    'metal': metal,
    'displayName': displayName,
  };
}
