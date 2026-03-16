import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/utils/formatters.dart';

class MetalDetailDialog extends StatelessWidget {
  final String title;
  final String? lastPrice;
  final String? high;
  final String? low;
  final String? change;
  final String? lastTrade;
  final bool isPositive;

  const MetalDetailDialog({
    super.key,
    required this.title,
    this.lastPrice,
    this.high,
    this.low,
    this.change,
    this.lastTrade,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _contentBox(context),
    );
  }

  Widget _contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildDetailRow('Last Price', lastPrice ?? '--', isBold: true),
          const SizedBox(height: 12),
          _buildDetailRow('High', high ?? '--', valueColor: ColorConstants.positiveGreen),
          const SizedBox(height: 12),
          _buildDetailRow('Low', low ?? '--', valueColor: ColorConstants.negativeRed),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Change',
            change ?? '--',
            valueColor: isPositive ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
            isBold: true,
          ),
          if (lastTrade != null && lastTrade!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: ColorConstants.textHint),
                const SizedBox(width: 8),
                Text(
                  'Last Trade: ${lastTrade ?? '--'}',
                  style: TextStyles.caption.copyWith(
                    color: ColorConstants.textHint,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodyMedium.copyWith(
            color: ColorConstants.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyles.bodyMedium.copyWith(
            color: valueColor ?? ColorConstants.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    String? lastPrice,
    String? high,
    String? low,
    String? change,
    String? lastTrade,
    bool isPositive = true,
  }) {
    showDialog(
      context: context,
      builder: (context) => MetalDetailDialog(
        title: title,
        lastPrice: lastPrice,
        high: high,
        low: low,
        change: change,
        lastTrade: lastTrade,
        isPositive: isPositive,
      ),
    );
  }
}
