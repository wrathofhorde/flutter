// lib/database/database_helper.dart
import 'package:assets_snapshot/models/asset_snapshot.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/models/asset.dart'; // Asset 모델 클래스 임포트
import 'dart:async'; // Completer를 위해 추가

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static Completer<Database>?
  _databaseCompleter; // 추가: 데이터베이스 초기화 완료를 위한 Completer
  static const int _databaseVersion = 5; // 현재 데이터베이스 버전

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    // _database가 아직 null이면, 초기화 시작 또는 진행 중인 초기화 기다리기
    if (_databaseCompleter == null) {
      _databaseCompleter = Completer<Database>();
      _initDatabase()
          .then((db) {
            _database = db;
            _databaseCompleter!.complete(db);
          })
          .catchError((e) {
            // 에러 처리: _databaseCompleter를 완료시키지 않으면 get database 호출이 무한 대기할 수 있음
            _databaseCompleter!.completeError(e);
            _databaseCompleter = null; // 초기화 실패 시 completer 리셋
          });
    }
    return _databaseCompleter!.future;
  }

  Future<Database> _initDatabase() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'investment_tracker.db');
    debugPrint('DB 저장경로:$path'); // 데이터베이스 저장 경로 출력

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
        asset_location TEXT NOT NULL DEFAULT 'domestic', -- '국내/해외' 구분을 위한 필드 (DB에 'domestic'/'overseas' 저장)
        memo TEXT,
        purchasePrice INTEGER,    -- 매수금액 (정수형)
        currentValue INTEGER,     -- 현재가치 (정수형)
        lastProfitRate REAL,      -- 최종 수익률 (실수형)
        UNIQUE(account_id, name), -- 한 계좌에 동일한 이름의 자산은 중복될 수 없음
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

    // 버전 5로 업그레이드: Assets 테이블에 asset_location 컬럼 추가
    if (oldVersion < 5) {
      // ALTER TABLE로 컬럼 추가 (기존 데이터 유지)
      // SQLite는 ADD COLUMN 시 NOT NULL을 허용하지만 DEFAULT 값을 지정해야 함
      await db.execute(
        'ALTER TABLE Assets ADD COLUMN asset_location TEXT NOT NULL DEFAULT \'domestic\'',
      );
      debugPrint('Assets table upgraded: asset_location column added.');
    }
    // 다른 버전 업그레이드 로직은 여기에 추가될 수 있습니다.
    // 예를 들어, oldVersion < 4인 경우 AssetSnapshots 테이블 스키마 변경 로직 등
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _databaseCompleter = null; // Completer도 리셋
    }
  }

  Future<void> deleteDb() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'investment_tracker.db');
    await deleteDatabase(path);
    _database = null;
    _databaseCompleter = null; // Completer도 리셋
    debugPrint("Database deleted!");
  }

  // --- Accounts 테이블 CRUD 메서드 시작 ---

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

  Future<int> insertAsset(Asset asset) async {
    final db = await database;
    final id = await db.insert(
      'Assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
    debugPrint(
      'Asset inserted: ${asset.name} (Account ID: ${asset.accountId}) with id: $id',
    );
    return id;
  }

  Future<List<Asset>> getAssetsByAccountId(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Assets',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) {
      return Asset.fromMap(maps[i]);
    });
  }

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

  Future<int> updateAsset(Asset asset) async {
    final db = await database;
    final rowsAffected = await db.update(
      'Assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint(
      'Asset updated: ${asset.name} (Account ID: ${asset.accountId}), rows affected: $rowsAffected',
    );
    return rowsAffected;
  }

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

  // --- AssetSnapshots 테이블 CRUD 메서드 시작 ---

  Future<int> insertAssetSnapshot(AssetSnapshot snapshot) async {
    final db = await database;
    final id = await db.insert(
      'AssetSnapshots',
      snapshot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint(
      'AssetSnapshot inserted/updated: ${snapshot.snapshotDate} for Asset ID: ${snapshot.assetId} with id: $id',
    );
    return id;
  }

  Future<List<AssetSnapshot>> getAssetSnapshotsByAssetId(int assetId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'AssetSnapshots',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'snapshot_date ASC',
    );
    return List.generate(maps.length, (i) {
      return AssetSnapshot.fromMap(maps[i]);
    });
  }

  Future<AssetSnapshot?> getAssetSnapshotByAssetIdAndDate(
    int assetId,
    String date,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'AssetSnapshots',
      where: 'asset_id = ? AND snapshot_date = ?',
      whereArgs: [assetId, date],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AssetSnapshot.fromMap(maps.first);
    }
    return null;
  }

  Future<AssetSnapshot?> getLatestAssetSnapshotByAssetId(int assetId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'AssetSnapshots',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'snapshot_date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AssetSnapshot.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAssetSnapshot(AssetSnapshot snapshot) async {
    final db = await database;
    final rowsAffected = await db.update(
      'AssetSnapshots',
      snapshot.toMap(),
      where: 'id = ?',
      whereArgs: [snapshot.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint(
      'AssetSnapshot updated: ${snapshot.snapshotDate} for Asset ID: ${snapshot.assetId}, rows affected: $rowsAffected',
    );
    return rowsAffected;
  }

  Future<int> deleteAssetSnapshot(int snapshotId) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'AssetSnapshots',
      where: 'id = ?',
      whereArgs: [snapshotId],
    );
    debugPrint(
      'AssetSnapshot deleted with id: $snapshotId, rows deleted: $rowsDeleted',
    );
    return rowsDeleted;
  }

  Future<int> deleteAllAssetSnapshotsByAssetId(int assetId) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'AssetSnapshots',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
    debugPrint(
      'All AssetSnapshots deleted for assetId: $assetId, rows deleted: $rowsDeleted',
    );
    return rowsDeleted;
  }

  // --- 계좌별 총 자산 현황 조회 메서드 추가 ---
  Future<Map<String, double>> getAccountSummary(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT
        SUM(purchasePrice) AS totalPurchasePrice,
        SUM(currentValue) AS totalCurrentValue
      FROM Assets
      WHERE account_id = ? -- 여기 컬럼명은 데이터베이스 스키마와 일치해야 합니다. (account_id)
    ''',
      [accountId],
    );

    // SUM 함수는 결과가 없을 경우 null을 반환할 수 있으므로, null 처리 필수
    double totalPurchasePrice =
        (result.first['totalPurchasePrice'] as num?)?.toDouble() ?? 0.0;
    double totalCurrentValue =
        (result.first['totalCurrentValue'] as num?)?.toDouble() ?? 0.0;

    double totalProfitRate = 0.0;
    if (totalPurchasePrice != 0) {
      totalProfitRate =
          ((totalCurrentValue - totalPurchasePrice) / totalPurchasePrice) * 100;
    }

    return {
      'totalPurchasePrice': totalPurchasePrice,
      'totalCurrentValue': totalCurrentValue,
      'totalProfitRate': totalProfitRate,
    };
  }

  // ---------------------------------------------
}
