import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart'; // 이제 필요 없으므로 주석 처리 가능

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    // 프로젝트 루트 디렉토리 경로 가져오기
    String currentDirectoryPath = Directory.current.path;
    // 프로젝트 루트에 block_balance.db 생성
    String path = join(currentDirectoryPath, "block_balance.db");

    debugPrint('새로운 Database 경로: $path');

    final db = sqlite3.open(path);

    // 테이블 초기화
    db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        address TEXT NOT NULL UNIQUE,
        network TEXT NOT NULL,
        alias TEXT
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        tx_hash TEXT PRIMARY KEY,
        block_no INTEGER,
        unix_timestamp INTEGER,
        date_time TEXT,
        from_address TEXT,
        to_address TEXT,
        token_value TEXT,
        token_symbol TEXT,
        token_name TEXT,
        contract_address TEXT,
        txn_fee TEXT,
        network TEXT,
        wallet_id INTEGER,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
      );
    ''');

    return db;
  }

  // ... 나머지 fetchAll, execute, insertTransactionsBatch 코드는 동일하게 유지
  Future<List<Map<String, dynamic>>> fetchAll(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final db = await database;
    final ResultSet result = db.select(sql, params);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> execute(String sql, [List<Object?> params = const []]) async {
    final db = await database;
    db.execute(sql, params);
  }

  Future<void> insertTransactionsBatch(List<List<Object?>> paramSets) async {
    final db = await database;

    // 1. 중복(스캠) 데이터 삭제를 위한 쿼리 준비
    final deleteStmt = db.prepare('DELETE FROM transactions WHERE tx_hash = ?');

    // 2. 신규 삽입을 위한 쿼리 준비 (OR REPLACE 제외)
    final insertStmt = db.prepare('''
    INSERT INTO transactions 
    (tx_hash, block_no, unix_timestamp, date_time, from_address, to_address, token_value, token_name, token_symbol, contract_address, txn_fee, network, wallet_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''');

    int duplicateCount = 0;

    try {
      for (var params in paramSets) {
        final String txHash = params[0].toString();

        // 해당 tx_hash가 이미 존재하는지 확인
        final existing = db.select(
          'SELECT tx_hash FROM transactions WHERE tx_hash = ?',
          [txHash],
        );

        if (existing.isNotEmpty) {
          // 중복 발견 시: 기존 데이터 삭제 및 로그 출력 후 해당 루프 스킵
          deleteStmt.execute([txHash]);
          duplicateCount++;
          debugPrint('🚫 스캠(중복) 데이터 감지 및 삭제 완료: $txHash');
          continue; // 삽입하지 않고 다음 트랜잭션으로 이동
        }

        // 중복이 없을 때만 삽입 실행
        try {
          insertStmt.execute(params);
        } catch (e) {
          debugPrint('❌ 삽입 중 기타 오류 발생: $e');
        }
      }
      debugPrint('✅ 작업 완료 (중복 삭제된 건수: $duplicateCount)');
    } finally {
      deleteStmt.dispose();
      insertStmt.dispose();
    }
  }
}
