import 'dart:io';
import 'package:csv/csv.dart';
import 'database_helper.dart';
import 'log_service.dart';

class CsvService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> importCsv(String filePath, int walletId, String network) async {
    final file = File(filePath);
    final input = file.readAsStringSync();
    final fields = const CsvToListConverter().convert(input);
    final fileName = filePath.split(Platform.pathSeparator).last.toLowerCase();

    if (fileName.startsWith('prc20_')) {
      final batch = _parsePrc20(fields, walletId, network);
      await _dbHelper.insertTransactionsBatch(batch, fileName);
      LogService().addLog('📊 [$fileName] 완료: ${batch.length}건');
    } else if (fileName.startsWith('pol_')) {
      await _parseAndProcessPol(fields, walletId, network, fileName);
    }
    // ... erc20, eth 등 다른 접두어 처리 추가 가능
  }

  Future<void> _parseAndProcessPol(
    List<List<dynamic>> fields,
    int walletId,
    String network,
    String fileName,
  ) async {
    List<List<Object?>> insertBatch = [];
    int updateCount = 0;

    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 11) continue;

      String txHash = row[0].toString();
      String valIn = row[7].toString();
      String valOut = row[8].toString();
      String txnFee = row[10].toString();

      double vIn = double.tryParse(valIn.replaceAll(',', '')) ?? 0;
      double vOut = double.tryParse(valOut.replaceAll(',', '')) ?? 0;
      double fee = double.tryParse(txnFee.replaceAll(',', '')) ?? 0;

      if (vIn > 0 || vOut > 0) {
        insertBatch.add([
          txHash,
          row[1],
          row[2],
          row[3],
          row[4].toString().toLowerCase(),
          row[5].toString().toLowerCase(),
          (vIn > 0 ? valIn : valOut),
          "POLYGON",
          "POL",
          txnFee,
          network,
          walletId,
        ]);
      } else if (fee > 0) {
        final bool isUpdated = await _dbHelper.updateTransactionFee(
          txHash,
          txnFee,
        );
        if (isUpdated) updateCount++;
      }
    }

    if (insertBatch.isNotEmpty) {
      await _dbHelper.insertTransactionsBatch(insertBatch, fileName);
    }
    LogService().addLog(
      '📊 [$fileName] 삽입: ${insertBatch.length}건 / 업데이트: $updateCount건',
    );
  }

  List<List<Object?>> _parsePrc20(
    List<List<dynamic>> fields,
    int walletId,
    String network,
  ) {
    List<List<Object?>> batch = [];
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 11) continue;
      String name = row[9].toString();
      if (name == "SUPER TRUST" || name == "USDT0") {
        batch.add([
          row[0].toString(),
          row[1],
          row[2],
          row[3],
          row[4].toString().toLowerCase(),
          row[5].toString().toLowerCase(),
          row[6].toString(),
          name,
          row[10].toString(),
          '0',
          network,
          walletId,
        ]);
      }
    }
    return batch;
  }
}
