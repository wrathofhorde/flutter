import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _selectedToken = 'All';
  List<String> _tokens = ['All']; // DB에서 동적으로 가져올 예정
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 초기 데이터(토큰 목록 및 전체 트랜잭션) 로드
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // 1. 존재하는 토큰 심볼 목록 가져오기
    final tokenData = await _dbHelper.fetchAll(
      'SELECT DISTINCT token_symbol FROM transactions',
    );
    final List<String> fetchedTokens = ['All'];
    for (var row in tokenData) {
      if (row['token_symbol'] != null) fetchedTokens.add(row['token_symbol']);
    }

    // 2. 전체 트랜잭션 조회
    await _loadTransactions();

    setState(() {
      _tokens = fetchedTokens;
      _isLoading = false;
    });
  }

  // 필터에 따른 트랜잭션 로드
  Future<void> _loadTransactions() async {
    String query = 'SELECT * FROM transactions';
    List<Object?> params = [];

    if (_selectedToken != 'All') {
      query += ' WHERE token_symbol = ?';
      params.add(_selectedToken);
    }
    query += ' ORDER BY unix_timestamp DESC LIMIT 100'; // 최신순 100개만

    final data = await _dbHelper.fetchAll(query, params);
    setState(() => _transactions = data);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '토큰 필터: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedToken,
                items: _tokens
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedToken = val!);
                  _loadTransactions();
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('새로고침'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionTable(),
          ),
        ],
      ),
    );
  }

  // 트랜잭션 결과 표 생성
  Widget _buildTransactionTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(label: Text('일시')),
              DataColumn(label: Text('토큰')),
              DataColumn(label: Text('수량')),
              DataColumn(label: Text('보낸 사람')),
              DataColumn(label: Text('받은 사람')),
              DataColumn(label: Text('해시')),
            ],
            rows: _transactions.map((tx) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(tx['date_time'].toString().split(' ')[0]),
                  ), // 날짜만 표시
                  DataCell(Text(tx['token_symbol'] ?? '')),
                  DataCell(
                    Text(
                      tx['token_value'] ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(_shortenAddress(tx['from_address']))),
                  DataCell(Text(_shortenAddress(tx['to_address']))),
                  DataCell(Text(_shortenAddress(tx['tx_hash']))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _shortenAddress(dynamic addr) {
    if (addr == null) return '';
    String s = addr.toString();
    if (s.length < 10) return s;
    return '${s.substring(0, 6)}...${s.substring(s.length - 4)}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
          const Text(
            '데이터가 없습니다. CSV를 먼저 업로드하세요.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
