// lib/widgets/gold_silver_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import 'dart:math'; // min, max 함수 사용을 위해 추가

class GoldSilverChart extends StatelessWidget {
  final List<GoldData> goldData;
  final List<SilverData> silverData;
  final int monthsToShow;

  const GoldSilverChart({
    super.key,
    required this.goldData,
    required this.silverData,
    required this.monthsToShow,
  });

  @override
  Widget build(BuildContext context) {
    if (goldData.isEmpty || silverData.isEmpty) {
      return const Center(child: Text('Gold 또는 Silver 데이터를 불러올 수 없습니다.'));
    }

    // 데이터 정렬
    goldData.sort((a, b) => a.date.compareTo(b.date));
    silverData.sort((a, b) => a.date.compareTo(b.date));

    // 각 데이터의 최소/최대값 계산
    final double minGoldPrice = goldData.map((e) => e.price).reduce(min);
    final double maxGoldPrice = goldData.map((e) => e.price).reduce(max);
    final double minSilverPrice = silverData.map((e) => e.price).reduce(min);
    final double maxSilverPrice = silverData.map((e) => e.price).reduce(max);

    // 차트의 전체 Y축 범위 (Gold 가격을 기준으로 설정)
    // Gold 데이터의 min/max에 약간의 패딩을 더합니다.
    final double goldRange = maxGoldPrice - minGoldPrice;
    final double chartMinY = minGoldPrice - goldRange * 0.1;
    final double chartMaxY = maxGoldPrice + goldRange * 0.1;

    // Gold Spots: 실제 Gold 가격 사용
    final List<FlSpot> goldSpots = goldData
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.price))
        .toList();

    // Silver Spots: Silver 가격을 Gold Y축 범위에 맞게 변환하여 Plot
    final List<FlSpot> silverSpots = silverData.asMap().entries.map((entry) {
      final double originalSilverPrice = entry.value.price;
      final double silverRelativePosition =
          (originalSilverPrice - minSilverPrice) /
          (maxSilverPrice - minSilverPrice);
      final double scaledSilverPriceForPlotting =
          chartMinY + silverRelativePosition * (chartMaxY - chartMinY);
      return FlSpot(entry.key.toDouble(), scaledSilverPriceForPlotting);
    }).toList();

    // Gold Y축 interval 계산 (범위가 0이면 1.0으로 설정)
    final double goldInterval = (chartMaxY - chartMinY > 0)
        ? (chartMaxY - chartMinY) / 4
        : 1.0;
    // Silver Y축 interval 계산 (범위가 0이면 1.0으로 설정)
    final double silverRange = maxSilverPrice - minSilverPrice;
    final double silverInterval = (silverRange > 0) ? silverRange / 4 : 1.0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold vs Silver Prices (지난 ${monthsToShow == 999 ? "모든" : monthsToShow}개월)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withAlpha((255 * 0.3).round()),
                      strokeWidth: 0.5,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withAlpha((255 * 0.3).round()),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (index >= 0 && index < goldData.length) {
                            final DateTime date = goldData[index].date;
                            int intervalFactor = (goldData.length / 6).ceil();
                            if (intervalFactor == 0) intervalFactor = 1;

                            if (index % intervalFactor == 0 ||
                                index == goldData.length - 1) {
                              return SideTitleWidget(
                                meta: meta,
                                angle: -0.7,
                                child: Text(
                                  DateFormat('yy.MM').format(date),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      // 왼쪽 Y축 (금 가격)
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: goldInterval,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      // *** axisLine 속성을 제거했습니다. ***
                      // AxisTitles에는 axisLine 파라미터가 없으므로 제거합니다.
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final double chartRelativePosition =
                              (value - chartMinY) / (chartMaxY - chartMinY);
                          final double originalSilverValue =
                              minSilverPrice +
                              chartRelativePosition *
                                  (maxSilverPrice - minSilverPrice);

                          if (originalSilverValue.isNaN ||
                              originalSilverValue.isInfinite) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            originalSilverValue.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Color(0xFFA9A9A9),
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: silverInterval,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xff37434d),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: goldSpots,
                      isCurved: true,
                      color: const Color(0xFFD4AF37),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: silverSpots,
                      isCurved: true,
                      color: const Color(0xFFA9A9A9),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minX: 0,
                  maxX: (goldData.length - 1).toDouble(),
                  minY: chartMinY,
                  maxY: chartMaxY,

                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final int index = touchedSpot.spotIndex;
                          if (index < 0 ||
                              index >= goldData.length ||
                              index >= silverData.length) {
                            return null;
                          }
                          final String dateFormatted = DateFormat(
                            'yyyy-MM-dd',
                          ).format(goldData[index].date);
                          final double goldPrice = goldData[index].price;
                          final double silverPrice = silverData[index].price;

                          String text;
                          Color color;
                          if (touchedSpot.barIndex == 0) {
                            text = 'Gold: ${goldPrice.toStringAsFixed(2)}';
                            color = touchedSpot.bar.color ?? Colors.black;
                          } else {
                            text = 'Silver: ${silverPrice.toStringAsFixed(2)}';
                            color = touchedSpot.bar.color ?? Colors.black;
                          }

                          return LineTooltipItem(
                            '$dateFormatted\n$text',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? response) {},
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 2,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Gold Price (USD/OZS)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 2,
                        color: const Color(0xFFA9A9A9),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Silver Price (USD/OZS)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
