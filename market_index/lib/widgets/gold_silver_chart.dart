// lib/widgets/gold_silver_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';

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

    goldData.sort((a, b) => a.date.compareTo(b.date));
    silverData.sort((a, b) => a.date.compareTo(b.date));

    final List<FlSpot> goldSpots = goldData
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.price))
        .toList();

    final List<FlSpot> silverSpots = silverData
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.price))
        .toList();

    double minGold = goldData
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
    double maxGold = goldData
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);
    double minSilver = silverData
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
    double maxSilver = silverData
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);

    minGold -= (maxGold - minGold) * 0.1;
    maxGold += (maxGold - minGold) * 0.1;
    minSilver -= (maxSilver - minSilver) * 0.1;
    maxSilver += (maxSilver - minSilver) * 0.1;

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
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
                            if (index == 0 ||
                                (index % (goldData.length ~/ 6)).toInt() == 0 ||
                                index == goldData.length - 1) {
                              return SideTitleWidget(
                                meta: meta, // <--- meta 객체를 추가
                                angle: -0.7, // <--- angle을 다시 추가
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: (maxGold - minGold) / 4,
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
                  minY: minGold,
                  maxY: maxGold,

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
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 45.0, top: 8.0),
                child: Text(
                  'Silver Price (USD/OZS)',
                  style: TextStyle(
                    color: const Color(0xFFA9A9A9),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
