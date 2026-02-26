import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbHelper.database;
      // contract_address가 제거된 새로운 스키마에 맞춘 쿼리
      final List<Map<String, dynamic>> data = db
          .select('''
        SELECT id, tx_hash, date_time, from_address, to_address, 
               token_value, token_name, token_symbol, txn_fee, network 
        FROM transactions 
        ORDER BY unix_timestamp DESC
      ''')
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  String _shortenAddress(String? address) {
    if (address == null || address.length < 10) return address ?? '';
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 내역 조회'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? const Center(child: Text('조회된 데이터가 없습니다.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('날짜')),
                    DataColumn(label: Text('심볼')),
                    DataColumn(label: Text('수량')),
                    DataColumn(label: Text('From')),
                    DataColumn(label: Text('To')),
                    DataColumn(label: Text('수수료(Fee)')),
                    DataColumn(label: Text('네트워크')),
                  ],
                  rows: _transactions.map((tx) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(tx['date_time'].toString().split(' ')[0]),
                        ), // 날짜만 표시
                        DataCell(Text(tx['token_symbol'] ?? '')),
                        DataCell(Text(tx['token_value'] ?? '0')),
                        DataCell(Text(_shortenAddress(tx['from_address']))),
                        DataCell(Text(_shortenAddress(tx['to_address']))),
                        DataCell(
                          Text(
                            tx['txn_fee'] == '0' || tx['txn_fee'] == null
                                ? '-'
                                : tx['txn_fee'].toString(),
                          ),
                        ),
                        DataCell(Text(tx['network'] ?? '')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
