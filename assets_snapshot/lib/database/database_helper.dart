// lib/database/database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/models/asset.dart';
import 'package:assets_snapshot/models/asset_snapshot.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'assets_snapshot.db');

    debugPrint('Database path (using getApplicationDocumentsDirectory): $path');
    debugPrint(path);
    return await openDatabase(
      path,
      version: 3, // 데이터베이스 버전 변경 (asset_location, asset_snapshots 테이블 추가)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // onUpgrade 콜백 추가
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE assets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,      -- 스네이크 케이스
        name TEXT NOT NULL,
        asset_type TEXT NOT NULL,
        asset_location TEXT NOT NULL,
        memo TEXT,
        purchase_price INTEGER,           -- 스네이크 케이스
        current_value INTEGER,            -- 스네이크 케이스
        last_profit_rate REAL,            -- 스네이크 케이스
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_snapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL,        -- 스네이크 케이스
        snapshot_date TEXT NOT NULL,      -- 스네이크 케이스
        purchase_price INTEGER,           -- 스네이크 케이스
        current_value INTEGER NOT NULL,   -- 스네이크 케이스 (AssetSnapshot 모델에 맞춰 not null 적용)
        profit_rate REAL NOT NULL,        -- 스네이크 케이스
        profit_rate_change REAL NOT NULL, -- 스네이크 케이스
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
      )
    ''');
    // asset_locations 테이블은 주석 처리 유지
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE assets ADD COLUMN asset_location TEXT NOT NULL DEFAULT 'domestic'",
      );
      // asset_snapshots 테이블이 없었다면 생성 (이전 스키마)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS asset_snapshots(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          asset_id INTEGER NOT NULL,
          snapshot_date TEXT NOT NULL,
          current_value REAL NOT NULL, -- 이전 버전에서는 purchase_price가 없었음
          FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
        )
      ''');
      debugPrint(
        'Upgraded to version 2: asset_location added, asset_snapshots created.',
      );
    }

    if (oldVersion < 3) {
      // asset_snapshots 테이블에 purchase_price 컬럼 추가
      await db.execute(
        "ALTER TABLE asset_snapshots ADD COLUMN purchase_price INTEGER",
      );
      // currentValue, profitRate, profitRateChange도 스네이크 케이스로 변경하려면
      // SQLite는 ALTER TABLE RENAME COLUMN을 지원합니다.
      // 하지만 이미 데이터가 있다면 복잡해질 수 있습니다.
      // ALTER TABLE asset_snapshots RENAME COLUMN currentValue TO current_value;
      // ALTER TABLE asset_snapshots RENAME COLUMN profitRate TO profit_rate;
      // ALTER TABLE asset_snapshots RENAME COLUMN profitRateChange TO profit_rate_change;
      // 복잡하므로 이 부분은 모델의 toMap/fromMap에서 처리하는 것이 더 일반적입니다.
      // DB 스키마는 최초 생성 시 맞춰놓고, 이후 마이그레이션은 컬럼 추가/삭제 위주로 합니다.
      debugPrint(
        'Upgraded to version 3: purchase_price added to asset_snapshots.',
      );
    }
  }

  // --- Account CRUD Operations ---
  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  Future<int> updateAccount(Account account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  /// 특정 계좌의 총 매수금액, 총 평가금액, 총 수익률을 계산합니다.
  Future<Map<String, double>> getAccountSummary(int accountId) async {
    final db = await database;
    // assets 테이블에서 해당 accountId에 속하는 모든 asset의
    // purchasePrice와 currentValue를 합산
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT
        SUM(purchasePrice) as totalPurchasePrice,
        SUM(currentValue) as totalCurrentValue
      FROM assets
      WHERE account_id = ?
    ''',
      [accountId],
    );

    double totalPurchasePrice =
        (result.first['totalPurchasePrice'] as num?)?.toDouble() ?? 0.0;
    double totalCurrentValue =
        (result.first['totalCurrentValue'] as num?)?.toDouble() ?? 0.0;
    double totalProfitRate = 0.0;

    if (totalPurchasePrice > 0) {
      totalProfitRate =
          ((totalCurrentValue - totalPurchasePrice) / totalPurchasePrice) * 100;
    }

    return {
      'totalPurchasePrice': totalPurchasePrice,
      'totalCurrentValue': totalCurrentValue,
      'totalProfitRate': totalProfitRate,
    };
  }

  // --- Asset CRUD Operations ---
  Future<int> insertAsset(Asset asset) async {
    final db = await database;
    final now = DateTime.now();
    asset.createdAt = asset.createdAt ?? now;
    asset.updatedAt = now; // 항상 현재 시간으로 업데이트
    return await db.insert(
      'assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Asset>> getAssetsByAccountId(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return Asset.fromMap(maps[i]);
    });
  }

  Future<Asset?> getAssetById(int assetId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'id = ?',
      whereArgs: [assetId],
    );
    if (maps.isNotEmpty) {
      return Asset.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAsset(Asset asset) async {
    final db = await database;
    asset.updatedAt = DateTime.now(); // 업데이트 시 updated_at 갱신
    return await db.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteAsset(int id) async {
    final db = await database;
    return await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  // --- AssetSnapshot CRUD Operations (New) ---
  Future<int> insertAssetSnapshot(AssetSnapshot snapshot) async {
    final db = await database;
    // UNIQUE(asset_id, snapshot_date) 제약 조건 때문에 replace 사용
    return await db.insert(
      'asset_snapshots',
      snapshot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AssetSnapshot>> getAssetSnapshotsByAssetId(int assetId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_snapshots',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'snapshot_date ASC', // 기본적으로 날짜 오름차순으로 가져옴
    );
    return List.generate(maps.length, (i) {
      return AssetSnapshot.fromMap(maps[i]);
    });
  }

  // 특정 종목의 특정 날짜 스냅샷을 가져옵니다.
  Future<AssetSnapshot?> getAssetSnapshotByDate(
    int assetId,
    String date,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_snapshots',
      where: 'asset_id = ? AND snapshot_date = ?',
      whereArgs: [assetId, date],
      limit: 1, // 최대 1개만 가져옴
    );
    if (maps.isNotEmpty) {
      return AssetSnapshot.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAssetSnapshot(int id) async {
    final db = await database;
    return await db.delete('asset_snapshots', where: 'id = ?', whereArgs: [id]);
  }
}
