import 'dart:io';
import 'package:csv/csv.dart';
import 'database_helper.dart';
import 'log_service.dart';

class CsvService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 파일명에 따라 네트워크를 강제하고, CSV 내 주소를 기반으로 지갑 ID를 자동 매칭합니다.
  Future<void> importCsv(String filePath) async {
    final file = File(filePath);
    // 대용량 파일 대응을 위해 비동기로 읽기
    final input = await file.readAsString();
    final fields = const CsvToListConverter().convert(input);
    final fileName = filePath.split(Platform.pathSeparator).last.toLowerCase();

    if (fields.length < 2) {
      LogService().addLog('⚠️ [$fileName] 처리할 데이터가 없습니다.');
      return;
    }

    if (fileName.startsWith('int_')) {
      await _parseAndProcessInt(fields, "INTERNAL", fileName);
    } else if (fileName.startsWith('pol_')) {
      await _parseAndProcessPol(fields, "POLYGON", fileName);
    } else if (fileName.startsWith('eth_')) {
      await _parseAndProcessEth(fields, "ETHEREUM", fileName);
    } else if (fileName.startsWith('prc20_')) {
      await _parseAndProcessToken(fields, "POLYGON", fileName, isPrc: true);
    } else if (fileName.startsWith('erc20_')) {
      await _parseAndProcessToken(fields, "ETHEREUM", fileName, isPrc: false);
    } else {
      LogService().addLog('❌ [$fileName] 지원하지 않는 파일 형식입니다.');
    }
  }

  /// 주소를 기반으로 등록된 지갑 ID를 조회하는 헬퍼 메서드
  Future<int> _findWalletId(String from, String to) async {
    final wallets = await _dbHelper.getAllWallets();
    for (var w in wallets) {
      String addr = w['address'].toString().toLowerCase();
      if (from.toLowerCase() == addr || to.toLowerCase() == addr) {
        return w['id'] as int;
      }
    }
    return 0; // 매칭되는 지갑이 없을 경우 기본값
  }

  // --- 폴리곤 Internal 파싱 ---
  Future<void> _parseAndProcessInt(List<List<dynamic>> fields, String network, String fileName) async {
    final headers = fields[0].map((e) => e.toString().trim()).toList();
    int idxHash = headers.indexOf('Transaction Hash');
    int idxValueIn = headers.indexOf('Value_IN(POL)');
    int idxFrom = headers.indexOf('From');
    int idxTo = headers.indexOf('TxTo');

    List<List<Object?>> insertBatch = [];
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      double vIn = double.tryParse(row[idxValueIn].toString().replaceAll(',', '')) ?? 0;
      if (vIn > 0) {
        int wId = await _findWalletId(row[idxFrom].toString(), row[idxTo].toString());
        insertBatch.add([
          row[idxHash].toString(), row[headers.indexOf('Blockno')], row[headers.indexOf('UnixTimestamp')],
          row[headers.indexOf('DateTime (UTC+9)')].toString(), row[idxFrom].toString().toLowerCase(),
          row[idxTo].toString().toLowerCase(), vIn.toString(), "POLYGON", "POL", "0", network, wId,
        ]);
      }
    }
    if (insertBatch.isNotEmpty) await _dbHelper.insertTransactionsBatch(insertBatch, fileName);
    LogService().addLog('✅ [$fileName] $network ${insertBatch.length}건 완료');
  }

  // --- 메인넷(ETH/POL) 파싱 ---
  Future<void> _parseAndProcessEth(List<List<dynamic>> fields, String network, String fileName) async => 
      _parseAndProcessMain(fields, network, fileName, "ETH");
  
  Future<void> _parseAndProcessPol(List<List<dynamic>> fields, String network, String fileName) async => 
      _parseAndProcessMain(fields, network, fileName, "POL");

  Future<void> _parseAndProcessMain(List<List<dynamic>> fields, String network, String fileName, String symbol) async {
    List<List<Object?>> insertBatch = [];
    int updateCount = 0;
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 11) continue;
      String txHash = row[0].toString();
      double vIn = double.tryParse(row[7].toString().replaceAll(',', '')) ?? 0;
      double vOut = double.tryParse(row[8].toString().replaceAll(',', '')) ?? 0;
      String fee = row[10].toString();

      if (vIn > 0 || vOut > 0) {
        int wId = await _findWalletId(row[4].toString(), row[5].toString());
        insertBatch.add([
          txHash, row[1], row[2], row[3], row[4].toString().toLowerCase(),
          row[5].toString().toLowerCase(), (vIn > 0 ? row[7] : row[8]).toString(),
          symbol == "ETH" ? "ETHEREUM" : "POLYGON", symbol, fee, network, wId,
        ]);
      } else if (double.tryParse(fee.replaceAll(',', '')) != 0) {
        if (await _dbHelper.updateTransactionFee(txHash, fee)) updateCount++;
      }
    }
    if (insertBatch.isNotEmpty) await _dbHelper.insertTransactionsBatch(insertBatch, fileName);
    LogService().addLog('✅ [$fileName] 삽입:${insertBatch.length}/업데이트:$updateCount');
  }

  // --- 토큰(ERC20/PRC20) 파싱 ---
  Future<void> _parseAndProcessToken(List<List<dynamic>> fields, String network, String fileName, {required bool isPrc}) async {
    List<List<Object?>> batch = [];
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 11) continue;
      String name = row[9].toString();
      bool isTarget = isPrc ? (name == "SUPER TRUST" || name == "USDT0") : (name == "Tether USD");
      
      if (isTarget) {
        int wId = await _findWalletId(row[4].toString(), row[5].toString());
        batch.add([
          row[0].toString(), row[1], row[2], row[3], row[4].toString().toLowerCase(),
          row[5].toString().toLowerCase(), row[6].toString(), name, row[10].toString(), '0', network, wId,
        ]);
      }
    }
    if (batch.isNotEmpty) await _dbHelper.insertTransactionsBatch(batch, fileName);
    LogService().addLog('✅ [$fileName] ${batch.length}건 완료');
  }
}