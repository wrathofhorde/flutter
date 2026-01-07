import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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

    final leftTitleWidth = 80.0;
    final double currentMinY =
        spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.95;
    final double currentMaxY =
        spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.05;

    return Container(
      // 기존 Container의 height와 decoration 유지
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10), // 기존 패딩 유지
      decoration: BoxDecoration(
        color: Colors.transparent, // 다시 원래 배경색으로 돌려놓거나 원하는 색으로 설정
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        // Stack 위젯을 사용하여 코인명과 차트를 겹치게 배치
        children: [
          // 1. 코인명 표시 (왼쪽 상단)
          Positioned(
            top: 4, // 상단에서 떨어진 거리
            left: leftTitleWidth, // 왼쪽에서 떨어진 거리
            child: Text(
              coinName,
              style: const TextStyle(
                fontSize: 14, // 글자 크기 조정
                fontWeight: FontWeight.bold,
                color: Colors.black87, // 글자색
              ),
            ),
          ),
          // 2. LineChart 위젯 (코인명 뒤에 위치)
          Padding(
            // 차트 내부 padding 조정 (코인명과의 겹침을 피하기 위해)
            padding: const EdgeInsets.only(
              top: 25.0,
              left: 0,
              right: 25,
              bottom: 10,
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // 상단 타이틀 비활성화
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (fullCoinData.length / 5).floor().toDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 ||
                            value.toInt() >= fullCoinData.length) {
                          return const Text('');
                        }
                        final date = DateTime.parse(
                          fullCoinData[value.toInt()].date,
                        );
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
                      reservedSize: leftTitleWidth,
                      getTitlesWidget: (value, meta) {
                        if ((value - currentMaxY).abs() <
                            (currentMaxY * 0.01)) {
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
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minX: 0,
                maxX: (fullCoinData.length - 1).toDouble(),
                minY: currentMinY,
                maxY: currentMaxY,
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
                    getTooltipItems: (touchedSpots) {
                      final numberFormat = NumberFormat('#,###', 'en_US');
                      return touchedSpots.map((spot) {
                        final int index = spot.x.toInt();
                        String dateString = '';
                        if (index >= 0 && index < fullCoinData.length) {
                          final date = DateTime.parse(fullCoinData[index].date);
                          final formatter = DateFormat('yyyy.MM.dd');
                          dateString = formatter.format(date);
                        }

                        return LineTooltipItem(
                          '$dateString\n'
                          '${numberFormat.format(spot.y.round().toInt())}원',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                    getTooltipColor: (touchedSpot) =>
                        const Color.fromARGB(240, 158, 158, 158),
                  ),
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((int index) {
                          final flLine = FlLine(
                            color: lineColor,
                            strokeWidth: 1.2,
                            dashArray: [5, 5],
                          );
                          final dotData = FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 2,
                                color: lineColor,
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
          ),
        ],
      ),
    );
  }
}
