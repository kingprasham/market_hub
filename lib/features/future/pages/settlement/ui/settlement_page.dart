import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/settlement_controller.dart';

class SettlementPage extends StatelessWidget {
  const SettlementPage({super.key});

  SettlementController get controller => Get.put(SettlementController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.settlementData.isEmpty) {
          return const ShimmerListLoader();
        }

        if (controller.settlementData.isEmpty) {
          return Center(
            child: Text(
              'No Settlement Data Available',
              style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: ColorConstants.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSettlementHeader(),
                const SizedBox(height: 12),
                _buildSettlementTable(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSettlementHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        'SETTLEMENT',
        style: TextStyle(
          color: ColorConstants.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettlementTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade400, width: 1),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.red.shade400, width: 1),
        columnWidths: const {
          0: FixedColumnWidth(80), // DATE
          1: FlexColumnWidth(1.2), // METAL
          2: FlexColumnWidth(1),   // CASH BID
          3: FlexColumnWidth(1),   // CASH ASK
          4: FlexColumnWidth(1),   // 3M BID
          5: FlexColumnWidth(1),   // 3M ASK
        },
        children: [
          // Sub Headers
          TableRow(
            children: [
              _buildHeaderCell('DATE'),
              _buildHeaderCell('METAL'),
              _buildHeaderCell('BID', parent: 'CASH'),
              _buildHeaderCell('ASK', parent: 'CASH'),
              _buildHeaderCell('BID', parent: '3M'),
              _buildHeaderCell('ASK', parent: '3M'),
            ],
          ),
          // Group Headers (CASH and 3M)
          TableRow(
            children: [
              const SizedBox.shrink(),
              const SizedBox.shrink(),
              _buildGroupHeader('CASH'),
              _buildGroupHeader('CASH'),
              _buildGroupHeader('3M'),
              _buildGroupHeader('3M'),
            ],
          ),
          ...controller.settlementData.map((item) => _buildDataRow(item)).toList(),
        ],
      ),
    );
  }

  // Note: Table headers in Flutter are tricky for nested. 
  // We'll manually build the header rows.

  // Let's refine the table structure to perfectly match the user image:
  // Row 1: DATE | METAL | CASH (spanning BID/ASK) | 3M (spanning BID/ASK)
  // Row 2: empty| empty | BID | ASK | BID | ASK

  // Actually, simplest is to use custom widgets for headers.
  
  Widget _buildHeaderCell(String label, {String? parent}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textPrimary,
        ),
      ),
    );
  }

  // To match the image exactly:
  // The first row should have "DATE", "METAL", and then merged "CASH" and "3M"
  // But Table doesn't support colSpan. We'll use a standard Table with layered headers.

  TableRow _buildDataRow(dynamic item) {
    return TableRow(
      children: [
        _buildDataCell(item.date, fontSize: 10),
        _buildDataCell(item.metal, isCentered: true, fontWeight: FontWeight.bold),
        _buildDataCell(item.bidCash.toStringAsFixed(0), color: Colors.blue.shade800),
        _buildDataCell(item.askCash.toStringAsFixed(0), color: Colors.blue.shade800),
        _buildDataCell(item.bid3M.toStringAsFixed(0), color: Colors.blue.shade800),
        _buildDataCell(item.ask3M.toStringAsFixed(0), color: Colors.blue.shade800),
      ],
    );
  }

  Widget _buildDataCell(String value, {
    bool isCentered = false, 
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double fontSize = 11,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? ColorConstants.textPrimary,
        ),
      ),
    );
  }
}
