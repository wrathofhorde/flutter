import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CoinLineChart extends StatelessWidget {
  const CoinLineChart({
    super.key,
    required this.coinName,
    required this.spots,
    required this.lineColor,
    required this.fullCoinData,
  });

  final Color lineColor;
  final String coinName;
  final List<FlSpot> spots;
  final List<dynamic> fullCoinData;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'en_US');

    if (spots.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(child: Text('$coinName 데이터 로딩 중...')),
      );
    }

    // spots가 비어있지 않을 때만 minY와 maxY를 계산
    final double currentMinY =
        spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.95;
    final double currentMaxY =
        spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.05;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        // borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.transparent),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (fullCoinData.length / 5).floor().toDouble(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 ||
                      value.toInt() >= fullCoinData.length) {
                    return const Text('');
                  }
                  final date = DateTime.parse(fullCoinData[value.toInt()].date);
                  final formatter = DateFormat('yy/MM/dd');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      formatter.format(date),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  // Y축의 최대값과 가까운 경우 빈 텍스트를 반환하여 제거
                  if ((value - currentMaxY).abs() < (currentMaxY * 0.01)) {
                    // 오차 범위 1% 이내
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: Text(
                      numberFormat.format(value.toInt()),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: (fullCoinData.length - 1).toDouble(),
          minY: currentMinY, // 미리 계산된 minY 사용
          maxY: currentMaxY, // 미리 계산된 maxY 사용
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 1.2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpot) {
                final numberFormat = NumberFormat('#,###', 'en_US');
                return touchedSpot
                    .map(
                      (spot) => LineTooltipItem(
                        numberFormat.format(spot.y.round().toInt()),
                        TextStyle(color: Colors.white),
                      ),
                    )
                    .toList();
              },
              getTooltipColor: (touchedSpot) =>
                  const Color.fromARGB(196, 158, 158, 158),
            ),
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((int index) {
                    // 터치된 지점의 수직선 스타일
                    final flLine = FlLine(
                      color: lineColor,
                      strokeWidth: 1.2,
                      dashArray: [5, 5], // 점선으로 표시
                    );
                    // 터치된 지점의 점 스타일
                    final dotData = FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 2,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: lineColor,
                        );
                      },
                    );
                    return TouchedSpotIndicatorData(flLine, dotData);
                  }).toList();
                },
          ),
        ),
      ),
    );
  }
}
