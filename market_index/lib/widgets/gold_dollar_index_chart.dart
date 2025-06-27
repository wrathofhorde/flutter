// lib/widgets/gold_dollar_index_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import 'dart:math';
import 'dart:developer' as developer;

class GoldDollarIndexChart extends StatelessWidget {
  final List<GoldData> goldData;
  final List<DollarIndexData> dollarIndexData;
  final int monthsToShow;

  const GoldDollarIndexChart({
    super.key,
    required this.goldData,
    required this.dollarIndexData,
    required this.monthsToShow,
  });

  @override
  Widget build(BuildContext context) {
    if (goldData.isEmpty || dollarIndexData.isEmpty) {
      return const Center(child: Text('Gold 또는 Dollar Index 데이터를 불러올 수 없습니다.'));
    }

    // 데이터 정렬
    goldData.sort((a, b) => a.date.compareTo(b.date));
    dollarIndexData.sort((a, b) => a.date.compareTo(b.date));

    // 공통 날짜 범위의 시작점을 찾습니다.
    final DateTime firstDate = goldData.first.date;

    // Gold 데이터의 최소/최대 가격
    final double minGoldPrice = goldData.map((e) => e.price).reduce(min);
    final double maxGoldPrice = goldData.map((e) => e.price).reduce(max);

    // Dollar Index 데이터의 최소/최대 가격
    final double minDollarIndex = dollarIndexData
        .map((e) => e.price)
        .reduce(min);
    final double maxDollarIndex = dollarIndexData
        .map((e) => e.price)
        .reduce(max);

    // Gold Spots 생성
    final List<FlSpot> goldSpots = goldData
        .map(
          (data) => FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            data.price,
          ),
        )
        .toList();

    // Dollar Index 데이터 재조정 (스케일링)
    // Gold 가격 범위에 Dollar Index를 맞추기 위한 스케일링 상수 계산
    // Gold의 범위 대비 Dollar Index의 범위 비율을 찾고, 그 비율을 Gold 최저점에 적용
    final double goldPriceRange = maxGoldPrice - minGoldPrice;
    final double dollarIndexRange = maxDollarIndex - minDollarIndex;

    List<FlSpot> dollarIndexSpotsScaled = [];

    // dollarIndexRange가 0이 아니어야 합니다. (모든 값이 동일한 경우 방지)
    if (dollarIndexRange > 0 && goldPriceRange > 0) {
      // Dollar Index의 각 값을 Gold 스케일에 맞게 변환합니다.
      // 1. Dollar Index 값을 0-1 범위로 정규화
      // 2. 정규화된 값을 Gold의 (minGoldPrice ~ maxGoldPrice) 범위로 스케일링
      for (var data in dollarIndexData) {
        double normalizedDollarIndex =
            (data.price - minDollarIndex) / dollarIndexRange;
        double scaledDollarIndex =
            normalizedDollarIndex * goldPriceRange + minGoldPrice;
        dollarIndexSpotsScaled.add(
          FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            scaledDollarIndex,
          ),
        );
      }
    } else {
      // Dollar Index 범위가 0이거나 Gold 가격 범위가 0인 경우, 스케일링을 적용하지 않거나 기본값 사용
      developer.log(
        'Warning: Dollar Index range or Gold Price range is zero. Cannot scale Dollar Index.',
        name: 'GoldDollarIndexChart',
      );
      // 이 경우에는 Dollar Index 값을 그대로 사용하거나 다른 방식으로 처리할 수 있습니다.
      // 여기서는 그냥 Dollar Index의 첫 값을 사용하여 모든 DollarIndexData에 동일한 스케일 적용 (일단 첫 값에 맞춰서 그리는 방식)
      if (dollarIndexData.isNotEmpty && goldData.isNotEmpty) {
        double averageGoldPrice =
            goldData.map((e) => e.price).reduce((a, b) => a + b) /
            goldData.length;
        double firstDollarIndexPrice = dollarIndexData.first.price;
        // 임시 스케일링 비율: Gold 평균을 Dollar Index 첫 값으로 나눈 비율
        double scaleFactor = averageGoldPrice / firstDollarIndexPrice;

        for (var data in dollarIndexData) {
          dollarIndexSpotsScaled.add(
            FlSpot(
              data.date.difference(firstDate).inDays.toDouble(),
              data.price * scaleFactor,
            ),
          );
        }
      }
    }

    // X축 최대값 (두 데이터 중 더 긴 기간을 가진 데이터를 기준으로)
    final double maxX = max(
      goldData.last.date.difference(firstDate).inDays.toDouble(),
      dollarIndexData.last.date.difference(firstDate).inDays.toDouble(),
    );

    // Y축 범위 및 interval 설정 (Gold 가격 기준으로 통일)
    final double chartMinY = minGoldPrice - goldPriceRange * 0.1;
    final double chartMaxY = maxGoldPrice + goldPriceRange * 0.1;

    // Y축 interval 계산 (Gold 가격 기준으로 통일)
    double chartInterval = (chartMaxY - chartMinY > 0)
        ? (chartMaxY - chartMinY) / 4
        : 1.0;
    if (chartInterval < 10) {
      // 금 가격은 보통 10단위 이상이므로 간격을 10이상으로
      chartInterval = 10;
    }
    chartInterval = chartInterval.ceilToDouble(); // 정수로 반올림

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold Price vs Dollar Index (지난 ${monthsToShow == 999 ? "모든" : monthsToShow}개월)',
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
                          // Gold Price (왼쪽 Y축)
                          return Text(
                            value.toStringAsFixed(0), // Gold는 소수점 없이 표시
                            style: const TextStyle(
                              color: Color(0xFFD4AF37), // Gold 색상
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: chartInterval, // Gold 가격에 맞춰진 interval
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          // Dollar Index (오른쪽 Y축) - 스케일링된 값을 실제 Dollar Index 값으로 역변환
                          if (dollarIndexRange > 0 && goldPriceRange > 0) {
                            // 1. 스케일링된 값을 0-1 범위로 역정규화
                            double normalizedValue =
                                (value - minGoldPrice) / goldPriceRange;
                            // 2. 역정규화된 값을 원래 Dollar Index 범위로 스케일링
                            double originalDollarIndexValue =
                                normalizedValue * dollarIndexRange +
                                minDollarIndex;

                            // interval에 맞는 라벨만 표시
                            double remainder =
                                (originalDollarIndexValue - minDollarIndex) %
                                ((maxDollarIndex - minDollarIndex) /
                                    4); // 달러 인덱스 원래 범위의 대략적인 간격
                            if (remainder < 0.1 ||
                                (((maxDollarIndex - minDollarIndex) / 4) -
                                        remainder) <
                                    0.1) {
                              return Text(
                                originalDollarIndexValue.toStringAsFixed(
                                  1,
                                ), // Dollar Index는 소수점 한 자리로 표시
                                style: const TextStyle(
                                  color: Colors.purple, // Dollar Index 색상
                                  fontSize: 10,
                                ),
                              );
                            }
                          } else {
                            // 스케일링이 적용되지 않은 경우, Dollar Index 값을 직접 표시
                            // 이 경우, Y축 스케일링은 Gold에 맞춰져 있으므로 라벨이 이상하게 보일 수 있습니다.
                            // 대신 Gold 스케일링에 맞춰진 Silver Interval을 사용하거나, 더 나은 처리를 고려해야 합니다.
                            // 여기서는 간단히 원래 DollarIndexData의 값을 사용하되, 해당 값에 맞는 위치에만 표시
                            return Text(
                              value.toStringAsFixed(1), // 원래값을 직접 표시
                              style: const TextStyle(
                                color: Colors.purple, // Dollar Index 색상
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        interval:
                            chartInterval *
                            (dollarIndexRange / goldPriceRange)
                                .abs(), // Gold interval 비율에 맞춰 조정
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
                      color: const Color(0xFFD4AF37), // Gold 색상
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots:
                          dollarIndexSpotsScaled, // 스케일링된 Dollar Index 데이터 사용
                      isCurved: true,
                      color: Colors.purple, // Dollar Index 색상
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minX: 0,
                  maxX: maxX,
                  minY: chartMinY, // Gold 가격 기준의 Y축 범위
                  maxY: chartMaxY, // Gold 가격 기준의 Y축 범위

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

                          String text;
                          Color color;
                          if (touchedSpot.barIndex == 0) {
                            // Gold 라인
                            text = 'Gold: ${touchedSpot.y.toStringAsFixed(2)}';
                            color = touchedSpot.bar.color ?? Colors.black;
                          } else {
                            // Dollar Index 라인 (스케일링된 값으로부터 원본 값 계산)
                            double originalDollarIndexValue = 0.0;
                            if (dollarIndexRange > 0 && goldPriceRange > 0) {
                              double normalizedValue =
                                  (touchedSpot.y - minGoldPrice) /
                                  goldPriceRange;
                              originalDollarIndexValue =
                                  normalizedValue * dollarIndexRange +
                                  minDollarIndex;
                            } else if (dollarIndexData.isNotEmpty &&
                                goldData.isNotEmpty) {
                              // 스케일링이 안된 경우 (goldPriceRange나 dollarIndexRange가 0인 경우)
                              // 대략적인 역계산을 시도 (첫 값 기준으로 스케일링된 경우)
                              double averageGoldPrice =
                                  goldData
                                      .map((e) => e.price)
                                      .reduce((a, b) => a + b) /
                                  goldData.length;
                              double firstDollarIndexPrice =
                                  dollarIndexData.first.price;
                              double scaleFactor =
                                  averageGoldPrice / firstDollarIndexPrice;
                              if (scaleFactor != 0) {
                                originalDollarIndexValue =
                                    touchedSpot.y / scaleFactor;
                              }
                            }
                            text =
                                'Dollar Index: ${originalDollarIndexValue.toStringAsFixed(2)}';
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
                      Container(width: 16, height: 2, color: Colors.purple),
                      const SizedBox(width: 4),
                      const Text(
                        'Dollar Index',
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
