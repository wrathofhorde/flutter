import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';
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
        Decimal value = _toDecimal(tx['token_value']);
        Decimal fee = _toDecimal(tx['txn_fee']);

        String network = tx['network']?.toString().toUpperCase() ?? '';
        String symbol =
            tx['token_symbol']?.toString().toUpperCase() ?? 'UNKNOWN';
        String fromAddr =
            tx['from_address']?.toString().toLowerCase().trim() ?? '';
        String toAddr = tx['to_address']?.toString().toLowerCase().trim() ?? '';

        DateTime? fullDate = DateTime.tryParse(tx['date_time'].toString());
        if (fullDate == null) continue;
        String dateStr = DateFormat('yyyy-MM-dd').format(fullDate);

        // 1. 유형 분류
        String type = "기타";
        if (registeredAddresses.contains(fromAddr)) {
          type = "출고";
        } else if (registeredAddresses.contains(toAddr)) {
          Decimal threshold = (network == 'ETHEREUM')
              ? ethThreshold
              : polThreshold;
          type = (value < threshold) ? "스캠" : "입고";
        }

        // 2. [조건부 합산 로직]
        // 오직 '입고' 유형이면서 ETH/POL 인 경우에만 수수료 합산
        // '스캠'이나 '출고' 등은 수수료를 합산하지 않음 (기존 방식)
        Decimal calculatedValue = value;
        if (type == "입고" && (symbol == "ETH" || symbol == "POL")) {
          calculatedValue = value + fee;
        }

        String groupKey = "${dateStr}_${network}_${symbol}_$type";

        if (!aggregatedMap.containsKey(groupKey)) {
          aggregatedMap[groupKey] = {
            'date': dateStr,
            'network': network,
            'coin': symbol,
            'type': type,
            'amount': Decimal.zero,
            'fee': Decimal.zero,
            'count': 0,
          };
        }

        aggregatedMap[groupKey]!['amount'] += calculatedValue;
        aggregatedMap[groupKey]!['fee'] += fee;
        aggregatedMap[groupKey]!['count'] += 1;
      }

      List<Map<String, dynamic>> sortedList = aggregatedMap.values.toList();
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

  String formatDecimal(Decimal value) {
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 집계 (ETH/POL 입고 시 수수료 합산)'),
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
                ? const Center(child: Text('조회 결과가 없습니다.'))
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

  Decimal _toDecimal(dynamic value) {
    if (value == null) return Decimal.zero;
    String cleanValue = value.toString().replaceAll(',', '').trim();
    if (cleanValue.isEmpty || cleanValue == 'N/A') return Decimal.zero;
    return Decimal.tryParse(cleanValue) ?? Decimal.zero;
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

        Decimal value = _toDecimal(tx['token_value']);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.date} 상세 (${widget.coin} - ${widget.type})"),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
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

                // 상세 화면 표시 로직: 메인 화면 집계 로직과 동일하게 적용
                Decimal value = _toDecimal(tx['token_value']);
                Decimal fee = _toDecimal(tx['txn_fee']);
                String symbol = widget.coin.toUpperCase();

                String displayValue = tx['token_value'].toString();
                // '입고'일 때만 수수료 합산 표시
                if (widget.type == "입고" &&
                    (symbol == "ETH" || symbol == "POL")) {
                  displayValue = (value + fee).toString();
                }

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
                              displayValue,
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
