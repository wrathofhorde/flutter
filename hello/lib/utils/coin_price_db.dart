import 'package:flutter/foundation.dart';
import 'package:hello/models/coin_data.dart';
import 'package:hello/utils/database_helper.dart';

class CoinPriceDb {
  final _columnId = "id";
  final _columnBtc = "btc";
  final _columnEth = "eth";
  final _columnXrp = "xrp";
  final _columnUsdt = "usdt";
  final _columnDate = "date";
  final String _tableName;
  final DatabaseHelper _dbHelper;

  // 생성자를 통해 DatabaseHelper 인스턴스를 주입
  CoinPriceDb(this._dbHelper, this._tableName);

  Future<void> createTableIfNotExists() async {
    debugPrint(_tableName);
    final sql =
        '''
          CREATE TABLE IF NOT EXISTS $_tableName (
            $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_columnDate TEXT UNIQUE,
            $_columnBtc INTEGER,
            $_columnEth INTEGER,
            $_columnXrp INTEGER,
            $_columnUsdt INTEGER
          );
        ''';
    debugPrint(sql);
    await _dbHelper.execute(sql);
  }

  Future<void> insertMajorCoinPrices({
    required String date,
    required int btc,
    required int eth,
    required int xrp,
    required double usdt,
  }) async {
    final sql =
        '''
          INSERT OR IGNORE INTO $_tableName 
          ($_columnDate, $_columnBtc, $_columnEth, $_columnXrp, $_columnUsdt) 
          VALUES (?, ?, ?, ?, ?);
        ''';
    debugPrint(sql);
    await _dbHelper.execute(sql, [date, btc, eth, xrp, usdt]);
  }

  Future<void> bulkInsertMajorCoinPrices({
    required List<List<dynamic>> params,
  }) async {
    final sql =
        '''
      INSERT OR IGNORE INTO $_tableName
      ($_columnDate, $_columnBtc, $_columnEth, $_columnXrp, $_columnUsdt)
      VALUES (?, ?, ?, ?, ?);
      ''';
    debugPrint(sql);
    await _dbHelper.executeMany(sql, params);
    // debugPrint('Repository: Bulk inserted ${params.length} coin data entries.');
  }

  Future<List<CoinData>> getAllCoinData() async {
    final sql =
        '''
          SELECT $_columnDate, $_columnBtc, $_columnEth, $_columnXrp, $_columnUsdt 
          FROM $_tableName 
          ORDER BY date DESC;
        ''';
    debugPrint(sql);
    final result = await _dbHelper.fetchAll(sql);
    final List<CoinData> coinDataList = result
        .map((map) => CoinData.fromMap(map))
        .toList();
    // debugPrint('Repository: Fetched all coin data: $coinDataList');
    return coinDataList;
  }

  Future<List<CoinData>> getCoinDataByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final sql =
        '''
          SELECT $_columnDate, $_columnBtc, $_columnEth, $_columnXrp, $_columnUsdt
          FROM $_tableName
          WHERE $_columnDate BETWEEN ? AND ? 
          ORDER BY $_columnDate ASC;
        ''';
    debugPrint(sql);
    final result = await _dbHelper.fetchAll(sql, [startDate, endDate]);
    final List<CoinData> coinDataList = result
        .map((map) => CoinData.fromMap(map))
        .toList();
    // debugPrint(
    //   'Repository: Fetched coin data from $startDate to $endDate: $coinDataList',
    // );
    return coinDataList;
  }

  Future<CoinData?> getCoinDataByDate(String date) async {
    final sql =
        '''
          SELECT $_columnDate, $_columnBtc, $_columnEth, $_columnXrp, $_columnUsdt
          FROM $_tableName
          WHERE $_columnDate = ?;
        ''';
    debugPrint(sql);
    final result = await _dbHelper.fetchOne(sql, [date]);
    if (result != null) {
      final CoinData coinData = CoinData.fromMap(result);
      // debugPrint('Repository: Fetched coin data for $date: $coinData');
      return coinData;
    }
    // debugPrint('Repository: No coin data found for $date');
    return null;
  }

  Future<String?> getLastUpdatedDate() async {
    final sql =
        '''
          SELECT MAX($_columnDate) AS last_date 
          FROM $_tableName;
        ''';
    debugPrint(sql);
    final result = await _dbHelper.fetchOne(sql);
    final String? lastDate = result?['last_date'] as String?;
    // debugPrint('Repository: Last updated date: $lastDate');
    return lastDate;
  }

  Future<Map<String, dynamic>> getAggregatedCoinPrices({
    required String startDate,
    required String endDate,
  }) async {
    final sql =
        '''
        SELECT
            AVG($_columnBtc) AS avg_btc, MAX($_columnBtc) AS max_btc, MIN($_columnBtc) AS min_btc,
            AVG($_columnEth) AS avg_eth, MAX($_columnEth) AS max_eth, MIN($_columnEth) AS min_eth,
            AVG($_columnXrp) AS avg_xrp, MAX($_columnXrp) AS max_xrp, MIN($_columnXrp) AS min_xrp,
            AVG($_columnUsdt) AS avg_usdt, MAX($_columnUsdt) AS max_usdt, MIN($_columnUsdt) AS min_usdt
        FROM $_tableName
        WHERE $_columnDate BETWEEN ? AND ?;
        '''; // ORDER BY는 단일 결과에는 필요 없음
    debugPrint(sql);
    final result = await _dbHelper.fetchOne(sql, [startDate, endDate]);
    if (result != null) {
      return {
        'btc': {
          'avg': (result['avg_btc'].round() as int?) ?? 0,
          'max': (result['max_btc'] as int?) ?? 0,
          'min': (result['min_btc'] as int?) ?? 0,
        },
        'eth': {
          'avg': (result['avg_eth'].round() as int?) ?? 0,
          'max': (result['max_eth'] as int?) ?? 0,
          'min': (result['min_eth'] as int?) ?? 0,
        },
        'xrp': {
          'avg': (result['avg_xrp'].round() as int?) ?? 0,
          'max': (result['max_xrp'] as int?) ?? 0,
          'min': (result['min_xrp'] as int?) ?? 0,
        },
        'usdt': {
          'avg': (result['avg_usdt'].round() as int?) ?? 0,
          'max': (result['max_usdt'] as int?) ?? 0,
          'min': (result['min_usdt'] as int?) ?? 0,
        },
      };
    }

    return {
      'btc': {'avg': 0, 'max': 0, 'min': 0},
      'eth': {'avg': 0, 'max': 0, 'min': 0},
      'xrp': {'avg': 0, 'max': 0, 'min': 0},
      'usdt': {'avg': 0, 'max': 0, 'min': 0},
    };
  }
}
