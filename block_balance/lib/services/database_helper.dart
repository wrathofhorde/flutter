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
    // 윈도우 앱 루트 폴더(실행파일 위치)에 DB 생성
    final rootPath = Directory.current.path;
    final path = join(rootPath, filePath);

    // 디버깅용 경로 출력
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

  // 지갑 등록 (UI에서 발생하는 'insertWallet' 정의되지 않음 에러 해결)
  Future<void> insertWallet(
    String address,
    String network,
    String alias,
  ) async {
    final db = await database;
    db.execute(
      'INSERT INTO wallets (address, network, alias) VALUES (?, ?, ?)',
      [address.toLowerCase().trim(), network.toUpperCase(), alias.trim()],
    );
  }

  // 모든 지갑 가져오기
  Future<List<Map<String, dynamic>>> getAllWallets() async {
    final db = await database;
    final ResultSet results = db.select(
      'SELECT * FROM wallets ORDER BY id DESC',
    );
    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  // ID로 특정 지갑 정보 가져오기
  Future<Map<String, dynamic>?> getWalletById(int id) async {
    final db = await database;
    final ResultSet results = db.select('SELECT * FROM wallets WHERE id = ?', [
      id,
    ]);
    return results.isEmpty ? null : Map<String, dynamic>.from(results.first);
  }

  // --- 거래 내역 관리 메서드 ---

  // 수수료 업데이트 로직 (erc20 임포트 후 eth/pol 임포트 시 매칭용)
  Future<bool> updateTransactionFee(String txHash, String fee) async {
    final db = await database;

    db.execute('UPDATE transactions SET txn_fee = ? WHERE tx_hash = ?', [
      fee,
      txHash,
    ]);

    // 영향받은 행의 수 확인
    final changes = db.updatedRows;

    if (changes == 0) {
      // 매칭되는 해시가 없는 경우 로그만 남김 (스킵)
      return false;
    }
    return true;
  }

  // 대량 거래 내역 삽입 (CSV 임포트용)
  Future<void> insertTransactionsBatch(
    List<List<Object?>> paramSets,
    String fileName,
  ) async {
    final db = await database;

    // 1. UNIQUE 제약조건이 있으므로 DELETE 문과 중복 체크 Map이 아예 필요 없습니다.
    final insertStmt = db.prepare('''
      INSERT OR IGNORE INTO transactions 
      (tx_hash, block_no, unix_timestamp, date_time, from_address, to_address, token_value, token_name, token_symbol, txn_fee, network, wallet_id, source_file)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    try {
      // 2. 그냥 넣기만 하면 됩니다. 중복이면 DB가 알아서 IGNORE(무시)합니다.
      for (var params in paramSets) {
        insertStmt.execute([...params, fileName]);
      }
    } catch (e) {
      LogService().addLog('❌ DB 배치 삽입 에러: $e');
    } finally {
      insertStmt.dispose();
    }
  }

  // lib/services/database_helper.dart 내부에 추가
  Future<void> deleteWallet(int id) async {
    final db = await database;
    // 지갑을 삭제하면 해당 지갑의 거래 내역도 지울지 결정해야 하지만,
    // 일단 안전하게 지갑 정보만 삭제합니다.
    db.execute('DELETE FROM wallets WHERE id = ?', [id]);
  }
}
