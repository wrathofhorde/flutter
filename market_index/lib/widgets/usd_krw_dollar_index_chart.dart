// lib/widgets/usd_krw_dollar_index_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import 'dart:math';
import 'dart:developer' as developer;

class UsdKrwDollarIndexChart extends StatelessWidget {
  final List<UsdKrwData> usdKrwData;
  final List<DollarIndexData> dollarIndexData;
  final int monthsToShow;

  const UsdKrwDollarIndexChart({
    super.key,
    required this.usdKrwData,
    required this.dollarIndexData,
    required this.monthsToShow,
  });

  @override
  Widget build(BuildContext context) {
    if (usdKrwData.isEmpty || dollarIndexData.isEmpty) {
      return const Center(
        child: Text('USD/KRW 또는 Dollar Index 데이터를 불러올 수 없습니다.'),
      );
    }

    // 데이터 정렬
    usdKrwData.sort((a, b) => a.date.compareTo(b.date));
    dollarIndexData.sort((a, b) => a.date.compareTo(b.date));

    // 공통 날짜 범위의 시작점을 찾습니다.
    final DateTime firstDate = usdKrwData.first.date;

    // USD/KRW 데이터의 최소/최대
    final double minUsdKrw = usdKrwData.map((e) => e.rate).reduce(min);
    final double maxUsdKrw = usdKrwData.map((e) => e.rate).reduce(max);

    // Dollar Index 데이터의 최소/최대
    final double minDollarIndex = dollarIndexData
        .map((e) => e.price)
        .reduce(min);
    final double maxDollarIndex = dollarIndexData
        .map((e) => e.price)
        .reduce(max);

    // USD/KRW Spots 생성
    final List<FlSpot> usdKrwSpots = usdKrwData
        .map(
          (data) => FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            data.rate,
          ),
        )
        .toList();

    // Dollar Index 데이터 재조정 (스케일링)
    final double usdKrwRange = maxUsdKrw - minUsdKrw;
    final double dollarIndexRange = maxDollarIndex - minDollarIndex;

    List<FlSpot> dollarIndexSpotsScaled = [];

    if (dollarIndexRange > 0 && usdKrwRange > 0) {
      for (var data in dollarIndexData) {
        double normalizedDollarIndex =
            (data.price - minDollarIndex) / dollarIndexRange;
        double scaledDollarIndex =
            normalizedDollarIndex * usdKrwRange + minUsdKrw;
        dollarIndexSpotsScaled.add(
          FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            scaledDollarIndex,
          ),
        );
      }
    } else {
      // Dollar Index 범위가 0이거나 USD/KRW 범위가 0인 경우 (예: 데이터가 하나뿐이거나 모두 동일한 값)
      // 이 경우, 스케일링이 의미 없거나 오류가 발생할 수 있으므로, 기본값을 사용하거나 경고를 로깅합니다.
      developer.log(
        'Warning: Dollar Index range or USD/KRW range is zero. Cannot scale Dollar Index.',
        name: 'UsdKrwDollarIndexChart',
      );
      // 임시 스케일링 (USD/KRW의 첫 값을 기준으로 Dollar Index의 첫 값을 맞춤)
      if (usdKrwData.isNotEmpty && dollarIndexData.isNotEmpty) {
        double scaleFactor =
            usdKrwData.first.rate / dollarIndexData.first.price;
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
      usdKrwData.last.date.difference(firstDate).inDays.toDouble(),
      dollarIndexData.last.date.difference(firstDate).inDays.toDouble(),
    );

    // Y축 범위 및 interval 설정 (USD/KRW 가격 기준으로 통일)
    final double chartMinY = minUsdKrw - usdKrwRange * 0.1;
    final double chartMaxY = maxUsdKrw + usdKrwRange * 0.1;

    // Y축 interval 계산 (USD/KRW 가격 기준으로 통일)
    double chartInterval = (chartMaxY - chartMinY > 0)
        ? (chartMaxY - chartMinY) / 4
        : 1.0;
    // 환율은 보통 10단위 이상으로 변화하므로, 간격을 조정합니다.
    if (chartInterval < 10) {
      chartInterval = 10;
    }
    // 간격을 10, 20, 50, 100 등 보기 좋은 단위로 조정
    if (chartInterval > 0) {
      final List<double> commonIntervals = [
        1,
        2,
        5,
        10,
        20,
        50,
        100,
        200,
        500,
        1000,
      ];
      chartInterval = commonIntervals.firstWhere(
        (element) => element >= chartInterval,
        orElse: () => chartInterval.ceilToDouble(),
      );
    } else {
      chartInterval = 1.0; // 최소값
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'USD/KRW vs Dollar Index (지난 ${monthsToShow == 999 ? "모든" : monthsToShow}개월)',
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
                          // USD/KRW (왼쪽 Y축)
                          return Text(
                            value.toStringAsFixed(0), // 환율은 정수로 표시
                            style: const TextStyle(
                              color: Colors.orange, // USD/KRW 색상
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: chartInterval, // USD/KRW 기준의 interval
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          // Dollar Index (오른쪽 Y축) - 스케일링된 값을 실제 Dollar Index 값으로 역변환
                          if (dollarIndexRange > 0 && usdKrwRange > 0) {
                            // 1. 스케일링된 값을 0-1 범위로 역정규화
                            double normalizedValue =
                                (value - minUsdKrw) / usdKrwRange;
                            // 2. 역정규화된 값을 원래 Dollar Index 범위로 스케일링
                            double originalDollarIndexValue =
                                normalizedValue * dollarIndexRange +
                                minDollarIndex;

                            // interval에 맞는 라벨만 표시
                            // Dollar Index의 실제 범위에 비례하는 간격 사용
                            double dollarIndexDisplayInterval =
                                dollarIndexRange / 4; // 대략 4개의 라벨
                            if (dollarIndexDisplayInterval < 0.5)
                              dollarIndexDisplayInterval = 0.5; // 최소 간격

                            double remainder =
                                (originalDollarIndexValue - minDollarIndex) %
                                dollarIndexDisplayInterval;
                            if (remainder < 0.01 ||
                                (dollarIndexDisplayInterval - remainder) <
                                    0.01) {
                              return Text(
                                originalDollarIndexValue.toStringAsFixed(
                                  1,
                                ), // Dollar Index는 소수점 한 자리로 표시
                                style: const TextStyle(
                                  color: Colors.green, // Dollar Index 색상
                                  fontSize: 10,
                                ),
                              );
                            }
                          } else {
                            // 스케일링이 적용되지 않은 경우
                            // 현재 Y축 스케일에 맞춰진 달러 인덱스 값을 그대로 표시 (정확한 원래 값 아님)
                            return Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        interval:
                            chartInterval *
                            (dollarIndexRange / usdKrwRange)
                                .abs(), // USD/KRW interval 비율에 맞춰 조정
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
                      spots: usdKrwSpots,
                      isCurved: true,
                      color: Colors.orange, // USD/KRW 색상
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots:
                          dollarIndexSpotsScaled, // 스케일링된 Dollar Index 데이터 사용
                      isCurved: true,
                      color: Colors.green, // Dollar Index 색상
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minX: 0,
                  maxX: maxX,
                  minY: chartMinY, // USD/KRW 기준의 Y축 범위
                  maxY: chartMaxY, // USD/KRW 기준의 Y축 범위

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
                            // USD/KRW 라인
                            text =
                                'USD/KRW: ${touchedSpot.y.toStringAsFixed(2)}';
                            color = touchedSpot.bar.color ?? Colors.black;
                          } else {
                            // Dollar Index 라인 (스케일링된 값으로부터 원본 값 계산)
                            double originalDollarIndexValue = 0.0;
                            if (dollarIndexRange > 0 && usdKrwRange > 0) {
                              double normalizedValue =
                                  (touchedSpot.y - minUsdKrw) / usdKrwRange;
                              originalDollarIndexValue =
                                  normalizedValue * dollarIndexRange +
                                  minDollarIndex;
                            } else if (usdKrwData.isNotEmpty &&
                                dollarIndexData.isNotEmpty) {
                              // 스케일링이 안된 경우 (range가 0인 경우)
                              // 임시 스케일링이 적용된 경우의 역계산
                              double scaleFactor =
                                  usdKrwData.first.rate /
                                  dollarIndexData.first.price;
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
                      Container(width: 16, height: 2, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text('USD/KRW', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 16, height: 2, color: Colors.green),
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
