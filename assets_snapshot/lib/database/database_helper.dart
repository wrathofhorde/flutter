// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/models/asset.dart'; // Asset 모델 클래스 임포트

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 4; // !!! 데이터베이스 버전 4로 증가 !!!

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
      version: _databaseVersion,
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
        purchasePrice INTEGER,
        currentValue INTEGER,
        lastProfitRate REAL,
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

    // !!! AssetSnapshots Table 수정 !!!
    await db.execute('''
      CREATE TABLE IF NOT EXISTS AssetSnapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL,  -- 외래 키: 어떤 종목의 스냅샷인지
        snapshot_date TEXT NOT NULL,
        purchase_price INTEGER NOT NULL,   -- 해당 스냅샷 시점의 매수금액
        current_value INTEGER NOT NULL,    -- 해당 스냅샷 시점의 평가금액
        profit_rate REAL NOT NULL,         -- 해당 스냅샷 시점의 수익률
        profit_rate_change REAL,           -- 해당 스냅샷 시점의 수익률 변화율
        UNIQUE(asset_id, snapshot_date),   -- 특정 종목의 특정 날짜 스냅샷은 유일해야 함
        FOREIGN KEY (asset_id) REFERENCES Assets(id) ON DELETE CASCADE
      )
    ''');

    debugPrint("Database created and tables initialized!");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint("Database upgraded from version $oldVersion to $newVersion");

    // 이전 버전에서 현재 버전으로 업그레이드 시
    // 중요: 개발 단계에서만 테이블 드롭 후 재생성을 사용하세요.
    // 실제 앱에서는 ALTER TABLE을 사용하여 데이터 유실을 방지해야 합니다.
    // 현재는 버전 4로 올리면서 AssetSnapshots 테이블 스키마를 변경하므로,
    // 해당 테이블을 드롭하고 재생성하는 것이 가장 간단합니다.
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS AssetSnapshots');
      // Assets 테이블의 컬럼 타입 변경 (REAL -> INTEGER)은 이미 버전 3에서 처리했으므로
      // 여기서는 AssetSnapshots만 다시 생성하면 됩니다.
      // 만약 Assets 테이블의 컬럼 타입도 변경해야 한다면, Assets 테이블도 DROP/CREATE 합니다.
      // 여기서는 AssetSnapshots 테이블의 스키마 변경만 반영합니다.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS AssetSnapshots(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          asset_id INTEGER NOT NULL,
          snapshot_date TEXT NOT NULL,
          purchase_price INTEGER NOT NULL,
          current_value INTEGER NOT NULL,
          profit_rate REAL NOT NULL,
          profit_rate_change REAL,
          UNIQUE(asset_id, snapshot_date),
          FOREIGN KEY (asset_id) REFERENCES Assets(id) ON DELETE CASCADE
        )
      ''');
    }
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
    final db = await database;
    final id = await db.insert(
      'Accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Account inserted: ${account.name} with id: $id');
    return id;
  }

  // Read (모든 계좌 조회)
  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Accounts',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  // Read (특정 ID의 계좌 조회)
  Future<Account?> getAccountById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  // Update (계좌 정보 업데이트)
  Future<int> updateAccount(Account account) async {
    final db = await database;
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
    return rowsAffected;
  }

  // Delete (계좌 삭제)
  Future<int> deleteAccount(int id) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'Accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Account deleted with id: $id, rows deleted: $rowsDeleted');
    return rowsDeleted;
  }

  // --- Accounts 테이블 CRUD 메서드 끝 ---

  // --- Assets 테이블 CRUD 메서드 시작 ---

  // Create (종목 추가)
  Future<int> insertAsset(Asset asset) async {
    final db = await database;
    final id = await db.insert(
      'Assets',
      asset.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.rollback, // 동일 계좌-종목명 중복 시 롤백 (오류 발생)
    );
    debugPrint(
      'Asset inserted: ${asset.name} (Account ID: ${asset.accountId}) with id: $id',
    );
    return id;
  }

  // Read (특정 계좌의 모든 종목 조회)
  Future<List<Asset>> getAssetsByAccountId(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Assets',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'name ASC', // 종목 이름순으로 정렬
    );
    return List.generate(maps.length, (i) {
      return Asset.fromMap(maps[i]);
    });
  }

  // Read (특정 ID의 종목 조회)
  Future<Asset?> getAssetById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Assets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Asset.fromMap(maps.first);
    }
    return null;
  }

  // Update (종목 정보 업데이트)
  Future<int> updateAsset(Asset asset) async {
    final db = await database;
    final rowsAffected = await db.update(
      'Assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
      conflictAlgorithm: ConflictAlgorithm.replace, // 충돌 시 대체
    );
    debugPrint(
      'Asset updated: ${asset.name} (Account ID: ${asset.accountId}), rows affected: $rowsAffected',
    );
    return rowsAffected;
  }

  // Delete (종목 삭제)
  Future<int> deleteAsset(int assetId) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'Assets',
      where: 'id = ?',
      whereArgs: [assetId],
    );
    debugPrint('Asset deleted with id: $assetId, rows deleted: $rowsDeleted');
    return rowsDeleted;
  }

  // Delete (특정 계좌의 모든 종목 삭제 - 계좌 삭제 시 함께 호출될 수 있음)
  Future<int> deleteAllAssetsByAccountId(int accountId) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'Assets',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    debugPrint(
      'All assets deleted for accountId: $accountId, rows deleted: $rowsDeleted',
    );
    return rowsDeleted;
  }

  // --- Assets 테이블 CRUD 메서드 끝 ---
}
