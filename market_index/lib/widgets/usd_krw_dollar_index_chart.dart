// lib/widgets/usd_krw_dollar_index_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:market_index/utils/chart_common.dart';
import '../models/data_models.dart';
import 'dart:math';

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
    final DateTime firstDate =
        usdKrwData.first.date; // USD/KRW 데이터의 첫 날짜를 기준으로 함

    // USD/KRW 데이터의 최소/최대 가격 및 Y축 패딩
    final double minUsdKrw = usdKrwData.map((e) => e.rate).reduce(min);
    final double maxUsdKrw = usdKrwData.map((e) => e.rate).reduce(max);
    final double usdKrwPaddingY = (maxUsdKrw - minUsdKrw) * 0.1;
    final double finalMinUsdKrwY = minUsdKrw - usdKrwPaddingY;
    final double finalMaxUsdKrwY = maxUsdKrw + usdKrwPaddingY;

    // Dollar Index 데이터의 최소/최대 가격 및 Y축 패딩 (라벨링을 위함)
    final double minDollarIndex = dollarIndexData
        .map((e) => e.price)
        .reduce(min);
    final double maxDollarIndex = dollarIndexData
        .map((e) => e.price)
        .reduce(max);
    final double dollarIndexPaddingY = (maxDollarIndex - minDollarIndex) * 0.1;
    final double finalMinDollarIndexY = minDollarIndex - dollarIndexPaddingY;
    final double finalMaxDollarIndexY = maxDollarIndex + dollarIndexPaddingY;

    // USD/KRW Spots 생성
    final List<FlSpot> usdKrwSpots = usdKrwData
        .map(
          (data) => FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            data.rate,
          ),
        )
        .toList();

    // Dollar Index Spots 생성 - USD/KRW 스케일에 맞춰 변환
    final List<FlSpot> dollarIndexSpots = dollarIndexData.map((data) {
      final double originalDollarIndexY = data.price;
      double scaledDollarIndexY;

      // 달러 인덱스 가격 범위가 0인 경우 예외 처리
      if ((finalMaxDollarIndexY - finalMinDollarIndexY).abs() < 1e-9) {
        scaledDollarIndexY = finalMinUsdKrwY;
      } else {
        // 달러 인덱스 값을 USD/KRW Y축 범위로 스케일링
        scaledDollarIndexY =
            (originalDollarIndexY - finalMinDollarIndexY) *
                (finalMaxUsdKrwY - finalMinUsdKrwY) /
                (finalMaxDollarIndexY - finalMinDollarIndexY) +
            finalMinUsdKrwY;
      }
      return FlSpot(
        data.date.difference(firstDate).inDays.toDouble(),
        scaledDollarIndexY,
      );
    }).toList();

    final double maxX = usdKrwData.last.date
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
              'USD/KRW vs Dollar Index',
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
                        'USD/KRW',
                        style: TextStyle(
                          color: ChartColor.usdkrw, // USD/KRW 색상과 맞춤
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                              value.toStringAsFixed(0), // 환율은 정수로 표시
                              style: const TextStyle(
                                color: ChartColor.usdkrw, // USD/KRW 라벨 색상 (주황색)
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // 글자 크기 조정
                              ),
                              textAlign: TextAlign.left,
                            ),
                          );
                        },
                        reservedSize: 50, // 여유 공간 확보
                        interval:
                            (finalMaxUsdKrwY - finalMinUsdKrwY) /
                            5, // USD/KRW 가격에 맞춰 간격 조정
                      ),
                    ),
                    rightTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Dollar Index',
                        style: TextStyle(
                          color: ChartColor.dollarIndex, // Dollar Index 색상과 맞춤
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      axisNameSize: 25,
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // 차트의 현재 Y값 (USD/KRW 스케일)을 달러 인덱스 스케일로 역변환하여 라벨로 표시
                          double dollarIndexEquivalentValue;
                          if ((finalMaxUsdKrwY - finalMinUsdKrwY).abs() <
                              1e-9) {
                            dollarIndexEquivalentValue = finalMinDollarIndexY;
                          } else {
                            dollarIndexEquivalentValue =
                                (value - finalMinUsdKrwY) *
                                    (finalMaxDollarIndexY -
                                        finalMinDollarIndexY) /
                                    (finalMaxUsdKrwY - finalMinUsdKrwY) +
                                finalMinDollarIndexY;
                          }
                          return SideTitleWidget(
                            space: 8.0,
                            meta: meta,
                            child: Text(
                              dollarIndexEquivalentValue.toStringAsFixed(
                                1,
                              ), // 소수점 한 자리까지 표시
                              style: const TextStyle(
                                color: ChartColor
                                    .dollarIndex, // 달러 인덱스 라벨 색상 (초록색)
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // 글자 크기 조정
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                        reservedSize: 50, // 여유 공간 확보
                        interval:
                            (finalMaxUsdKrwY - finalMinUsdKrwY) /
                            5, // 기본 차트 Y축 범위에 맞춰 간격 조정
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: ChartColor.border, width: 1),
                  ),
                  minX: 0,
                  maxX: maxX,
                  minY: finalMinUsdKrwY, // 차트의 전체 Y축 범위는 USD/KRW 기준
                  maxY: finalMaxUsdKrwY, // 차트의 전체 Y축 범위는 USD/KRW 기준
                  lineBarsData: [
                    LineChartBarData(
                      spots: usdKrwSpots,
                      isCurved: true,
                      color: ChartColor.usdkrw, // USD/KRW color
                      barWidth: ChartBar.width,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: dollarIndexSpots, // 변환된 dollarIndexSpots 사용
                      isCurved: true,
                      color: ChartColor.dollarIndex, // Dollar Index color
                      barWidth: ChartBar.width,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
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

                          if (color == ChartColor.usdkrw) {
                            // USD/KRW는 원래 값 그대로 사용
                            label = 'USD/KRW';
                            priceText = touchedSpot.y.toStringAsFixed(0);
                          } else if (color == ChartColor.dollarIndex) {
                            // Dollar Index는 터치된 Y값(USD/KRW 스케일)을 달러 인덱스 스케일로 역변환하여 표시
                            label = 'Dollar Index';
                            double originalDollarIndexPrice;
                            if ((finalMaxUsdKrwY - finalMinUsdKrwY).abs() <
                                1e-9) {
                              originalDollarIndexPrice = finalMinDollarIndexY;
                            } else {
                              originalDollarIndexPrice =
                                  (touchedSpot.y - finalMinUsdKrwY) *
                                      (finalMaxDollarIndexY -
                                          finalMinDollarIndexY) /
                                      (finalMaxUsdKrwY - finalMinUsdKrwY) +
                                  finalMinDollarIndexY;
                            }
                            priceText = originalDollarIndexPrice
                                .toStringAsFixed(1);
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
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Container(width: 16, height: 2, color: ChartColor.usdkrw),
                      const SizedBox(width: 4),
                      const Text('USD/KRW', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 2,
                        color: ChartColor.dollarIndex,
                      ),
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
