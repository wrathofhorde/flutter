import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static String? _dbName; // 데이터베이스 파일 이름
  static Database? _database; // SQLite 데이터베이스 인스턴스

  // 싱글톤 인스턴스 (한 번만 생성되도록)
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  // init 메소드 (데이터베이스 인스턴스를 얻기 위한 공개 API)
  Future<Database> init(String dbname) async {
    _dbName = dbname;
    return await database;
  }

  // 데이터베이스 초기화 및 인스턴스 반환
  Future<Database> get database async {
    // async 키워드 확인
    _database ??= await _initDb();
    return _database!;
  }

  // 데이터베이스를 초기화하는 실제 로직
  Future<Database> _initDb() async {
    String currentDirectoryPath = Directory.current.path;
    String path = join(currentDirectoryPath, _dbName);
    debugPrint('Database path: $path');

    return sqlite3.open(path);
  }

  // INSERT, UPDATE, DELETE와 같이 결과를 반환하지 않는 쿼리 실행
  // execute 메소드: 단일 쿼리 실행
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final db = await database;
    try {
      db.execute(sql, parameters);
      debugPrint('Executed: $sql with params: $parameters');
    } catch (e) {
      debugPrint('Error executing query: $sql, params: $parameters, error: $e');
      rethrow;
    }
  }

  // executeMany 메소드: 여러 개의 쿼리 실행
  Future<void> executeMany(String sql, List<List<Object?>> paramSets) async {
    final db = await database;
    try {
      final statement = db.prepare(sql);
      for (var params in paramSets) {
        statement.execute(params);
        debugPrint('Executed many: $sql with params: $params');
      }
      statement.dispose(); // statement 사용 후 반드시 해제
    } catch (e) {
      debugPrint('Error executing many query: $sql, error: $e');
      rethrow;
    }
  }

  // SELECT와 같이 결과를 반환하는 쿼리 실행 (모든 결과 가져오기)
  // fetchAll 메소드: 모든 결과 행 가져오기
  Future<List<Map<String, dynamic>>> fetchAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final db = await database;
    try {
      final ResultSet result = db.select(sql, parameters);
      final List<Map<String, dynamic>> rows = result
          .map((row) => row.cast<String, dynamic>())
          .toList();
      debugPrint('Fetched all: $rows for query: $sql with params: $parameters');
      return rows;
    } catch (e) {
      debugPrint('Error fetching all: $sql, params: $parameters, error: $e');
      rethrow;
    }
  }

  // SELECT와 같이 결과를 반환하는 쿼리 실행 (단일 결과 행 가져오기)
  // fetchOne 메소드: 첫 번째 결과 행만 가져오기
  Future<Map<String, dynamic>?> fetchOne(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final db = await database;
    try {
      final ResultSet result = db.select(sql, parameters);
      if (result.isNotEmpty) {
        final Map<String, dynamic> row = result.first.cast<String, dynamic>();
        debugPrint(
          'Fetched one: $row for query: $sql with params: $parameters',
        );
        return row;
      }
      debugPrint(
        'Fetched one: No result for query: $sql with params: $parameters',
      );
      return null;
    } catch (e) {
      debugPrint('Error fetching one: $sql, params: $parameters, error: $e');
      rethrow;
    }
  }

  // 데이터베이스 연결 닫기
  void close() {
    if (_database != null) {
      _database!.dispose();
      _database = null;
      debugPrint('Database closed.');
    }
  }
}
