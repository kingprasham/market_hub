import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class PriceAlertsPage extends StatefulWidget {
  const PriceAlertsPage({super.key});

  @override
  State<PriceAlertsPage> createState() => _PriceAlertsPageState();
}

class _PriceAlertsPageState extends State<PriceAlertsPage> {
  final List<Map<String, dynamic>> alerts = [
    {
      'metal': 'Copper Wire Bar',
      'location': 'Mumbai',
      'condition': 'Above',
      'targetPrice': 750.00,
      'currentPrice': 745.25,
      'isActive': true,
    },
    {
      'metal': 'Aluminium Ingot',
      'location': 'Delhi',
      'condition': 'Below',
      'targetPrice': 195.00,
      'currentPrice': 200.25,
      'isActive': true,
    },
    {
      'metal': 'Zinc HG',
      'location': 'All',
      'condition': 'Above',
      'targetPrice': 280.00,
      'currentPrice': 265.75,
      'isActive': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
        ),
        title: Text(
          'Price Alerts',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _showCreateAlertDialog,
            icon: const Icon(Icons.add, color: ColorConstants.primaryBlue),
          ),
        ],
      ),
      body: alerts.isEmpty ? _buildEmptyState() : _buildAlertsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAlertDialog,
        backgroundColor: ColorConstants.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('New Alert'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ColorConstants.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 50,
              color: ColorConstants.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Price Alerts',
            style: TextStyles.h5.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create alerts to get notified when\nprices reach your target',
            textAlign: TextAlign.center,
            style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert, index);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, int index) {
    final isAbove = alert['condition'] == 'Above';
    final isActive = alert['isActive'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: ColorConstants.primaryBlue.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isAbove ? ColorConstants.positiveGreen : ColorConstants.negativeRed).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAbove ? Icons.trending_up : Icons.trending_down,
                  color: isAbove ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['metal'],
                      style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert['location'],
                      style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (value) {
                  setState(() {
                    alerts[index]['isActive'] = value;
                  });
                },
                activeColor: ColorConstants.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert When',
                      style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isAbove ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: isAbove ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${alert['condition']} ₹${alert['targetPrice']}',
                          style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Price',
                      style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${alert['currentPrice']}',
                      style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    alerts.removeAt(index);
                  });
                  Get.snackbar(
                    'Deleted',
                    'Alert removed',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: const Icon(Icons.delete_outline, color: ColorConstants.negativeRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateAlertDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Create Price Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Metal',
                border: OutlineInputBorder(),
              ),
              items: ['Copper Wire Bar', 'Aluminium Ingot', 'Brass Sheet', 'Zinc HG']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items: ['Above', 'Below']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Target Price (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Alert Created',
                'You will be notified when price conditions are met',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryBlue,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
