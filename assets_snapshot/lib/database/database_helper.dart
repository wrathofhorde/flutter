import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // debugPrint 사용을 위해 임포트

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
    debugPrint(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 데이터베이스가 처음 생성될 때 실행되는 SQL 쿼리 (테이블 생성)
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
    // TODO: 버전 업그레이드 로직 (스키마 변경 시)
    // 예: if (oldVersion < 2) { await db.execute("ALTER TABLE Accounts ADD COLUMN new_column TEXT"); }
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

  // TODO: 각 테이블에 대한 CRUD (Create, Read, Update, Delete) 메서드 추가 예정
}
