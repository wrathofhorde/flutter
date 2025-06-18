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
      version: 1,
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
    //
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

    List<Account> accounts = [];
    for (var map in maps) {
      Account account = Account.fromMap(map);
      // 각 계좌의 요약 정보 로드
      if (account.id != null) {
        Map<String, double> summary = await getAccountSummary(account.id!);
        account = account.copyWith(
          totalPurchasePrice: summary['totalPurchasePrice'],
          totalCurrentValue: summary['totalCurrentValue'],
          totalProfitRate: summary['totalProfitRate'],
        );
      }
      accounts.add(account);
    }
    return accounts;
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
        SUM(purchase_price) as totalPurchasePrice,
        SUM(current_value) as totalCurrentValue
      FROM assets
      WHERE account_id = ?
    ''',
      [accountId],
    );

    double totalPurchase =
        (result.isNotEmpty && result.first['totalPurchasePrice'] != null)
        ? (result.first['totalPurchasePrice'] as num).toDouble()
        : 0.0;
    double totalCurrent =
        (result.isNotEmpty && result.first['totalCurrentValue'] != null)
        ? (result.first['totalCurrentValue'] as num)
              .toDouble() // 수정: result.first['totalCurrentValue']로 수정해야 합니다
        : 0.0;

    // 이전에 발생했던 오타를 수정합니다: `currentValue` -> `totalCurrentValue`
    totalCurrent =
        (result.isNotEmpty && result.first['totalCurrentValue'] != null)
        ? (result.first['totalCurrentValue'] as num).toDouble()
        : 0.0;

    double totalProfitRate = 0.0;
    if (totalPurchase > 0) {
      totalProfitRate =
          ((totalCurrent - totalPurchase) / totalPurchase) * 100.0;
    }

    return {
      'totalPurchasePrice': totalPurchase,
      'totalCurrentValue': totalCurrent,
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
