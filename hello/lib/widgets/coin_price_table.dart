import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class CoinPriceTable extends StatelessWidget {
  const CoinPriceTable({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.yearAggregatedData,
  });

  final String startDate;
  final String endDate;
  final Map<String, dynamic>? yearAggregatedData;

  @override
  Widget build(BuildContext context) {
    const double subtitleFontSize = 18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$startDate ~ $endDate',
          style: const TextStyle(
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: yearAggregatedData == null
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ), // 데이터 로딩 중 표시
                )
              : Table(
                  border: TableBorder.all(color: Colors.grey.shade400),
                  defaultColumnWidth: const FlexColumnWidth(1.0),
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeaderCell('코인'),
                        _buildTableHeaderCell('평균가'),
                        _buildTableHeaderCell('최고가'),
                        _buildTableHeaderCell('최저가'),
                      ],
                    ),
                    _buildTableDataRow('BTC', yearAggregatedData!['btc']),
                    _buildTableDataRow('ETH', yearAggregatedData!['eth']),
                    _buildTableDataRow('XRP', yearAggregatedData!['xrp']),
                  ],
                ),
        ),
      ],
    );
  }

  // 기존 _buildTableDataRow 함수와 동일
  TableRow _buildTableDataRow(String coinName, Map<String, dynamic> data) {
    final avg = data['avg'] as int;
    final max = data['max'] as int;
    final min = data['min'] as int;

    final numberFormat = NumberFormat('#,###', 'en_US');

    return TableRow(
      children: [
        _buildTableCell(coinName, textAlign: TextAlign.center),
        _buildTableCell("${numberFormat.format(avg)}원"),
        _buildTableCell("${numberFormat.format(max)}원"),
        _buildTableCell("${numberFormat.format(min)}원"),
      ],
    );
  }

  // 기존 _buildTableCell 함수와 동일
  Widget _buildTableCell(
    String text, {
    TextAlign textAlign = TextAlign.right,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: 'Cascadia Code', // 폰트 패밀리 적용
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  // 기존 _buildTableHeaderCell 함수와 동일
  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.center, // 헤더는 가운데 정렬
        style: const TextStyle(
          fontFamily: 'Cascadia Code', // 폰트 패밀리 적용
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
