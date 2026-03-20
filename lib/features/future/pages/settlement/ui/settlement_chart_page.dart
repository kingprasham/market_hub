import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../controller/settlement_controller.dart';

class SettlementChartPage extends GetView<SettlementController> {
  const SettlementChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Arguments: { 'metalName': 'COPPER' }
    final String metalName = Get.arguments?['metalName'] ?? 'Metal';
    
    // Fetch data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHistoricalPrices(metalName);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$metalName History', style: TextStyles.h3),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: ColorConstants.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isHistoricalLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: ColorConstants.primaryColor),
          );
        }

        if (controller.historicalData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No historical data found for $metalName',
                  style: TextStyles.bodyLarge.copyWith(color: ColorConstants.textSecondary),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => controller.fetchHistoricalPrices(metalName),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChartCard(metalName),
              _buildStatsSection(),
              _buildHistoryList(),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChartCard(String metalName) {
    return Container(
      height: 380,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, color: ColorConstants.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Settlement Price',
                    style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'LME Official Data',
                    style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(_buildChartData()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final history = controller.historicalData;
    final spots = <FlSpot>[];
    
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].cash));
    }

    final prices = history.map((e) => e.cash).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice;
    final padding = range == 0 ? 100.0 : range * 0.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: range == 0 ? 50 : range / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${value.toInt()}',
                style: TextStyles.caption.copyWith(fontSize: 10, color: ColorConstants.textSecondary),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (history.length / 4).clamp(1, history.length.toDouble()),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= history.length) return const SizedBox();
              
              // Date format "10. March 2026" -> "10 Mar"
              final dateParts = history[index].date.split('. ');
              String day = '';
              String month = '';
              if (dateParts.length >= 2) {
                day = dateParts[0];
                final monthPart = dateParts[1].split(' ');
                if (monthPart.isNotEmpty) {
                  month = monthPart[0].substring(0, 3);
                }
              }
              
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$day $month',
                  style: TextStyles.caption.copyWith(fontSize: 10, color: ColorConstants.textSecondary),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (history.length - 1).toDouble(),
      minY: minPrice - padding,
      maxY: maxPrice + padding,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: ColorConstants.primaryColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: history.length < 15,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: ColorConstants.primaryColor,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorConstants.primaryColor.withOpacity(0.15),
                ColorConstants.primaryColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => ColorConstants.primaryColor,
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              final entry = history[index];
              return LineTooltipItem(
                '\$${entry.cash.toStringAsFixed(2)}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                children: [
                  TextSpan(
                    text: entry.date,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.normal, fontSize: 10),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final history = controller.historicalData;
    final prices = history.map((e) => e.cash).toList();
    final high = prices.reduce((a, b) => a > b ? a : b);
    final low = prices.reduce((a, b) => a < b ? a : b);
    final avg = prices.reduce((a, b) => a + b) / prices.length;
    
    final latest = history.last.cash;
    final first = history.first.cash;
    final change = latest - first;
    final changePercent = (change / first) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Performance Stats', style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              _buildStatCard('Highest Price', '\$${high.toStringAsFixed(2)}', Colors.green),
              _buildStatCard('Lowest Price', '\$${low.toStringAsFixed(2)}', Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('Period Average', '\$${avg.toStringAsFixed(2)}', Colors.blue),
              _buildStatCard(
                'Net Change', 
                '${change >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%', 
                change >= 0 ? Colors.green : Colors.red
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary)),
            const SizedBox(height: 6),
            Text(value, style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final history = controller.historicalData.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('Closing Records', style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final entry = history[index];
            final bool isUp = index < history.length - 1 && entry.cash >= history[index+1].cash;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: (isUp ? Colors.green : Colors.red).withOpacity(0.1),
                  child: Icon(
                    isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isUp ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                title: Text(entry.date, style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                subtitle: Text('Pension CSP: ${NumberFormat("#,###").format(entry.stock)} MT', style: TextStyles.caption),
                trailing: Text(
                  '\$${entry.cash.toStringAsFixed(2)}',
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
