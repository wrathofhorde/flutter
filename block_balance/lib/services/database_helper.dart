import 'package:flutter/widgets.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart';
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
    final rootPath = Directory.current.path;
    final path = join(rootPath, filePath);

    debugPrint('💾 Database Path: $path');

    final db = sqlite3.open(path);

    // 1. 지갑 테이블 생성
    db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        address TEXT NOT NULL,
        network TEXT NOT NULL,
        alias TEXT
      )
    ''');

    // 2. 거래 내역 테이블 생성
    db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tx_hash TEXT UNIQUE,
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

  // --- 지갑 관리 메서드 ---

  Future<void> insertWallet(String address, String network, String alias) async {
    final db = await database;
    db.execute(
      'INSERT INTO wallets (address, network, alias) VALUES (?, ?, ?)',
      [address.toLowerCase().trim(), network.toUpperCase(), alias.trim()],
    );
  }

  Future<List<Map<String, dynamic>>> getAllWallets() async {
    final db = await database;
    final ResultSet results = db.select(
      'SELECT * FROM wallets ORDER BY id DESC',
    );
    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>?> getWalletById(int id) async {
    final db = await database;
    final ResultSet results = db.select('SELECT * FROM wallets WHERE id = ?', [id]);
    return results.isEmpty ? null : Map<String, dynamic>.from(results.first);
  }

  // --- 거래 내역 관리 메서드 ---

  Future<bool> updateTransactionFee(String txHash, String fee) async {
    final db = await database;
    db.execute('UPDATE transactions SET txn_fee = ? WHERE tx_hash = ?', [fee, txHash]);
    return db.updatedRows > 0;
  }

  // [수정된 부분] 대량 거래 내역 삽입 시 0원 데이터 필터링 로직 추가
  Future<void> insertTransactionsBatch(
    List<List<Object?>> paramSets,
    String fileName,
  ) async {
    final db = await database;

    final insertStmt = db.prepare('''
      INSERT OR IGNORE INTO transactions 
      (tx_hash, block_no, unix_timestamp, date_time, from_address, to_address, token_value, token_name, token_symbol, txn_fee, network, wallet_id, source_file)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    int skipCount = 0;
    int insertCount = 0;

    try {
      for (var params in paramSets) {
        // params[6]이 token_value 위치 (위 쿼리의 순서 참고)
        String rawVal = params[6]?.toString().replaceAll(',', '').trim() ?? "0";
        double tokenValue = double.tryParse(rawVal) ?? 0.0;

        // --- 0원 데이터 필터링 ---
        if (tokenValue == 0) {
          skipCount++;
          continue; // DB에 넣지 않고 다음 루프로 건너뜀
        }

        insertStmt.execute([...params, fileName]);
        insertCount++;
      }
      
      if (skipCount > 0) {
        LogService().addLog('ℹ️ $fileName: 값이 0인 데이터 $skipCount건 제외됨 (성공: $insertCount건)');
      }
    } catch (e) {
      LogService().addLog('❌ DB 배치 삽입 에러: $e');
    } finally {
      insertStmt.dispose();
    }
  }

  Future<void> deleteWallet(int id) async {
    final db = await database;
    db.execute('DELETE FROM wallets WHERE id = ?', [id]);
  }

  // [추가 팁] 이미 DB에 들어있는 0원 데이터를 정리하고 싶을 때 사용
  Future<void> cleanupZeroValueTransactions() async {
    final db = await database;
    db.execute("DELETE FROM transactions WHERE CAST(REPLACE(token_value, ',', '') AS REAL) = 0");
    LogService().addLog('🧹 DB 내의 0원 데이터 정리 완료');
  }
}