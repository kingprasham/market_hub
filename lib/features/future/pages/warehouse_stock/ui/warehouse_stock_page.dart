import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/warehouse_stock_controller.dart';
import '../../../../../core/services/google_sheets_service.dart';
import '../../../../../shared/widgets/common/metal_detail_dialog.dart';
import 'package:intl/intl.dart';

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
          child: CustomScrollView(
            slivers: [
              // Date banner
              if (controller.warehouseDate.value.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ColorConstants.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: ColorConstants.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${controller.warehouseDate.value}',
                          style: TextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = controller.lmeData[index];
                      return _buildWarehouseCard(context, item);
                    },
                    childCount: controller.lmeData.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
      ),
      child: Column(
        children: [
          const Text(
            'LME WAREHOUSE STOCK REPORT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.05),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.white10),
             ),
             child: Column(
                children: [
                   const Text(
                     'CONMET INTERNATIONAL LLP',
                     style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                   ),
                   const SizedBox(height: 2),
                   Text(
                     'Importers And Suppliers Of Non Ferrous Metals In India',
                     style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                   ),
                   const SizedBox(height: 4),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.phone, color: Colors.redAccent, size: 10),
                       const SizedBox(width: 4),
                       Text(
                         '9871585566, 9810011615',
                         style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 10),
                       ),
                     ],
                   ),
                ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseCard(BuildContext context, dynamic item) {
    return InkWell(
      onTap: () {
        MetalDetailDialog.show(
          context,
          title: '${item.symbol} Warehouse Stock',
          lastPrice: 'Total: ${item.last.toStringAsFixed(0)}',
          high: 'In: ${item.inStock.toStringAsFixed(0)}',
          low: 'Out: ${item.outStock.toStringAsFixed(0)}',
          change: 'Daily: ${item.change > 0 ? '+' : ''}${item.change.toStringAsFixed(0)} (${item.chnPercent})',
          isPositive: item.change >= 0,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: ColorConstants.borderColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open Stock',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          item.last.toStringAsFixed(0),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Daily Change',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      _buildChangeText(item.change, bold: true),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildValueSection('TOTAL STOCK', [
                    _buildDetailItem('IN', item.inStock.toStringAsFixed(0)),
                    _buildDetailItem('OUT', item.outStock.toStringAsFixed(0)),
                    _buildDetailItem('CHANGE', '', child: _buildChangeText(item.change)),
                    _buildDetailItem('CHANGE %', item.chnPercent),
                  ]),
                  const Divider(height: 24),
                  _buildValueSection('CANCELLED WARRANTS (C.WR)', [
                    _buildDetailItem('VALUE', item.cwr.toStringAsFixed(0)),
                    _buildDetailItem('CHANGE', '', child: _buildChangeText(item.cwrChange)),
                    _buildDetailItem('CHANGE %', item.cwrChnPercent),
                  ]),
                  const Divider(height: 24),
                  _buildValueSection('LIVE WARRANTS (LIVE-WR)', [
                    _buildDetailItem('VALUE', item.liveWr.toStringAsFixed(0)),
                    _buildDetailItem('CHANGE', '', child: _buildChangeText(item.liveWrChange)),
                    _buildDetailItem('CHANGE %', item.liveWrChnPercent),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: ColorConstants.primaryBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: children.map((w) => SizedBox(width: 70, child: w)).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {Widget? child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        child ?? Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildChangeText(double value, {String? text, bool bold = false}) {
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
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        fontSize: bold ? 14 : 12,
      ),
    );
  }
}
