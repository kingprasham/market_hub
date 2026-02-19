import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/event_detail_controller.dart';

class EventDetailPage extends GetView<EventDetailController> {
  const EventDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
        ),
        title: Text(
          'Economic Event',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: controller.shareEvent,
            icon: const Icon(Icons.share_outlined, color: ColorConstants.textPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: ShimmerListLoader());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildEventDetails(),
              _buildEconomicData(),
              _buildDescription(),
              _buildSignificance(),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getImpactColor().withOpacity(0.1),
            _getImpactColor().withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country and Impact
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCountryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getCountryColor()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.countryCode,
                      style: TextStyles.bodySmall.copyWith(
                        color: _getCountryColor(),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildImpactBadge(),
            ],
          ),
          const SizedBox(height: 16),

          // Event Title
          Text(
            controller.eventItem.title,
            style: TextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Date and Time
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: ColorConstants.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                Formatters.formatDate(controller.eventItem.publishedAt),
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: ColorConstants.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${controller.eventItem.publishedAt.hour.toString().padLeft(2, '0')}:${controller.eventItem.publishedAt.minute.toString().padLeft(2, '0')}',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBadge() {
    final impact = controller.impact;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getImpactColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getImpactColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            impact == 'high' ? 3 : impact == 'medium' ? 2 : 1,
            (index) => Icon(
              Icons.show_chart,
              size: 14,
              color: _getImpactColor(),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            impact.toUpperCase(),
            style: TextStyles.caption.copyWith(
              color: _getImpactColor(),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: TextStyles.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Country', controller.country),
          _buildDetailRow('Category', 'Economic Indicator'),
          _buildDetailRow('Frequency', 'Monthly'),
          _buildDetailRow('Source', 'Official Statistics'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEconomicData() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Economic Data',
            style: TextStyles.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildDataCard('Previous', controller.previousValue, Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: _buildDataCard('Forecast', controller.forecastValue, ColorConstants.primaryBlue)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDataCard(
                  'Actual',
                  controller.actualValue,
                  controller.actualValue == 'Pending'
                      ? Colors.grey
                      : ColorConstants.positiveGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyles.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            controller.eventItem.description,
            style: TextStyles.bodyMedium.copyWith(
              height: 1.6,
              color: ColorConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignificance() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: ColorConstants.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Market Significance',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This economic indicator is closely watched by market participants as it provides insights into economic health and can influence monetary policy decisions. Higher-than-expected results typically strengthen the currency, while lower results may lead to weakness.',
            style: TextStyles.bodySmall.copyWith(
              height: 1.6,
              color: ColorConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Reminder Button - Icon only with tooltip
            Obx(() => Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: controller.isReminderSet.value
                      ? ColorConstants.primaryOrange
                      : ColorConstants.borderColor,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: controller.toggleReminder,
                icon: Icon(
                  controller.isReminderSet.value
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: controller.isReminderSet.value
                      ? ColorConstants.primaryOrange
                      : ColorConstants.textSecondary,
                ),
                tooltip: controller.isReminderSet.value ? 'Reminder Set' : 'Set Reminder',
              ),
            )),
            const SizedBox(width: 12),
            // Add to Calendar Button - Full width
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.addToCalendar,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Add to Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getImpactColor() {
    switch (controller.impact) {
      case 'high':
        return ColorConstants.negativeRed;
      case 'medium':
        return ColorConstants.primaryOrange;
      default:
        return Colors.grey;
    }
  }

  Color _getCountryColor() {
    switch (controller.countryCode) {
      case 'US':
        return Colors.blue;
      case 'CN':
        return Colors.red;
      case 'IN':
        return Colors.orange;
      case 'EU':
        return Colors.indigo;
      case 'GB':
        return Colors.purple;
      case 'JP':
        return Colors.pink;
      default:
        return ColorConstants.primaryBlue;
    }
  }
}
