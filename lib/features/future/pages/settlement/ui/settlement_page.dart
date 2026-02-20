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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF2C2C2C)),
                    dataRowColor: MaterialStateProperty.all(ColorConstants.surfaceColor),
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
                      // verticalInside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
                    ),
                    columns: const [
                      DataColumn(label: Text('DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('METAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('BID (Cash)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ASK (Cash)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('BID (3M)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ASK (3M)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                    rows: controller.settlementData.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.date)),
                          DataCell(Text(item.metal, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(item.bidCash > 0 ? item.bidCash.toStringAsFixed(0) : '-')),
                          DataCell(Text(item.askCash > 0 ? item.askCash.toStringAsFixed(0) : '-')),
                          DataCell(Text(item.bid3M > 0 ? item.bid3M.toStringAsFixed(0) : '-')),
                          DataCell(Text(item.ask3M > 0 ? item.ask3M.toStringAsFixed(0) : '-')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: const Color(0xFF00897B),
      child: const Center(
        child: Text(
          'SETTLEMENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
