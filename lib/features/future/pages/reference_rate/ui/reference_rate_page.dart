import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/reference_rate_controller.dart';
import '../../../../../data/models/forex/forex_sheet_data.dart';

class ReferenceRatePage extends StatelessWidget {
  const ReferenceRatePage({super.key});

  ReferenceRateController get controller => Get.put(ReferenceRateController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ColorConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: ColorConstants.backgroundColor,
          elevation: 0,
          toolbarHeight: 0, // Hide default app bar (tabs are in bottom)
          bottom: TabBar(
            labelColor: ColorConstants.primaryBlue,
            unselectedLabelColor: ColorConstants.textSecondary,
            indicatorColor: ColorConstants.primaryBlue,
            labelStyle: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyles.bodyMedium,
            tabs: const [
              Tab(text: 'SBI TT SELL'),
              Tab(text: 'RBI FBILL'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const ShimmerListLoader();
          }

          if (controller.hasError.value) {
             return Center(
               child: Text(
                 controller.errorMessage.value,
                 style: TextStyles.bodyMedium.copyWith(color: Colors.red),
                 textAlign: TextAlign.center,
               ),
             );
          }

          return TabBarView(
            children: [
              _buildSbiTable(controller.sbiTableRows),
              _buildRbiTable(controller.rbiTableRows),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSbiTable(List<SbiTableRow> rows) {
    if (rows.isEmpty) {
      return Center(child: Text('No SBI Data Available', style: TextStyles.bodyMedium));
    }
    
    final sortedRows = List<SbiTableRow>.from(rows)
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(ColorConstants.cardColor),
          columnSpacing: 20,
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          columns: _buildColumns(['DATE', 'USD/INR', 'EUR/INR', 'GBP/INR', 'JPY/INR']),
          rows: sortedRows.map((row) {
            return DataRow(cells: [
              _buildDateCell(row.date),
              _buildCell(row.usd),
              _buildCell(row.eur),
              _buildCell(row.gbp),
              _buildCell(row.jpy),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRbiTable(List<RbiTableRow> rows) {
    if (rows.isEmpty) {
      return Center(child: Text('No RBI Data Available', style: TextStyles.bodyMedium));
    }

    final sortedRows = List<RbiTableRow>.from(rows)
      ..sort((a, b) => b.date.compareTo(a.date));
      
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(ColorConstants.cardColor),
          columnSpacing: 20,
           border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          columns: _buildColumns(['DATE', 'USD/INR', 'GBP/INR', 'EUR/INR', 'JPY/INR']),
          rows: sortedRows.map((row) {
            return DataRow(cells: [
              _buildDateCell(row.date),
              _buildCell(row.usd, decimalPlaces: 4),
              _buildCell(row.gbp, decimalPlaces: 4),
              _buildCell(row.eur, decimalPlaces: 4),
              _buildCell(row.jpy, decimalPlaces: 2),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns(List<String> labels) {
    return labels.map((label) => DataColumn(
      label: Text(
        label, 
        style: TextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold, 
          color: ColorConstants.textPrimary
        )
      ),
    )).toList();
  }

  DataCell _buildCell(double value, {int decimalPlaces = 2}) {
    return DataCell(
      Text(
        value.toStringAsFixed(decimalPlaces),
        style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textPrimary),
      ),
    );
  }

  DataCell _buildDateCell(DateTime date) {
    return DataCell(
      Text(
        DateFormat('dd-MMM-yyyy').format(date),
        style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
      ),
    );
  }
}
