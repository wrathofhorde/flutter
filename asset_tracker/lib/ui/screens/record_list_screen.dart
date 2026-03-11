import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅용 (pub add intl 필요)
import '../../models/asset_model.dart';
import '../../services/database_service.dart';

class RecordListScreen extends StatefulWidget {
  final AssetItem assetItem;

  const RecordListScreen({super.key, required this.assetItem});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  List<AssetRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    final data = await DatabaseService.getRecordsByAsset(widget.assetItem.id);
    setState(() => _records = data);
  }

  void _showAddRecordDialog({AssetRecord? existingRecord}) {
    final purchaseController = TextEditingController(
      text:
          existingRecord?.purchaseAmount.toString() ??
          (_records.isNotEmpty ? _records.first.purchaseAmount.toString() : ''),
    );
    final evalController = TextEditingController(
      text:
          existingRecord?.evaluationAmount.toString() ??
          (_records.isNotEmpty
              ? _records.first.evaluationAmount.toString()
              : ''),
    );
    DateTime selectedDate = existingRecord?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingRecord == null ? '기록 추가' : '기록 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  "날짜: ${DateFormat('yyyy-MM').format(selectedDate)}",
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  // 월 단위 선택을 위해 간단히 구현 (실제 앱에선 전용 피커 추천)
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
              TextField(
                controller: purchaseController,
                decoration: const InputDecoration(labelText: '매수 금액 (원금)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: evalController,
                decoration: const InputDecoration(labelText: '평가 금액 (현재가)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService.addAssetRecord(
                  widget.assetItem.id,
                  DateTime(selectedDate.year, selectedDate.month), // 월 단위로 정규화
                  double.tryParse(purchaseController.text) ?? 0,
                  double.tryParse(evalController.text) ?? 0,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                _refreshRecords();
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.assetItem.name} 기록')),
      body: ListView.builder(
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          final profit = record.evaluationAmount - record.purchaseAmount;
          final percent = record.profitRate;

          return ListTile(
            title: Text(DateFormat('yyyy년 MM월').format(record.date)),
            subtitle: Text(
              "매수: ${record.purchaseAmount.toInt()} / 평가: ${record.evaluationAmount.toInt()}",
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${profit > 0 ? '+' : ''}${profit.toInt()}",
                  style: TextStyle(
                    color: profit >= 0 ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${percent.toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: profit >= 0 ? Colors.red : Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => _showAddRecordDialog(existingRecord: record),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
