// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_snapshot/models/account.dart'; // Account 모델 클래스 임포트

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'investment_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Accounts Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Assets Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Assets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        asset_type TEXT NOT NULL,
        memo TEXT,
        UNIQUE(account_id, name),
        FOREIGN KEY (account_id) REFERENCES Accounts(id) ON DELETE CASCADE
      )
    ''');

    // AccountSnapshots Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS AccountSnapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        snapshot_date TEXT NOT NULL,
        evaluated_amount INTEGER NOT NULL,
        purchase_amount INTEGER NOT NULL,
        profit_loss INTEGER NOT NULL,
        yield_percentage REAL NOT NULL,
        yield_change_percentage REAL,
        UNIQUE(account_id, snapshot_date),
        FOREIGN KEY (account_id) REFERENCES Accounts(id) ON DELETE CASCADE
      )
    ''');

    // AssetSnapshots Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS AssetSnapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        snapshot_date TEXT NOT NULL UNIQUE,
        total_evaluated_amount INTEGER NOT NULL,
        total_purchase_amount INTEGER NOT NULL,
        total_profit_loss INTEGER NOT NULL,
        overall_yield_percentage REAL NOT NULL,
        overall_yield_change_percentage REAL
      )
    ''');

    debugPrint("Database created and tables initialized!");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint("Database upgraded from version $oldVersion to $newVersion");
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> deleteDb() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'investment_tracker.db');
    await deleteDatabase(path);
    _database = null;
    debugPrint("Database deleted!");
  }

  // --- Accounts 테이블 CRUD 메서드 시작 ---

  // Create (계좌 추가)
  Future<int> insertAccount(Account account) async {
    final db = await database; // 데이터베이스 인스턴스 가져오기
    // toMap() 메서드를 사용하여 Account 객체를 Map<String, dynamic>으로 변환
    final id = await db.insert(
      'Accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    ); // 충돌 시 대체
    debugPrint('Account inserted: ${account.name} with id: $id');
    return id;
  }

  // Read (모든 계좌 조회)
  Future<List<Account>> getAccounts() async {
    final db = await database;
    // Accounts 테이블에서 모든 데이터 조회 (최신 업데이트 순으로 정렬)
    final List<Map<String, dynamic>> maps = await db.query(
      'Accounts',
      orderBy: 'updated_at DESC',
    );

    // Map 리스트를 Account 객체 리스트로 변환
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  // Read (특정 ID의 계좌 조회)
  Future<Account?> getAccountById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Accounts',
      where: 'id = ?', // id가 일치하는 행 조회
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null; // 해당 ID의 계좌가 없으면 null 반환
  }

  // Update (계좌 정보 업데이트)
  Future<int> updateAccount(Account account) async {
    final db = await database;
    // id를 기준으로 Account 객체의 모든 필드를 업데이트
    final rowsAffected = await db.update(
      'Accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint(
      'Account updated: ${account.name}, rows affected: $rowsAffected',
    );
    return rowsAffected; // 업데이트된 행의 수 반환
  }

  // Delete (계좌 삭제)
  Future<int> deleteAccount(int id) async {
    final db = await database;
    // id를 기준으로 계좌 삭제
    final rowsDeleted = await db.delete(
      'Accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Account deleted with id: $id, rows deleted: $rowsDeleted');
    return rowsDeleted; // 삭제된 행의 수 반환
  }

  // --- Accounts 테이블 CRUD 메서드 끝 ---
}
