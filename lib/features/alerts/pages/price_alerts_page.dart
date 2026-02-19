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
  final List<PriceAlert> _alerts = [
    PriceAlert(id: '1', metal: 'Copper', condition: 'Above', price: 9500.00, isActive: true),
    PriceAlert(id: '2', metal: 'Aluminium', condition: 'Below', price: 2600.00, isActive: true),
    PriceAlert(id: '3', metal: 'Gold', condition: 'Above', price: 2700.00, isActive: false),
    PriceAlert(id: '4', metal: 'USD/INR', condition: 'Above', price: 84.00, isActive: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Price Alerts',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: ColorConstants.primaryBlue),
            onPressed: _showAddAlertDialog,
          ),
        ],
      ),
      body: _alerts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) => _buildAlertCard(_alerts[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAlertDialog,
        backgroundColor: ColorConstants.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Alert', style: TextStyles.buttonTextSecondary.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: ColorConstants.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Price Alerts', style: TextStyles.h6.copyWith(color: ColorConstants.textSecondary)),
          const SizedBox(height: 8),
          Text('Tap + to create your first alert', style: TextStyles.bodySmall.copyWith(color: ColorConstants.textHint)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(PriceAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: alert.isActive
            ? Border.all(color: ColorConstants.primaryBlue.withOpacity(0.3))
            : null,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: alert.condition == 'Above'
                        ? ColorConstants.positiveGreen.withOpacity(0.1)
                        : ColorConstants.negativeRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alert.condition == 'Above' ? Icons.trending_up : Icons.trending_down,
                    color: alert.condition == 'Above'
                        ? ColorConstants.positiveGreen
                        : ColorConstants.negativeRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.metal,
                        style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alert.condition} \$${alert.price.toStringAsFixed(2)}',
                        style: TextStyles.bodySmall.copyWith(color: ColorConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: alert.isActive,
                  onChanged: (value) {
                    setState(() {
                      alert.isActive = value;
                    });
                  },
                  activeColor: ColorConstants.primaryBlue,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showEditAlertDialog(alert),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                Container(width: 1, height: 30, color: ColorConstants.borderColor),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteAlert(alert),
                    icon: const Icon(Icons.delete, size: 18, color: ColorConstants.negativeRed),
                    label: const Text('Delete', style: TextStyle(color: ColorConstants.negativeRed)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAlertDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Create Price Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Metal/Currency'),
              items: ['Copper', 'Aluminium', 'Gold', 'Silver', 'USD/INR', 'EUR/INR']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Condition'),
              items: ['Above', 'Below']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Alert created successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorConstants.positiveGreen,
                  colorText: Colors.white);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditAlertDialog(PriceAlert alert) {
    Get.snackbar('Edit Alert', 'Editing ${alert.metal} alert',
        snackPosition: SnackPosition.BOTTOM);
  }

  void _deleteAlert(PriceAlert alert) {
    setState(() {
      _alerts.remove(alert);
    });
    Get.snackbar('Deleted', 'Alert removed',
        snackPosition: SnackPosition.BOTTOM);
  }
}

class PriceAlert {
  final String id;
  final String metal;
  final String condition;
  final double price;
  bool isActive;

  PriceAlert({
    required this.id,
    required this.metal,
    required this.condition,
    required this.price,
    required this.isActive,
  });
}
