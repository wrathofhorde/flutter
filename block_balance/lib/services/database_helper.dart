import 'package:flutter/widgets.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'log_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('block_balance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Directory.current.path는 .exe 파일이 실행되는 위치(루트)를 반환합니다.
    final rootPath = Directory.current.path;
    final path = join(rootPath, filePath);

    // 디버깅을 위해 콘솔에 DB 위치 출력 (로그 콘솔에서 확인 가능)
    debugPrint('💾 Database Path: $path');

    final db = sqlite3.open(path);

    db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        address TEXT NOT NULL,
        network TEXT NOT NULL,
        alias TEXT
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tx_hash TEXT,
        block_no INTEGER,
        unix_timestamp INTEGER,
        date_time TEXT,
        from_address TEXT,
        to_address TEXT,
        token_value TEXT,
        token_name TEXT,
        token_symbol TEXT,
        txn_fee TEXT,
        network TEXT,
        wallet_id INTEGER,
        source_file TEXT,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
      )
    ''');
    return db;
  }

  // 수수료 업데이트 로직 (void 반환값 문제 해결)
  Future<bool> updateTransactionFee(String txHash, String fee) async {
    final db = await database;

    // 1. execute는 반환값이 void이므로 바로 실행
    db.execute('UPDATE transactions SET txn_fee = ? WHERE tx_hash = ?', [
      fee,
      txHash,
    ]);

    // 2. 영향받은 행의 수 확인 (이 프로퍼티는 int를 반환함)
    final changes = db.updatedRows;

    if (changes == 0) {
      LogService().addLog('⚠️ [미등록 해시] $txHash');
      return false;
    }
    return true;
  }

  Future<void> insertTransactionsBatch(
    List<List<Object?>> paramSets,
    String fileName,
  ) async {
    final db = await database;

    Map<String, int> hashCount = {};
    for (var params in paramSets) {
      String txHash = params[0].toString();
      hashCount[txHash] = (hashCount[txHash] ?? 0) + 1;
    }

    final deleteStmt = db.prepare(
      'DELETE FROM transactions WHERE tx_hash = ? AND source_file = ?',
    );
    final insertStmt = db.prepare('''
      INSERT OR IGNORE INTO transactions 
      (tx_hash, block_no, unix_timestamp, date_time, from_address, to_address, token_value, token_name, token_symbol, txn_fee, network, wallet_id, source_file)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    try {
      for (var params in paramSets) {
        final String txHash = params[0].toString();
        if (hashCount[txHash]! > 1) {
          deleteStmt.execute([txHash, fileName]);
          continue;
        }
        insertStmt.execute([...params, fileName]);
      }
    } finally {
      deleteStmt.dispose();
      insertStmt.dispose();
    }
  }

  Future<List<Map<String, dynamic>>> getAllWallets() async {
    final db = await database;
    final ResultSet results = db.select('SELECT * FROM wallets');
    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>?> getWalletById(int id) async {
    final db = await database;
    final ResultSet results = db.select('SELECT * FROM wallets WHERE id = ?', [
      id,
    ]);
    return results.isEmpty ? null : Map<String, dynamic>.from(results.first);
  }
}
