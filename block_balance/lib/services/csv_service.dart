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

    if (fileName.toLowerCase().startsWith('pol_')) {
      await _parseAndProcessPol(fields, walletId, network, fileName);
    }
    // eth_ 접두사 처리 추가
    else if (fileName.toLowerCase().startsWith('eth_')) {
      await _parseAndProcessEth(fields, walletId, network, fileName);
    } else if (fileName.toLowerCase().startsWith('prc20_')) {
      final batch = _parsePrc20(fields, walletId, network);
      await _dbHelper.insertTransactionsBatch(batch, fileName);
      LogService().addLog('📊 [$fileName] ${batch.length}건 처리 완료');
    } else if (fileName.toLowerCase().startsWith('erc20_')) {
      final batch = _parseErc20(fields, walletId, network);
      await _dbHelper.insertTransactionsBatch(batch, fileName);
      LogService().addLog('📊 [$fileName] ${batch.length}건 (USDT) 처리 완료');
    }
  }

  Future<void> _parseAndProcessEth(
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
      // 이더리움 파일 필드: [7]Value_IN(ETH), [8]Value_OUT(ETH), [10]TxnFee(ETH)
      String valIn = row[7].toString();
      String valOut = row[8].toString();
      String txnFee = row[10].toString();

      double vIn = double.tryParse(valIn.replaceAll(',', '')) ?? 0;
      double vOut = double.tryParse(valOut.replaceAll(',', '')) ?? 0;

      // 1. ETH 자체 전송 내역이 있는 경우 (새로운 트랜잭션으로 삽입)
      if (vIn > 0 || vOut > 0) {
        insertBatch.add([
          txHash,
          row[1], // block_no
          row[2], // unix_timestamp
          row[3].toString(), // date_time
          row[4].toString().toLowerCase(), // from
          row[5].toString().toLowerCase(), // to
          (vIn > 0 ? valIn : valOut),
          "ETHEREUM",
          "ETH",
          txnFee,
          network,
          walletId,
        ]);
      }
      // 2. 밸류는 없지만 수수료가 발생한 경우 (기존 erc20_ 데이터 수수료 업데이트)
      else if (double.tryParse(txnFee.replaceAll(',', '')) != 0) {
        bool updated = await _dbHelper.updateTransactionFee(txHash, txnFee);
        if (updated) updateCount++;
      }
    }

    if (insertBatch.isNotEmpty) {
      await _dbHelper.insertTransactionsBatch(insertBatch, fileName);
    }
    LogService().addLog(
      '📊 [$fileName] ETH 삽입: ${insertBatch.length} / 수수료 매칭: $updateCount',
    );
  }

  List<List<Object?>> _parseErc20(
    List<List<dynamic>> fields,
    int walletId,
    String network,
  ) {
    List<List<Object?>> batch = [];

    // index 0은 헤더이므로 1부터 시작
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 11) continue;

      // CSV 구조 기반 인덱스:
      // [0]TxHash, [3]DateTime, [4]From, [5]To, [6]Value, [9]TokenName, [10]Symbol
      String tokenName = row[9].toString();

      // "Tether USD"인 경우만 필터링
      if (tokenName == "Tether USD") {
        batch.add([
          row[0].toString(), // tx_hash
          row[1], // block_no
          row[2], // unix_timestamp
          row[3].toString(), // date_time
          row[4].toString().toLowerCase(), // from_address
          row[5].toString().toLowerCase(), // to_address
          row[6].toString(), // token_value
          tokenName, // token_name
          row[10].toString(), // token_symbol (USDT)
          '0', // txn_fee (추후 업데이트)
          network, // network
          walletId, // wallet_id
        ]);
      }
    }
    return batch;
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
