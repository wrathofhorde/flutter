import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import 'dart:math';
import 'dart:developer' as developer; // developer.log 사용을 위해 추가

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

    // 데이터 정렬 (안전을 위해 다시 확인)
    goldData.sort((a, b) => a.date.compareTo(b.date));
    silverData.sort((a, b) => a.date.compareTo(b.date));

    final DateTime firstDate = goldData.first.date;

    final double minGoldPrice = goldData.map((e) => e.price).reduce(min);
    final double maxGoldPrice = goldData.map((e) => e.price).reduce(max);
    final double minSilverPrice = silverData.map((e) => e.price).reduce(min);
    final double maxSilverPrice = silverData.map((e) => e.price).reduce(max);

    final double goldRange = maxGoldPrice - minGoldPrice;
    // 차트의 Y축 범위를 Gold 가격 기준으로 넓게 잡습니다.
    double chartMinY = minGoldPrice - goldRange * 0.1;
    double chartMaxY = maxGoldPrice + goldRange * 0.1;

    // Y축 범위가 너무 작아서 문제가 될 경우를 대비하여 최소 범위를 설정합니다.
    if (chartMaxY - chartMinY < 1.0) {
      // 최소 1.0의 범위는 확보
      chartMaxY = chartMinY + 1.0;
    }

    // Gold Spots: 날짜 차이를 x-값으로 사용
    final List<FlSpot> goldSpots = goldData
        .map(
          (data) => FlSpot(
            data.date.difference(firstDate).inDays.toDouble(),
            data.price,
          ),
        )
        .toList();

    // Silver Spots: Silver 가격을 Gold Y축 범위에 맞게 변환하여 Plot
    final List<FlSpot> silverSpots = silverData.map((data) {
      final double originalSilverPrice = data.price;
      final double silverRelativePosition =
          (maxSilverPrice - minSilverPrice) != 0
          ? (originalSilverPrice - minSilverPrice) /
                (maxSilverPrice - minSilverPrice)
          : 0.5; // Silver 가격 범위가 0일 경우 중간값으로 처리
      final double scaledSilverPriceForPlotting =
          chartMinY + silverRelativePosition * (chartMaxY - chartMinY);
      return FlSpot(
        data.date.difference(firstDate).inDays.toDouble(),
        scaledSilverPriceForPlotting,
      );
    }).toList();

    // X축 최대값 (마지막 날짜와 첫 날짜의 차이)
    final double maxX = goldData.last.date
        .difference(firstDate)
        .inDays
        .toDouble();

    // Gold Y축 interval 계산
    final double goldInterval = (chartMaxY - chartMinY > 0)
        ? (chartMaxY - chartMinY) / 4
        : 1.0;

    // --- REVISED silverInterval CALCULATION ---
    final double silverRange = maxSilverPrice - minSilverPrice;
    double silverInterval;

    // 은 가격 범위가 매우 작거나 0인 경우를 처리합니다.
    // 너무 작은 간격으로 라벨이 겹치는 것을 방지하기 위해 최소 간격을 설정합니다.
    if (silverRange <= 0.01) {
      // Silver 가격 범위가 거의 없으면 (0.01은 예시 임계값)
      silverInterval = 0.5; // 고정된 간격 사용 (데이터 특성에 맞게 조정 필요)
    } else {
      // 차트의 전체 Y축 높이를 고려하여 은 라벨 간격을 계산합니다.
      // 라벨의 밀도를 제어하기 위해 전체 차트 Y축 범위에 대한 비율로 계산
      int idealNumSilverLabels = 5; // 목표하는 은 라벨의 개수
      silverInterval = silverRange / (idealNumSilverLabels - 1);

      // 계산된 간격이 너무 작으면 최소 간격으로 조정
      if (silverInterval < 0.2) {
        // 이전 0.1에서 0.2로 상향 조정
        silverInterval = 0.2;
      }

      // 간격을 "보기 좋은" 숫자로 반올림 (예: 0.5 단위)
      silverInterval = (silverInterval * 2).ceilToDouble() / 2;
      if (silverInterval == 0) silverInterval = 0.5; // 0이 되는 경우 방지
    }
    developer.log(
      'Calculated silverInterval: $silverInterval (Min: $minSilverPrice, Max: $maxSilverPrice, Range: $silverRange)',
      name: 'GoldSilverChart',
    );
    // --- END REVISED silverInterval CALCULATION ---

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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          // Y축 값(value)을 원래 Silver 가격 범위로 역변환
                          final double chartRelativePosition =
                              (value - chartMinY) / (chartMaxY - chartMinY);
                          double originalSilverValue =
                              minSilverPrice +
                              chartRelativePosition *
                                  (maxSilverPrice - minSilverPrice);

                          // NaN, Infinity 또는 유효하지 않은 범위의 값에 대한 처리 강화
                          if (!originalSilverValue.isFinite ||
                              originalSilverValue <
                                  minSilverPrice -
                                      0.1 || // Silver 최소 가격보다 너무 작으면 표시 안 함
                              originalSilverValue > maxSilverPrice + 0.1) {
                            // Silver 최대 가격보다 너무 크면 표시 안 함
                            return const SizedBox.shrink();
                          }

                          // 이 부분이 핵심: interval에 맞는 라벨만 표시하여 겹침 방지
                          // originalSilverValue가 silverInterval의 배수에 '가깝게' 일치하는 경우에만 라벨을 표시합니다.
                          double remainder =
                              (originalSilverValue - minSilverPrice) %
                              silverInterval;
                          if (remainder < 0.01 ||
                              (silverInterval - remainder) < 0.01) {
                            // 오차 범위 0.01 허용
                            return Text(
                              originalSilverValue.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Color(0xFFA9A9A9),
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox.shrink(); // 조건을 만족하지 않으면 표시하지 않음
                        },
                        interval: silverInterval, // 개선된 silverInterval 사용
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

                          String text;
                          Color color;
                          if (touchedSpot.barIndex == 0) {
                            // Gold 라인
                            text = 'Gold: ${touchedSpot.y.toStringAsFixed(2)}';
                            color = touchedSpot.bar.color ?? Colors.black;
                          } else {
                            // Silver 라인
                            final double chartRelativePosition =
                                (touchedSpot.y - chartMinY) /
                                (chartMaxY - chartMinY);
                            final double originalSilverPrice =
                                minSilverPrice +
                                chartRelativePosition *
                                    (maxSilverPrice - minSilverPrice);
                            text =
                                'Silver: ${originalSilverPrice.toStringAsFixed(2)}';
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
