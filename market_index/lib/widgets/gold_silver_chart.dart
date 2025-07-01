// lib/widgets/gold_silver_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:market_index/utils/chart_common.dart';
import '../models/data_models.dart';
import 'dart:math';

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

    final DateTime firstDate = goldData.first.date;

    // Gold 가격 데이터 범위 및 Y축 패딩
    final double minGoldPrice = goldData.map((e) => e.price).reduce(min);
    final double maxGoldPrice = goldData.map((e) => e.price).reduce(max);
    final double goldPaddingY = (maxGoldPrice - minGoldPrice) * 0.1;
    final double finalMinGoldY = minGoldPrice - goldPaddingY;
    final double finalMaxGoldY = maxGoldPrice + goldPaddingY;

    // Silver 가격 데이터 범위 및 Y축 패딩 (라벨링을 위함)
    final double minSilverPrice = silverData.map((e) => e.price).reduce(min);
    final double maxSilverPrice = silverData.map((e) => e.price).reduce(max);
    final double silverPaddingY = (maxSilverPrice - minSilverPrice) * 0.1;
    final double finalMinSilverY = minSilverPrice - silverPaddingY;
    final double finalMaxSilverY = maxSilverPrice + silverPaddingY;

    // Gold Spots 생성
    final List<FlSpot> goldSpots = goldData
        .map(
          (data) => FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            data.price,
          ),
        )
        .toList();

    // Silver Spots 생성 - Gold 스케일에 맞춰 변환
    final List<FlSpot> silverSpots = silverData.map((data) {
      final double originalSilverY = data.price;
      double scaledSilverY;

      // 은 가격 범위가 0인 경우 (모든 가격이 동일) 예외 처리
      if ((finalMaxSilverY - finalMinSilverY).abs() < 1e-9) {
        // 거의 0에 가까운 경우
        scaledSilverY = finalMinGoldY; // 또는 중간 값 등으로 설정
      } else {
        // 은 가격을 금 가격의 Y축 범위로 스케일링
        scaledSilverY =
            (originalSilverY - finalMinSilverY) *
                (finalMaxGoldY - finalMinGoldY) /
                (finalMaxSilverY - finalMinSilverY) +
            finalMinGoldY;
      }
      return FlSpot(
        data.date.difference(firstDate).inDays.toDouble(),
        scaledSilverY,
      );
    }).toList();

    final double maxX = goldData.last.date
        .difference(firstDate)
        .inDays
        .toDouble();

    // X축 라벨 간격을 동적으로 계산 (대략 6개의 라벨을 목표)
    // maxX를 5로 나누면 (6개의 라벨 = 5개의 간격) 됨.
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
              'Gold vs Silver Prices',
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
                        'Gold Price (USD/OZS)',
                        style: TextStyle(
                          color: ChartColor.gold, // Gold 색상과 맞춤
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // 축 이름 폰트 크기
                        ),
                      ),
                      axisNameSize: 25, // 축 이름 공간
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            space: 8.0,
                            meta: meta,
                            child: Text(
                              value.toStringAsFixed(0), // 금 가격은 정수로 표시
                              style: const TextStyle(
                                // 여기가 금색으로 변경됩니다.
                                color: ChartColor.gold, // Gold Price 라벨 색상
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          );
                        },
                        reservedSize: 50,
                        interval:
                            (finalMaxGoldY - finalMinGoldY) /
                            5, // Gold 가격에 맞춰 간격 조정
                      ),
                    ),
                    rightTitles: AxisTitles(
                      // 오른쪽 Y축
                      axisNameWidget: const Text(
                        'Silver Price (USD/OZS)',
                        style: TextStyle(
                          color: ChartColor.silver, // Silver 색상과 맞춤
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      axisNameSize: 25, // 축 이름 공간
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // 차트의 현재 Y값 (금 스케일)을 은 스케일로 역변환하여 라벨로 표시
                          double silverEquivalentValue;
                          if ((finalMaxGoldY - finalMinGoldY).abs() < 1e-9) {
                            // 금 가격 범위가 0인 경우
                            silverEquivalentValue = finalMinSilverY;
                          } else {
                            silverEquivalentValue =
                                (value - finalMinGoldY) *
                                    (finalMaxSilverY - finalMinSilverY) /
                                    (finalMaxGoldY - finalMinGoldY) +
                                finalMinSilverY;
                          }
                          return SideTitleWidget(
                            space: 8.0,
                            meta: meta,
                            child: Text(
                              silverEquivalentValue.toStringAsFixed(
                                1,
                              ), // 소수점 한 자리까지 표시
                              style: const TextStyle(
                                color: ChartColor.silver, // Silver Price 라벨 색상
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.right, // 오른쪽 정렬
                            ),
                          );
                        },
                        reservedSize: 50, // 오른쪽 마진 증가
                        // 오른쪽 축의 interval도 기본 차트의 Y축 범위에 맞춰야 합니다.
                        // 이 값은 getTitlesWidget 내부의 변환과는 별개로 축의 라벨 간격을 결정합니다.
                        interval: (finalMaxGoldY - finalMinGoldY) / 5,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: ChartColor.border, width: 1),
                  ),
                  minX: 0,
                  maxX: maxX,
                  minY: finalMinGoldY, // 차트의 전체 Y축 범위는 Gold 기준
                  maxY: finalMaxGoldY, // 차트의 전체 Y축 범위는 Gold 기준
                  lineBarsData: [
                    LineChartBarData(
                      spots: goldSpots,
                      isCurved: true,
                      color: ChartColor.gold, // Gold color
                      barWidth: ChartBar.width,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: silverSpots, // 변환된 silverSpots 사용
                      isCurved: true,
                      color: ChartColor.silver, // Silver color
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
                          final color = touchedSpot.bar.color;
                          DateTime date = firstDate.add(
                            Duration(days: touchedSpot.x.toInt()),
                          );
                          final String dateFormatted = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);
                          String label = '';
                          String priceText = '';

                          if (color == ChartColor.gold) {
                            // Gold는 원래 값 그대로 사용
                            label = 'Gold';
                            priceText = touchedSpot.y.toStringAsFixed(0);
                          } else if (color == ChartColor.silver) {
                            // Silver는 터치된 Y값(금 스케일)을 은 스케일로 역변환하여 표시
                            label = 'Silver';
                            double originalSilverPrice;
                            if ((finalMaxGoldY - finalMinGoldY).abs() < 1e-9) {
                              originalSilverPrice = finalMinSilverY;
                            } else {
                              originalSilverPrice =
                                  (touchedSpot.y - finalMinGoldY) *
                                      (finalMaxSilverY - finalMinSilverY) /
                                      (finalMaxGoldY - finalMinGoldY) +
                                  finalMinSilverY;
                            }
                            priceText = originalSilverPrice.toStringAsFixed(2);
                          }
                          return LineTooltipItem(
                            '$dateFormatted\n$label: $priceText',
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
            // 범례
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Container(width: 16, height: 2, color: ChartColor.gold),
                      const SizedBox(width: 4),
                      const Text('Gold Price', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 16, height: 2, color: ChartColor.silver),
                      const SizedBox(width: 4),
                      const Text(
                        'Silver Price',
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
