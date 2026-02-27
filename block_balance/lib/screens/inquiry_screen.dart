import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final TextEditingController _ethThresholdController = TextEditingController(
    text: "0.0001",
  );
  final TextEditingController _polThresholdController = TextEditingController(
    text: "0.0001",
  );

  List<Map<String, dynamic>> _summaryData = [];
  bool _isLoading = false;

  Future<void> _fetchAndSummarize() async {
    setState(() => _isLoading = true);

    final db = await _dbHelper.database;
    final ethThreshold =
        double.tryParse(_ethThresholdController.text) ?? 0.0001;
    final polThreshold =
        double.tryParse(_polThresholdController.text) ?? 0.0001;

    final List<Map<String, dynamic>> walletData = await _dbHelper
        .getAllWallets();
    final Set<String> registeredAddresses = walletData
        .map((w) => w['address'].toString().toLowerCase().trim())
        .toSet();

    final List<Map<String, dynamic>> rawData = db
        .select('''
      SELECT date_time, token_value, txn_fee, network, token_symbol, from_address, to_address 
      FROM transactions
    ''')
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    Map<String, Map<String, dynamic>> aggregatedMap = {};

    for (var tx in rawData) {
      double value =
          double.tryParse(tx['token_value'].toString().replaceAll(',', '')) ??
          0.0;
      double fee =
          double.tryParse(tx['txn_fee'].toString().replaceAll(',', '')) ?? 0.0;
      String network = tx['network']?.toString().toUpperCase() ?? '';
      String symbol = tx['token_symbol'] ?? 'UNKNOWN';
      String fromAddr =
          tx['from_address']?.toString().toLowerCase().trim() ?? '';
      String toAddr = tx['to_address']?.toString().toLowerCase().trim() ?? '';

      DateTime? fullDate = DateTime.tryParse(tx['date_time'].toString());
      if (fullDate == null) continue;
      String dateStr = DateFormat('yyyy-MM-dd').format(fullDate);

      String type = "기타";
      if (registeredAddresses.contains(fromAddr)) {
        type = "출고";
      } else if (registeredAddresses.contains(toAddr)) {
        double threshold = (network == 'ETHEREUM')
            ? ethThreshold
            : polThreshold;
        type = (value <= threshold) ? "스캠" : "입고";
      }

      String groupKey = "${dateStr}_${network}_${symbol}_$type";

      if (!aggregatedMap.containsKey(groupKey)) {
        aggregatedMap[groupKey] = {
          'date': dateStr,
          'network': network,
          'coin': symbol,
          'type': type,
          'amount': 0.0,
          'fee': 0.0,
        };
      }

      aggregatedMap[groupKey]!['amount'] += value;
      aggregatedMap[groupKey]!['fee'] += fee;
    }

    List<Map<String, dynamic>> sortedList = aggregatedMap.values.toList();
    sortedList.sort((a, b) {
      int dateCompare = b['date'].compareTo(a['date']);
      if (dateCompare == 0) {
        return a['network'].compareTo(b['network']);
      }
      return dateCompare;
    });

    setState(() {
      _summaryData = sortedList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 집계 분석 (텍스트 선택 가능)'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _summaryData.isEmpty
                ? const Center(child: Text('조회 버튼을 눌러주세요.'))
                : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blueGrey[50],
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: _buildInput(
              "ETH Scam Threshold",
              _ethThresholdController,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: _buildInput(
              "POL Scam Threshold",
              _polThresholdController,
              Colors.purple,
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchAndSummarize,
            icon: const Icon(Icons.search),
            label: const Text("데이터 집계 조회"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    Color color,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return SelectionArea(
      // <-- 테이블 전체를 SelectionArea로 감싸면 내부 텍스트 선택 가능
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 40,
              headingRowColor: WidgetStateProperty.all(Colors.blueGrey[100]),
              columns: const [
                DataColumn(
                  label: Text(
                    '날짜',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '네트워크',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '코인',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '종류',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '거래량 합계',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '수수료 합계',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _summaryData.map((data) {
                Color rowColor = data['network'] == 'ETHEREUM'
                    ? Colors.blue.withValues(alpha: 0.05)
                    : Colors.purple.withValues(alpha: 0.05);

                Color typeColor = Colors.grey;
                if (data['type'] == '입고') typeColor = Colors.blue[700]!;
                if (data['type'] == '출고') typeColor = Colors.red[700]!;
                if (data['type'] == '스캠') typeColor = Colors.orange[800]!;

                String formatCryptoAmount(double value) {
                  // 1. 최대 18자리 소수점까지 문자열로 변환
                  String fixedString = value.toStringAsFixed(18);

                  // 2. 정규식을 사용하여 소수점 뒤의 불필요한 0과 소수점 자체(예: 10.0 -> 10) 제거
                  RegExp removeTrailingZeros = RegExp(r'([.]*0+)(?!.*\d)');
                  return fixedString.replaceAll(removeTrailingZeros, '');
                }

                return DataRow(
                  color: WidgetStateProperty.all(rowColor),
                  cells: [
                    DataCell(Text(data['date'])),
                    DataCell(
                      Text(
                        data['network'],
                        style: TextStyle(
                          color: data['network'] == 'ETHEREUM'
                              ? Colors.blue[900]
                              : Colors.purple[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(Text(data['coin'])),
                    DataCell(
                      Text(
                        data['type'],
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 거래량: 최대 18자리 표시 및 0 제거 적용
                    DataCell(Text(formatCryptoAmount(data['amount']))),
                    // 수수료: 최대 18자리 표시 및 0 제거 적용
                    DataCell(Text(formatCryptoAmount(data['fee']))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
