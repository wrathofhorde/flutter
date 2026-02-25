// lib/services/csv_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'database_helper.dart';

class CsvService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // network 인자 추가
  Future<void> importCsv(String filePath, int walletId, String network) async {
    final input = File(filePath).openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    if (fields.length <= 1) return;

    List<List<Object?>> transactionBatch = [];

    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 11) continue;

      transactionBatch.add([
        row[0].toString(), // tx_hash
        int.tryParse(row[1].toString()) ?? 0, // block_no
        int.tryParse(row[2].toString()) ?? 0, // unix_timestamp
        row[3].toString(), // date_time
        row[4].toString().toLowerCase(), // from_address
        row[5].toString().toLowerCase(), // to_address
        row[6].toString(), // token_value
        row[9].toString(), // token_name
        row[10].toString(), // token_symbol
        row[8].toString(), // contract_address
        '', // txn_fee
        network, // network (추가된 인자 사용)
        walletId, // wallet_id
      ]);
    }

    try {
      await _dbHelper.insertTransactionsBatch(transactionBatch);
    } catch (e) {
      rethrow;
    }
  }
}
