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

  final String coinName;
  final List<FlSpot> spots;
  final Color lineColor;
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

    final double currentMinY =
        spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.95;
    final double currentMaxY =
        spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.05;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        // Column 위젯 추가
        crossAxisAlignment: CrossAxisAlignment.stretch, // 너비 전체를 차지하도록
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '$coinName 가격 변화', // 그래프 타이틀
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            // LineChart가 남은 공간을 모두 차지하도록 Expanded 추가
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
                        final date = DateTime.parse(
                          fullCoinData[value.toInt()].date,
                        );
                        final formatter = DateFormat('yy/MM/dd');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            formatter.format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 70,
                      getTitlesWidget: (value, meta) {
                        if ((value - currentMaxY).abs() <
                            (currentMaxY * 0.01)) {
                          return const Text('');
                        }
                        return Text(
                          numberFormat.format(value.toInt()),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.right,
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
                minY: currentMinY,
                maxY: currentMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: const LineTouchData(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
