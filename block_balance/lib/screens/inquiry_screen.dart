import 'dart:io';
import 'dart:ui'; // FontFeature를 위해 필요
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart'; // [추가] Decimal 패키지
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

  // 정밀한 계산을 위해 String에서 바로 Decimal로 변환하는 헬퍼 함수
  Decimal _toDecimal(dynamic value) {
    if (value == null) return Decimal.zero;
    String cleanValue = value.toString().replaceAll(',', '').trim();
    if (cleanValue.isEmpty || cleanValue == 'N/A') return Decimal.zero;
    return Decimal.tryParse(cleanValue) ?? Decimal.zero;
  }

  Future<void> _fetchAndSummarize() async {
    setState(() => _isLoading = true);

    try {
      final db = await _dbHelper.database;

      // 임계값은 비교용이므로 double로 유지해도 무방하나 일관성을 위해 Decimal로 처리
      final ethThreshold = _toDecimal(_ethThresholdController.text);
      final polThreshold = _toDecimal(_polThresholdController.text);

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
        // [수정] Decimal 연산 적용
        Decimal value = _toDecimal(tx['token_value']);
        Decimal fee = _toDecimal(tx['txn_fee']);

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
          Decimal threshold = (network == 'ETHEREUM')
              ? ethThreshold
              : polThreshold;
          type = (value < threshold) ? "스캠" : "입고";
        }

        String groupKey = "${dateStr}_${network}_${symbol}_$type";

        if (!aggregatedMap.containsKey(groupKey)) {
          aggregatedMap[groupKey] = {
            'date': dateStr,
            'network': network,
            'coin': symbol,
            'type': type,
            'amount': Decimal.zero, // 초기값을 Decimal.zero로 설정
            'fee': Decimal.zero,
            'count': 0,
          };
        }

        // [수정] Decimal 합산 (오차 없음)
        aggregatedMap[groupKey]!['amount'] += value;
        aggregatedMap[groupKey]!['fee'] += fee;
        aggregatedMap[groupKey]!['count'] += 1;
      }

      List<Map<String, dynamic>> sortedList = aggregatedMap.values.toList();

      // 정렬 로직 (기존과 동일)
      sortedList.sort((a, b) {
        int dateCompare = b['date'].compareTo(a['date']);
        if (dateCompare != 0) return dateCompare;
        int networkCompare = a['network'].compareTo(b['network']);
        if (networkCompare != 0) return networkCompare;
        int coinCompare = a['coin'].compareTo(b['coin']);
        if (coinCompare != 0) return coinCompare;
        return a['type'].compareTo(b['type']);
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

  // Decimal을 보기 좋게 포맷팅
  String formatDecimal(Decimal value) {
    return value.toString(); // Decimal은 자동으로 불필요한 0을 제거한 문자열을 반환합니다.
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
                ? const Center(child: CircularProgressIndicator())
                : _summaryData.isEmpty
                ? const Center(child: Text('데이터 집계 조회 버튼을 눌러주세요.'))
                : _buildDataTable(),
          ),
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
            icon: const Icon(Icons.analytics_outlined),
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
              showCheckboxColumn: false,
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
                Color rowColor = Colors.transparent;
                if (data['network'] == 'ETHEREUM') {
                  rowColor = Colors.blue.withValues(alpha: 0.1);
                } else if (data['network'] == 'POLYGON') {
                  rowColor = Colors.purple.withValues(alpha: 0.1);
                }

                return DataRow(
                  color: WidgetStateProperty.all(rowColor),
                  onSelectChanged: (selected) {
                    if (selected == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionDetailScreen(
                            date: data['date'],
                            network: data['network'],
                            coin: data['coin'],
                            type: data['type'],
                            ethThreshold: _toDecimal(
                              _ethThresholdController.text,
                            ),
                            polThreshold: _toDecimal(
                              _polThresholdController.text,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  cells: [
                    DataCell(Text(data['date'])),
                    DataCell(Text(data['network'])),
                    DataCell(Text(data['coin'])),
                    DataCell(
                      Text(
                        data['type'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text('${data['count']}건')),
                    DataCell(Text(formatDecimal(data['amount']))),
                    DataCell(Text(formatDecimal(data['fee']))),
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

class TransactionDetailScreen extends StatefulWidget {
  final String date;
  final String network;
  final String coin;
  final String type;
  final Decimal ethThreshold;
  final Decimal polThreshold;

  const TransactionDetailScreen({
    super.key,
    required this.date,
    required this.network,
    required this.coin,
    required this.type,
    required this.ethThreshold,
    required this.polThreshold,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  List<Map<String, dynamic>> _details = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> rawData = db
        .select(
          'SELECT * FROM transactions WHERE substr(date_time, 1, 10) = ? AND network = ? AND token_symbol = ?',
          [widget.date, widget.network, widget.coin],
        )
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    final List<Map<String, dynamic>> walletData = await DatabaseHelper.instance
        .getAllWallets();
    final Set<String> registeredAddresses = walletData
        .map((w) => w['address'].toString().toLowerCase().trim())
        .toSet();

    setState(() {
      _details = rawData.where((tx) {
        String fromAddr =
            tx['from_address']?.toString().toLowerCase().trim() ?? '';
        String toAddr = tx['to_address']?.toString().toLowerCase().trim() ?? '';

        // 상세 페이지 필터링 시에도 Decimal 적용
        String cleanValue =
            tx['token_value']?.toString().replaceAll(',', '') ?? '0';
        Decimal value = Decimal.tryParse(cleanValue) ?? Decimal.zero;

        String currentType = "기타";
        if (registeredAddresses.contains(fromAddr)) {
          currentType = "출고";
        } else if (registeredAddresses.contains(toAddr)) {
          Decimal threshold = (widget.network == 'ETHEREUM')
              ? widget.ethThreshold
              : widget.polThreshold;
          currentType = (value < threshold) ? "스캠" : "입고";
        }
        return currentType == widget.type;
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _downloadCsv() async {
    if (_details.isEmpty) return;
    try {
      List<List<dynamic>> rows = [
        [
          "DateTime",
          "TokenValue",
          "Symbol",
          "TX Hash",
          "From",
          "To",
          "Fee",
          "Source",
        ],
      ];

      for (var tx in _details) {
        rows.add([
          tx['date_time'],
          tx['token_value'], // 원본 문자열 유지 (쉼표 등 포함)
          tx['token_symbol'],
          tx['tx_hash'],
          tx['from_address'],
          tx['to_address'],
          tx['txn_fee'],
          tx['source_file'] ?? "",
        ]);
      }

      String csvContent = const ListToCsvConverter().convert(rows);
      final rootPath = Directory.current.path;
      String title = "${widget.date}_${widget.coin}_${widget.type}".replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final filePath = p.join(rootPath, '$title.csv');
      final file = File(filePath);

      await file.writeAsString(csvContent);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("CSV 저장 완료"),
            content: SelectionArea(
              child: Text("실행 파일 폴더에 저장되었습니다:\n\n$filePath"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("다운로드 실패: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.date} 상세 (${widget.coin} - ${widget.type})"),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _downloadCsv,
            icon: const Icon(Icons.file_download),
            tooltip: "CSV 다운로드",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _details.isEmpty
          ? const Center(child: Text("내역이 없습니다."))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _details.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final tx = _details[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tx['date_time'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Row(
                          children: [
                            SelectableText(
                              "${tx['token_value']}", // 화면에는 원본 값 표시
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.coin,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInlineInfo("TX HASH", tx['tx_hash'] ?? 'N/A'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInlineInfo(
                            "FROM",
                            tx['from_address'] ?? 'unknown',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInlineInfo(
                            "TO",
                            tx['to_address'] ?? 'unknown',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Fee: ",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SelectableText(
                              "${tx['txn_fee']} ${widget.network}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        if (tx['source_file'] != null)
                          Text(
                            tx['source_file'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildInlineInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
