// lib/widgets/gold_silver_ratio_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:market_index/utils/chart_common.dart';
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

    // X축 라벨 간격을 동적으로 계산 (대략 6개의 라벨을 목표)
    final double xAxisInterval = maxX / 5;

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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xAxisInterval, // 동적으로 계산된 간격 적용
                        getTitlesWidget: (value, meta) {
                          DateTime date = firstDate.add(
                            Duration(days: value.toInt()),
                          );
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat('yy.MM').format(date),
                              style: const TextStyle(
                                color: ChartColor.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Ratio',
                        style: TextStyle(
                          color: ChartColor.goldSilverRatio, // 비율 차트의 라인 색상과 맞춤
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      axisNameSize: 25,
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            space: 8.0,
                            meta: meta,
                            child: Text(
                              value.toStringAsFixed(1), // 소수점 한 자리까지 표시
                              style: const TextStyle(
                                color: ChartColor.text, // 일반 텍스트 색상
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // 글자 크기 조정
                              ),
                              textAlign: TextAlign.left,
                            ),
                          );
                        },
                        reservedSize: 50, // 여유 공간 확보
                        interval:
                            (chartMaxY - chartMinY) / 5, // Y축 간격 조정 (5개 라벨)
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: ChartColor.border, width: 1),
                  ),
                  minX: 0,
                  maxX: maxX,
                  minY: chartMinY,
                  maxY: chartMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: ChartColor.goldSilverRatio, // Line color
                      barWidth: ChartBar.width,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    // touchSpotDotData 대신 getTouchedSpotIndicator 사용
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                          final color = barData.color; // 해당 라인의 색상을 가져옵니다.

                          return spotIndexes.map((int index) {
                            final flLine = FlLine(
                              color: color, // 라인 색상도 해당 라인 색상으로
                              strokeWidth: 1.2,
                              dashArray: [5, 5],
                            );
                            final dotData = FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                final color = barData.color;
                                return FlDotCirclePainter(
                                  radius: 6, // 점의 반지름을 4로 설정 (원하는 크기로 조절)
                                  color: color!, // 점 색상도 해당 라인 색상으로
                                  strokeWidth: 1,
                                  strokeColor: Colors.white,
                                );
                              },
                            );
                            return TouchedSpotIndicatorData(flLine, dotData);
                          }).toList();
                        },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((touchedSpot) {
                          DateTime date = firstDate.add(
                            Duration(days: touchedSpot.x.toInt()),
                          );
                          final String dateFormatted = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);

                          return LineTooltipItem(
                            '$dateFormatted\n비율: ${touchedSpot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              color: ChartColor.goldSilverRatio,
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
                  Container(
                    width: 16,
                    height: 2,
                    color: ChartColor.goldSilverRatio,
                  ),
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
