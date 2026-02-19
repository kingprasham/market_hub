import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/services/google_sheets_service.dart';

/// Price chart widget that displays historical price data from PEST sheet
class PriceChart extends StatefulWidget {
  final String metalName;
  final Color accentColor;
  final List<Color> gradientColors;

  const PriceChart({
    super.key,
    required this.metalName,
    required this.accentColor,
    required this.gradientColors,
  });

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  GoogleSheetsService? _sheetsService;
  List<PriceHistoryEntry> _priceHistory = [];
  bool _isLoading = true;
  String _selectedPeriod = '1M';
  String? _selectedProduct;
  List<String> _availableProducts = [];
  String? _errorMessage;

  final List<String> _periods = ['1W', '1M', '3M', '6M', '1Y', 'ALL'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metalName != widget.metalName) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _sheetsService = Get.find<GoogleSheetsService>();
      _findMatchingProducts();
      _loadPriceHistory();
    } catch (e) {
      debugPrint('Error loading sheets service: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load price data';
      });
    }
  }

  void _findMatchingProducts() {
    if (_sheetsService == null) return;

    // Use the new metal-specific method for better matching
    final matching = _sheetsService!.getProductsWithHistoryForMetal(widget.metalName);

    debugPrint('Finding products for metal: ${widget.metalName}');
    debugPrint('Matching products: $matching');

    // If no matches from metal-specific method, try keyword matching
    if (matching.isEmpty) {
      final allProducts = _sheetsService!.getProductsWithHistory();
      final metalLower = widget.metalName.toLowerCase();

      for (final product in allProducts) {
        if (_productMatchesMetal(product.toLowerCase(), metalLower)) {
          matching.add(product);
        }
      }
      debugPrint('Fallback matching products: $matching');
    }

    setState(() {
      _availableProducts = matching;
      if (matching.isNotEmpty) {
        _selectedProduct = _getBestMatchingProduct(matching, widget.metalName.toLowerCase());
        debugPrint('Selected product: $_selectedProduct');
      }
    });
  }

  /// Check if a product name matches a metal using keyword patterns
  bool _productMatchesMetal(String product, String metal) {
    final p = product.toLowerCase();
    switch (metal) {
      case 'copper':
        return p.contains('copper') || p.contains('scrap') || p.contains('ccr') ||
               p.contains('super') || p.contains('zero') || p.contains('cc rod') ||
               p.contains('bhatthi') || p.contains('bhatti') || p.contains('plant');
      case 'brass':
        return p.contains('brass') || p.contains('purja') || p.contains('honey') ||
               p.contains('chadri') || p.contains('bharat');
      case 'aluminium':
        return p.contains('aluminium') || p.contains('bartan') || p.contains('wire') ||
               p.contains('ingot') || (p.contains('rod') && !p.contains('cc'));
      case 'zinc':
        return p.contains('zinc') || p.contains('hzl') || p.contains('imp') ||
               p.contains('az') || p.contains('zamak') || p.contains('pmi') ||
               p.contains('dross') || p.contains('tukadi') || p.contains('die');
      case 'lead':
        return p.contains('lead') || p.contains('pp') || p.contains('batt') ||
               p.contains('hard') || p.contains('soft') || p.contains('black') ||
               p.contains('white');
      case 'nickel':
        return p.contains('nickel') || p.contains('russia') || p.contains('norway') ||
               p.contains('jinchuan');
      case 'tin':
        return p.contains('tin') || p.contains('indo') || p.contains('indonesia');
      case 'gun metal':
        return p.contains('gun metal') || p.contains('local') || p.contains('mix') ||
               p.contains('jalandhar');
      default:
        return p.contains(metal);
    }
  }

  /// Get the best matching product to show by default
  String _getBestMatchingProduct(List<String> products, String metal) {
    // Priority order for selecting the best product to show by default
    final priorityPatterns = {
      'copper': ['Scrap (Cash)', 'Scrap+', 'SCRAP+', 'CC Rod', 'CCROD'],
      'brass': ['Purja', 'PURJA', 'Honey', 'HONEY'],
      'aluminium': ['Bartan', 'BARTAN', 'Ingot', 'INGOT', 'Wire', 'WIRE'],
      'zinc': ['HZL', 'Imported', 'IMP', 'AZ'],
      'lead': ['PP', 'Hard', 'HARD', 'Soft', 'SOFT'],
      'gun metal': ['Local', 'LOCAL', 'Mix', 'MIX'],
      'nickel': ['Russia', 'RUSSIA', 'Norway', 'NORWAY'],
      'tin': ['Indonesia', 'INDONESIA', 'Indo', 'INDO'],
    };

    final patterns = priorityPatterns[metal] ?? [];
    for (final pattern in patterns) {
      for (final product in products) {
        if (product.toLowerCase().contains(pattern.toLowerCase())) {
          return product;
        }
      }
    }
    return products.first;
  }

  void _loadPriceHistory() {
    if (_sheetsService == null || _selectedProduct == null) {
      setState(() {
        _isLoading = false;
        if (_selectedProduct == null && _availableProducts.isEmpty) {
          _errorMessage = 'No historical data available for ${widget.metalName}';
        }
      });
      return;
    }

    var history = _sheetsService!.getPriceHistory(_selectedProduct!);

    debugPrint('Loading history for $_selectedProduct: ${history.length} entries');

    // Filter by period
    final now = DateTime.now();
    DateTime startDate;
    switch (_selectedPeriod) {
      case '1W':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '6M':
        startDate = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = DateTime(2020, 1, 1);
    }

    history = history.where((e) => e.date.isAfter(startDate)).toList();
    history.sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      _priceHistory = history;
      _isLoading = false;
      if (history.isEmpty) {
        _errorMessage = 'No data for selected period';
      } else {
        _errorMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_availableProducts.length > 1) _buildProductSelector(),
          _buildPeriodSelector(),
          const SizedBox(height: 8),
          _buildChartArea(),
          if (_priceHistory.isNotEmpty) _buildStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.show_chart, color: widget.accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price History',
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _getDisplayName(),
                  style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
            tooltip: 'Refresh data',
          ),
        ],
      ),
    );
  }

  /// Get a user-friendly display name for the selected product
  String _getDisplayName() {
    if (_selectedProduct == null) return widget.metalName;

    // If we have history entries with display names, use that
    if (_priceHistory.isNotEmpty && _priceHistory.first.displayName != null) {
      return '${widget.metalName} - ${_priceHistory.first.displayName}';
    }

    // Otherwise format the product name
    return _formatProductName(_selectedProduct!);
  }

  Widget _buildProductSelector() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableProducts.length,
        itemBuilder: (context, index) {
          final product = _availableProducts[index];
          final isSelected = product == _selectedProduct;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _formatProductName(product),
                style: TextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : ColorConstants.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: widget.accentColor,
              backgroundColor: Colors.grey.shade100,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedProduct = product;
                    _isLoading = true;
                  });
                  _loadPriceHistory();
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Format product name for display
  String _formatProductName(String name) {
    // Remove metal prefix if present
    String formatted = name;
    final metalLower = widget.metalName.toLowerCase();
    if (formatted.toLowerCase().startsWith(metalLower)) {
      formatted = formatted.substring(widget.metalName.length).trim();
    }

    // Clean up special characters
    formatted = formatted.replaceAll('+', ' (Cash)').replaceAll('-', ' ');

    // Remove empty result
    if (formatted.isEmpty) {
      formatted = name;
    }

    // Shorten long names
    if (formatted.length > 18) {
      return '${formatted.substring(0, 15)}...';
    }
    return formatted;
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
                _isLoading = true;
              });
              _loadPriceHistory();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? widget.accentColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                period,
                style: TextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : ColorConstants.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartArea() {
    if (_isLoading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: widget.accentColor),
      );
    }

    if (_priceHistory.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'No historical data available',
              style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _availableProducts.isEmpty
                  ? 'Price history data is not available for ${widget.metalName}'
                  : 'Try selecting a different period or product',
              style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: LineChart(_buildChartData()),
    );
  }

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _priceHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), _priceHistory[i].price));
    }

    // Calculate min/max for Y axis
    final prices = _priceHistory.map((e) => e.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final padding = (maxPrice - minPrice) * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxPrice - minPrice) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyles.caption.copyWith(
                  color: ColorConstants.textSecondary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _getXAxisInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _priceHistory.length) return const SizedBox();

              final date = _priceHistory[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('dd/MM').format(date),
                  style: TextStyles.caption.copyWith(
                    color: ColorConstants.textSecondary,
                    fontSize: 9,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (_priceHistory.length - 1).toDouble(),
      minY: minPrice - padding,
      maxY: maxPrice + padding,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: widget.accentColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: _priceHistory.length <= 30,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: widget.accentColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.accentColor.withOpacity(0.3),
                widget.accentColor.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= _priceHistory.length) return null;

              final entry = _priceHistory[index];
              return LineTooltipItem(
                '₹${entry.price.toStringAsFixed(0)}\n${DateFormat('dd MMM yyyy').format(entry.date)}',
                TextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  double _getXAxisInterval() {
    final count = _priceHistory.length;
    if (count <= 7) return 1;
    if (count <= 30) return (count / 6).roundToDouble();
    if (count <= 90) return (count / 8).roundToDouble();
    return (count / 10).roundToDouble();
  }

  Widget _buildStats() {
    final prices = _priceHistory.map((e) => e.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    final firstPrice = _priceHistory.first.price;
    final lastPrice = _priceHistory.last.price;
    final change = lastPrice - firstPrice;
    final changePercent = (change / firstPrice) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem('High', '₹${maxPrice.toStringAsFixed(0)}', Colors.green),
          _buildStatItem('Low', '₹${minPrice.toStringAsFixed(0)}', Colors.red),
          _buildStatItem('Avg', '₹${avgPrice.toStringAsFixed(0)}', Colors.blue),
          _buildStatItem(
            'Change',
            '${change >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
            change >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
