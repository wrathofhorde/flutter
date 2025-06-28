// lib/widgets/gold_silver_ratio_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import 'dart:math';

class GoldSilverRatioChart extends StatelessWidget {
  final List<GoldSilverRatioData> ratioData;
  final int monthsToShow;

  const GoldSilverRatioChart({
    super.key,
    required this.ratioData,
    required this.monthsToShow,
  });

  @override
  Widget build(BuildContext context) {
    if (ratioData.isEmpty) {
      return const Center(child: Text('금/은 비율 데이터를 불러올 수 없습니다.'));
    }

    ratioData.sort((a, b) => a.date.compareTo(b.date));

    final DateTime firstDate = ratioData.first.date;
    final double minRatio = ratioData.map((e) => e.ratio).reduce(min);
    final double maxRatio = ratioData.map((e) => e.ratio).reduce(max);

    // Y축 범위 설정 (비율 데이터에 맞춰)
    final double ratioRange = maxRatio - minRatio;
    double chartMinY = minRatio - ratioRange * 0.1;
    double chartMaxY = maxRatio + ratioRange * 0.1;

    // Y축 범위가 너무 작으면 최소 범위 확보
    if (chartMaxY - chartMinY < 1.0) {
      chartMaxY = chartMinY + 1.0;
    }

    final List<FlSpot> spots = ratioData
        .map(
          (data) => FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            data.ratio,
          ),
        )
        .toList();

    final double maxX = ratioData.last.date
        .difference(firstDate)
        .inDays
        .toDouble();

    // Y축 interval 계산 (비율 데이터에 맞춰)
    double ratioInterval = (chartMaxY - chartMinY > 0)
        ? (chartMaxY - chartMinY) / 4
        : 1.0;
    if (ratioInterval < 0.5) {
      // 비율 특성에 맞춰 최소 간격 조정 (예시)
      ratioInterval = 0.5;
    }
    ratioInterval = (ratioInterval * 2).ceilToDouble() / 2; // 0.5 단위로 반올림

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold/Silver Ratio',
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
                          final DateTime date = firstDate.add(
                            Duration(days: value.toInt()),
                          );

                          int totalDays = maxX.toInt();
                          int intervalDays = (totalDays / 5).ceil();

                          if (intervalDays == 0) intervalDays = 1;

                          if (value == 0 ||
                              value.toInt() == maxX.toInt() ||
                              (value % intervalDays == 0 &&
                                  value != 0 &&
                                  value.toInt() != maxX.toInt())) {
                            return SideTitleWidget(
                              meta: meta,
                              angle: -0.7,
                              child: Text(
                                DateFormat('yy.MM.dd').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1), // 비율은 소수점 한 자리로 표시
                            style: const TextStyle(
                              color: Colors.blue, // 비율 차트 색상
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: ratioInterval,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      // 오른쪽 Y축은 표시하지 않습니다.
                      sideTitles: SideTitles(showTitles: false),
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
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue, // 비율 라인 색상
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minX: 0,
                  maxX: maxX,
                  minY: chartMinY,
                  maxY: chartMaxY,

                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final DateTime date = firstDate.add(
                            Duration(days: touchedSpot.x.toInt()),
                          );
                          final String dateFormatted = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);

                          return LineTooltipItem(
                            '$dateFormatted\n비율: ${touchedSpot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.blue,
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
                mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                children: [
                  Container(width: 16, height: 2, color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text(
                    'Gold/Silver Ratio',
                    style: TextStyle(fontSize: 12),
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
