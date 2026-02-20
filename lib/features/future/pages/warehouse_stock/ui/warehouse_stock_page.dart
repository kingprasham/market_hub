import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/warehouse_stock_controller.dart';
import '../../../../../core/services/google_sheets_service.dart';

class WarehouseStockPage extends StatelessWidget {
  const WarehouseStockPage({super.key});

  WarehouseStockController get controller => Get.put(WarehouseStockController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.lmeData.isEmpty) {
          return const ShimmerListLoader();
        }

        if (controller.lmeData.isEmpty) {
          return Center(
            child: Text(
              'No Warehouse Data Available',
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
                    columnSpacing: 20,
                    horizontalMargin: 16,
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
                    ),
                    columns: const [
                      DataColumn(label: Text('SYMBOL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('LAST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('CHANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('CHN %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('C. WR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('CHANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('CHN %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('LIVE-WR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('CHANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('CHN %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                    rows: controller.lmeData.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.symbol, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(item.last.toStringAsFixed(0))),
                          DataCell(Text(item.inStock.toStringAsFixed(0))),
                          DataCell(Text(item.outStock.toStringAsFixed(0))),
                          DataCell(_buildChangeText(item.change)),
                          DataCell(_buildChangeText(0, text: item.chnPercent)), // Parsing string directly
                          DataCell(Text(item.cwr.toStringAsFixed(0))),
                          DataCell(_buildChangeText(item.cwrChange)),
                          DataCell(_buildChangeText(0, text: item.cwrChnPercent)),
                          DataCell(Text(item.liveWr.toStringAsFixed(0))),
                          DataCell(_buildChangeText(item.liveWrChange)),
                          DataCell(_buildChangeText(0, text: item.liveWrChnPercent)),
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
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E), // Dark header bg
      child: Column(
        children: [
          const Text(
            'LME WAREHOUSE STOCK REPORT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(4),
             ),
             child: Column(
                children: const [
                   Text(
                     'CONMET INTERNATIONAL LLP',
                     style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                   ),
                   Text(
                     'Importers And Suppliers Of Non Ferrous Metals In India',
                     style: TextStyle(color: Colors.red, fontSize: 10),
                   ),
                   Text(
                     'Importing LME Grade A Material From Across The World.',
                     style: TextStyle(color: Colors.red, fontSize: 10),
                   ),
                   Text(
                     'Contact Us: 9871585566, 9810011615',
                     style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                   ),
                ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeText(double value, {String? text}) {
    final display = text ?? value.toStringAsFixed(0);
    // Check polarity
    bool isPos = value > 0;
    bool isNeg = value < 0;
    
    // If text is provided (percentage string), try to check polarity from it
    if (text != null) {
       if (text.contains('-')) isNeg = true;
       else if (text != '0.00%' && text != '0') isPos = true; // Assumption
    }

    Color color = Colors.black;
    if (isPos) color = ColorConstants.positiveGreen;
    if (isNeg) color = ColorConstants.negativeRed;
    
    return Text(
      display,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
