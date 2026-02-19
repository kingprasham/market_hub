import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../data/market_update_data.dart';

class MarketReportDialog extends StatelessWidget {
  final MarketReport report;

  const MarketReportDialog({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorConstants.backgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ColorConstants.primaryBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: TextStyles.h6.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.subtitle,
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: report.cities.length + 1, // +1 for footer
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == report.cities.length) {
                  return _buildFooter();
                }
                return _buildCityCard(report.cities[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(CityRates city) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // City Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  city.cityName,
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryBlue,
                  ),
                ),
                if (city.subtitle != null)
                  Text(
                    city.subtitle!,
                    style: TextStyles.caption.copyWith(
                      color: ColorConstants.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          
          // Rates
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: city.rates.map((rate) => _buildRateRow(rate)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(RateItem rate) {
    // If value is empty, it's likely a sub-header (like "SCRAP (ARM)")
    final isHeader = rate.value.isEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              rate.label,
              style: isHeader 
                  ? TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)
                  : TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
            ),
          ),
          if (!isHeader)
            Expanded(
              flex: 2,
              child: Text(
                rate.value,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          report.disclaimer,
          style: TextStyles.caption.copyWith(
            color: ColorConstants.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstants.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorConstants.primaryOrange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, size: 16, color: ColorConstants.primaryOrange),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  report.contact,
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorConstants.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
