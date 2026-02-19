import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/services/google_sheets_service.dart';

/// Widget to display All India prices for a metal across different cities
class AllIndiaPricesWidget extends StatefulWidget {
  final String metalName;
  final Color accentColor;

  const AllIndiaPricesWidget({
    super.key,
    required this.metalName,
    required this.accentColor,
  });

  @override
  State<AllIndiaPricesWidget> createState() => _AllIndiaPricesWidgetState();
}

class _AllIndiaPricesWidgetState extends State<AllIndiaPricesWidget> {
  GoogleSheetsService? _sheetsService;
  List<CityRate> _cityRates = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      _sheetsService = Get.find<GoogleSheetsService>();
      final rates = _sheetsService!.getAllIndiaRatesForMetal(widget.metalName);
      setState(() {
        _cityRates = rates;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading All India rates: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: widget.accentColor),
      );
    }

    if (_cityRates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.public, color: widget.accentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All India Prices',
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_cityRates.length} cities',
                          style: TextStyles.caption.copyWith(
                            color: ColorConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: ColorConstants.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  ..._cityRates.map((rate) => _buildCityRow(rate)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCityRow(CityRate rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              rate.city.substring(0, 2).toUpperCase(),
              style: TextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.accentColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rate.city,
              style: TextStyles.bodyMedium,
            ),
          ),
          Text(
            '₹${rate.price.toStringAsFixed(0)}',
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '/${rate.unit.replaceAll('Rs/', '')}',
            style: TextStyles.caption.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
