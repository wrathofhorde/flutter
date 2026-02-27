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
    final ethThreshold = double.tryParse(_ethThresholdController.text) ?? 0.0;
    final polThreshold = double.tryParse(_polThresholdController.text) ?? 0.0;

    // 1. 등록된 지갑 주소 가져오기
    final List<Map<String, dynamic>> walletData = await _dbHelper
        .getAllWallets();
    final Set<String> registeredAddresses = walletData
        .map((w) => w['address'].toString().toLowerCase())
        .toSet();

    // 2. 데이터 로드
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
      String fromAddr = tx['from_address']?.toString().toLowerCase() ?? '';
      String toAddr = tx['to_address']?.toString().toLowerCase() ?? '';

      // 날짜 추출
      DateTime? fullDate = DateTime.tryParse(tx['date_time'].toString());
      if (fullDate == null) continue;
      String dateStr = DateFormat('yyyy-MM-dd').format(fullDate);

      // 3. 입고/출고/스캠 분류 로직
      String type = "기타";

      if (registeredAddresses.contains(fromAddr)) {
        type = "출고";
      } else if (registeredAddresses.contains(toAddr)) {
        // 입고인 경우에만 스캠 체크 수행
        double currentThreshold = (network == 'ETHEREUM')
            ? ethThreshold
            : polThreshold;

        if (value <= currentThreshold) {
          type = "스캠"; // 임계값보다 작거나 같으면 스캠으로 분류
        } else {
          type = "입고";
        }
      }

      // 4. 복합 키 생성 및 집계
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

    setState(() {
      _summaryData = aggregatedMap.values.toList();
      _summaryData.sort((a, b) => b['date'].compareTo(a['date']));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상세 거래 집계 조회')),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _summaryData.isEmpty
                ? const Center(child: Text('데이터를 조회하세요.'))
                : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  // 상단 필터 UI
  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInput("ETH Scam", _ethThresholdController)),
              const SizedBox(width: 8),
              Expanded(child: _buildInput("POL Scam", _polThresholdController)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchAndSummarize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text("조회"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }

  // 요청하신 필드 구성의 테이블
  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 25,
          headingRowColor: WidgetStateProperty.all(
            Colors.blueGrey[50],
          ), // MaterialStateProperty -> WidgetStateProperty (최신 버전 대응)
          columns: const [
            DataColumn(label: Text('날짜')),
            DataColumn(label: Text('네트워크')),
            DataColumn(label: Text('코인')),
            DataColumn(label: Text('종류')),
            DataColumn(label: Text('거래량')),
            DataColumn(label: Text('수수료')),
          ],
          rows: _summaryData.map((data) {
            return DataRow(
              cells: [
                DataCell(Text(data['date'].toString())),
                DataCell(Text(data['network'].toString())),
                DataCell(Text(data['coin'].toString())),
                // 에러 났던 부분 수정: data[type] -> data['type']
                DataCell(
                  Text(
                    data['type'].toString(),
                    style: TextStyle(
                      color: data['type'] == '입고' ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text(data['amount'].toStringAsFixed(4))),
                DataCell(Text(data['fee'].toStringAsFixed(6))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
