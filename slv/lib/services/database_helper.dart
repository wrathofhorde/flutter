// lib/services/database_helper.dart
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "slv_tracker.sq3");
    debugPrint(path);

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. USD/KRW 환율 테이블 (유지)
    await db.execute('''
      CREATE TABLE usd_krw_rates (
        date TEXT PRIMARY KEY,
        open REAL,
        high REAL,
        low REAL,
        close REAL
      )
    ''');

    // **2. 달러 인덱스 (DXY) 테이블 추가**
    await db.execute('''
      CREATE TABLE dxy_index (
        date TEXT PRIMARY KEY,
        value REAL
      )
    ''');

    // 기존의 xau_prices, xag_prices, eur_usd_rates 등은 삭제됩니다.
  }

  // 모든 테이블 삭제 (개발 시 유용, 실제 앱에서는 주의)
  Future<void> deleteAllTables() async {
    final db = await database;
    await db.delete('usd_krw_rates');
    await db.delete('dxy_index'); // 추가
    // 기존의 xau_prices, xag_prices, eur_usd_rates 등 삭제
    debugPrint('All tables cleared!');
  }

  // 특정 테이블의 모든 데이터 가져오기 (예시)
  Future<List<Map<String, dynamic>>> getPrices(String tableName) async {
    final db = await database;
    return await db.query(tableName, orderBy: 'date ASC');
  }

  // 데이터 삽입 또는 업데이트
  Future<void> insertOrUpdateData(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace, // 충돌 시 대체
    );
  }

  // 특정 테이블의 가장 최근 날짜 가져오기
  Future<String?> getLastDate(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'date DESC',
      limit: 1,
      columns: ['date'],
    );
    if (maps.isNotEmpty) {
      return maps.first['date'] as String;
    }
    return null;
  }
}
