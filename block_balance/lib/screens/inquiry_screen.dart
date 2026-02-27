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

  // 데이터 집계 및 조회 로직
  Future<void> _fetchAndSummarize() async {
    setState(() => _isLoading = true);

    try {
      final db = await _dbHelper.database;
      final ethThreshold =
          double.tryParse(_ethThresholdController.text) ?? 0.0001;
      final polThreshold =
          double.tryParse(_polThresholdController.text) ?? 0.0001;

      // 등록된 지갑 주소 목록 가져오기
      final List<Map<String, dynamic>> walletData = await _dbHelper
          .getAllWallets();
      final Set<String> registeredAddresses = walletData
          .map((w) => w['address'].toString().toLowerCase().trim())
          .toSet();

      // 트랜잭션 데이터 조회
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
            double.tryParse(tx['txn_fee'].toString().replaceAll(',', '')) ??
            0.0;
        String network = tx['network']?.toString().toUpperCase() ?? '';
        String symbol = tx['token_symbol'] ?? 'UNKNOWN';
        String fromAddr =
            tx['from_address']?.toString().toLowerCase().trim() ?? '';
        String toAddr = tx['to_address']?.toString().toLowerCase().trim() ?? '';

        DateTime? fullDate = DateTime.tryParse(tx['date_time'].toString());
        if (fullDate == null) continue;
        String dateStr = DateFormat('yyyy-MM-dd').format(fullDate);

        // 종류 판별 (출고, 입고, 스캠)
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
            'count': 0,
          };
        }

        aggregatedMap[groupKey]!['amount'] += value;
        aggregatedMap[groupKey]!['fee'] += fee;
        aggregatedMap[groupKey]!['count'] += 1;
      }

      List<Map<String, dynamic>> sortedList = aggregatedMap.values.toList();
      sortedList.sort((a, b) {
        int dateCompare = b['date'].compareTo(a['date']);
        if (dateCompare == 0) return a['network'].compareTo(b['network']);
        return dateCompare;
      });

      setState(() {
        _summaryData = sortedList;
      });
    } catch (e) {
      debugPrint("데이터 집계 오류: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String formatCryptoAmount(double value) {
    String fixedString = value.toStringAsFixed(18);
    RegExp removeTrailingZeros = RegExp(r'([.]*0+)(?!.*\d)');
    return fixedString.replaceAll(removeTrailingZeros, '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 내역 집계 분석'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState() // 로딩 중일 때 표시할 UI
                : _summaryData.isEmpty
                ? const Center(child: Text('데이터 집계 조회 버튼을 눌러주세요.'))
                : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  // 로딩 상태 전용 UI
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            "대량의 데이터를 집계 중입니다...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text("잠시만 기다려 주세요.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blueGrey[50],
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: _buildInput(
              "ETH Scam Threshold",
              _ethThresholdController,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: _buildInput(
              "POL Scam Threshold",
              _polThresholdController,
              Colors.purple,
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchAndSummarize,
            // 로딩 중일 때 아이콘도 변경하여 시각적 피드백 강화
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.analytics_outlined),
            label: Text(
              _isLoading ? "집계 중..." : "데이터 집계 조회",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        filled: true,
        fillColor: Colors.white,
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
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable(
              columnSpacing: 24,
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
                    '건수',
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
                          fontWeight: FontWeight.bold,
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
                    DataCell(Text('${data['count']}건')),
                    DataCell(Text(formatCryptoAmount(data['amount']))),
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
