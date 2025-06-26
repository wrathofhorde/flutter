// lib/data/database_helper.dart
import 'dart:io' show Platform, Directory;
import 'dart:developer' as developer; // logging 대신 사용
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 사용
import 'package:market_index/models/data_models.dart';
import 'package:path_provider/path_provider.dart'; // 앱 데이터 경로
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // SQLite FFI
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 사용 (getLatestDate에서 사용)

class DatabaseHelper {
  static Database? _database; // 싱글톤 인스턴스를 위한 private 변수
  static String? _dbPath; // 데이터베이스 경로를 캐싱하기 위한 변수

  // 데이터베이스 싱글톤 인스턴스를 얻는 메서드
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // 데이터베이스 경로를 얻는 메서드
  static Future<String> getDatabasePath() async {
    if (_dbPath == null) {
      final dbFileName = dotenv.env['DB_NAME'] ?? 'data.db';

      if (Platform.isWindows) {
        _dbPath = '${Directory.current.path}/$dbFileName';
        developer.log('Windows 데이터베이스 경로: $_dbPath', name: 'DatabaseHelper');
      } else if (Platform.isMacOS) {
        final directory = await getApplicationSupportDirectory();
        _dbPath = '${directory.path}/$dbFileName';
        developer.log('macOS 데이터베이스 경로: $_dbPath', name: 'DatabaseHelper');
      } else {
        // Fallback for other platforms (e.g., Linux)
        final directory = await getApplicationSupportDirectory();
        _dbPath = '${directory.path}/$dbFileName';
        developer.log('기타 OS 데이터베이스 경로: $_dbPath', name: 'DatabaseHelper');
      }
    }
    return _dbPath!;
  }

  // 데이터베이스 초기화 및 테이블 생성
  static Future<Database> _initDb() async {
    sqfliteFfiInit(); // FFI 초기화
    final databaseFactory = databaseFactoryFfi;
    final path = await getDatabasePath();

    final database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS usd_krw (
                date TEXT PRIMARY KEY,
                rate REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS gold (
                date TEXT PRIMARY KEY,
                price REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS silver (
                date TEXT PRIMARY KEY,
                price REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS dollar_index (
                date TEXT PRIMARY KEY,
                price REAL NOT NULL
            )
          ''');
          developer.log(
            "usd_krw, gold, silver, dollar_index 테이블이 초기화되었습니다.",
            name: 'DatabaseHelper',
          );
        },
      ),
    );
    return database;
  }

  // 지정된 테이블의 가장 최근 날짜 가져오기
  static Future<DateTime?> getLatestDate(String tableName) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        columns: ['MAX(date) as max_date'],
      );
      final String? result = maps.first['max_date'];
      if (result != null) {
        final latestDate = DateTime.parse(result);
        developer.log(
          '$tableName 테이블의 최근 업데이트 날짜: $latestDate',
          name: 'DatabaseHelper',
        );
        return latestDate;
      }
      developer.log('$tableName 테이블에 데이터가 없습니다.', name: 'DatabaseHelper');
      return null;
    } catch (e) {
      developer.log(
        '$tableName 최근 날짜 조회 오류: $e',
        error: e,
        name: 'DatabaseHelper',
      );
      rethrow;
    }
  }

  // 데이터 저장 (일반화된 save_data)
  static Future<void> saveData(
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (var item in data) {
      final date = item['date'];
      final valueKey = tableName == 'usd_krw'
          ? 'rate'
          : 'price'; // 테이블 이름에 따라 저장할 컬럼 이름 결정

      batch.insert(
        tableName,
        {'date': date, valueKey: item.values.last}, // date를 제외한 나머지 값을 저장
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    try {
      await batch.commit(noResult: true);
      developer.log(
        '$tableName 테이블에 ${data.length}개의 데이터가 저장되었습니다.',
        name: 'DatabaseHelper',
      );
    } catch (e) {
      developer.log(
        '$tableName 데이터 저장 오류: $e',
        error: e,
        name: 'DatabaseHelper',
      );
      rethrow;
    }
  }

  // 특정 기간의 모든 데이터 로드 (visualize.py의 load_data와 유사)
  static Future<List<Map<String, dynamic>>> loadData(int months) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(
      Duration(days: months * 30),
    ); // 대략적인 개월 수

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final cutoffDateStr = formatter.format(cutoffDate);

    List<Map<String, dynamic>> allData = [];

    try {
      // usd_krw 데이터 로드
      final usdKrwMaps = await db.query(
        'usd_krw',
        where: 'date >= ?',
        whereArgs: [cutoffDateStr],
        orderBy: 'date ASC',
      );
      List<UsdKrwData> usdKrwList = usdKrwMaps
          .map((map) => UsdKrwData.fromMap(map))
          .toList();

      // gold 데이터 로드
      final goldMaps = await db.query(
        'gold',
        where: 'date >= ?',
        whereArgs: [cutoffDateStr],
        orderBy: 'date ASC',
      );
      List<GoldData> goldList = goldMaps
          .map((map) => GoldData.fromMap(map))
          .toList();

      // silver 데이터 로드
      final silverMaps = await db.query(
        'silver',
        where: 'date >= ?',
        whereArgs: [cutoffDateStr],
        orderBy: 'date ASC',
      );
      List<SilverData> silverList = silverMaps
          .map((map) => SilverData.fromMap(map))
          .toList();

      // dollar_index 데이터 로드
      final dollarIndexMaps = await db.query(
        'dollar_index',
        where: 'date >= ?',
        whereArgs: [cutoffDateStr],
        orderBy: 'date ASC',
      );
      List<DollarIndexData> dollarIndexList = dollarIndexMaps
          .map((map) => DollarIndexData.fromMap(map))
          .toList();

      // Pandas DataFrame처럼 단일 리스트로 병합 (날짜를 기준으로)
      Map<DateTime, Map<String, dynamic>> mergedData = {};

      for (var item in usdKrwList) {
        mergedData.putIfAbsent(item.date, () => {'date': item.date});
        mergedData[item.date]!['usd_krw'] = item.rate;
      }
      for (var item in goldList) {
        mergedData.putIfAbsent(item.date, () => {'date': item.date});
        mergedData[item.date]!['gold_price'] = item.price;
      }
      for (var item in silverList) {
        mergedData.putIfAbsent(item.date, () => {'date': item.date});
        mergedData[item.date]!['silver_price'] = item.price;
      }
      for (var item in dollarIndexList) {
        mergedData.putIfAbsent(item.date, () => {'date': item.date});
        mergedData[item.date]!['dollar_index_price'] = item.price;
      }

      // 날짜 기준으로 정렬
      allData = mergedData.values.toList()
        ..sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
        );
      developer.log(
        '데이터베이스에서 ${allData.length}개 데이터 로드 완료 (지난 $months개월).',
        name: 'DatabaseHelper',
      );
    } catch (e) {
      developer.log('데이터 로드 오류: $e', error: e, name: 'DatabaseHelper');
      rethrow;
    }
    return allData;
  }
}
