// lib/database/database_helper.dart
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
    String path = join(await getDatabasesPath(), 'assets_snapshot.db');
    return await openDatabase(
      path,
      version: 2, // 데이터베이스 버전 변경 (asset_location, asset_snapshots 테이블 추가)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // onUpgrade 콜백 추가
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // accounts 테이블 생성
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // assets 테이블 생성
    // asset_location 컬럼 추가
    await db.execute('''
      CREATE TABLE assets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        asset_type TEXT NOT NULL,
        asset_location TEXT NOT NULL DEFAULT 'domestic', -- 기본값 설정
        memo TEXT,
        purchasePrice INTEGER,
        currentValue INTEGER,
        lastProfitRate REAL,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
      )
    ''');

    // asset_snapshots 테이블 생성 (새로 추가)
    await db.execute('''
      CREATE TABLE asset_snapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL,
        snapshot_date TEXT NOT NULL, -- YYYY-MM-DD 형식
        purchasePrice INTEGER NOT NULL,
        currentValue INTEGER NOT NULL,
        profitRate REAL NOT NULL,
        profitRateChange REAL NOT NULL,
        UNIQUE(asset_id, snapshot_date), -- 동일 종목의 같은 날짜 스냅샷 중복 방지
        FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 1 -> Version 2 업그레이드
      // assets 테이블에 asset_location 컬럼 추가 (이미 있다면 무시)
      try {
        await db.execute(
          "ALTER TABLE assets ADD COLUMN asset_location TEXT NOT NULL DEFAULT 'domestic'",
        );
      } catch (e) {
        print("asset_location column already exists or other error: $e");
      }

      // asset_snapshots 테이블 생성
      await db.execute('''
        CREATE TABLE asset_snapshots(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          asset_id INTEGER NOT NULL,
          snapshot_date TEXT NOT NULL, -- YYYY-MM-DD 형식
          purchasePrice INTEGER NOT NULL,
          currentValue INTEGER NOT NULL,
          profitRate REAL NOT NULL,
          profitRateChange REAL NOT NULL,
          UNIQUE(asset_id, snapshot_date), -- 동일 종목의 같은 날짜 스냅샷 중복 방지
          FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
        )
      ''');
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
    return await db.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
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
