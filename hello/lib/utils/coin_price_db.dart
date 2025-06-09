import 'package:flutter/foundation.dart';
import 'package:hello/model/coin_data.dart';
import 'package:hello/utils/database_helper.dart';

class CoinPriceDb {
  final DatabaseHelper _dbHelper;
  // 생성자를 통해 DatabaseHelper 인스턴스를 주입
  CoinPriceDb(this._dbHelper);

  Future<void> insertMajorCoinPrices({
    required String date,
    required int btc,
    required int eth,
    required int xrp,
  }) async {
    final sql =
        '''
          INSERT OR IGNORE INTO ${_dbHelper.dbname} 
          (date, btc, eth, xrp) 
          VALUES (?, ?, ?, ?);
        ''';
    await _dbHelper.execute(sql, [date, btc, eth, xrp]);
    debugPrint('Repository: Inserted coin data for $date');
  }

  Future<List<CoinData>> getAllCoinData() async {
    final sql =
        '''
          SELECT date, btc, eth, xrp 
          FROM ${_dbHelper.dbname} 
          ORDER BY date DESC;
        ''';
    final result = await _dbHelper.fetchAll(sql);
    final List<CoinData> coinDataList = result
        .map((map) => CoinData.fromMap(map))
        .toList();
    debugPrint('Repository: Fetched all coin data: $coinDataList');
    return coinDataList;
  }

  Future<List<CoinData>> getCoinDataByDateRange(
    String startDate,
    String endDate,
  ) async {
    final sql =
        '''
          SELECT date, btc, eth, xrp 
          FROM ${_dbHelper.dbname} 
          WHERE date BETWEEN ? AND ? 
          ORDER BY date DESC;
        ''';
    final result = await _dbHelper.fetchAll(sql, [startDate, endDate]);
    final List<CoinData> coinDataList = result
        .map((map) => CoinData.fromMap(map))
        .toList();
    debugPrint(
      'Repository: Fetched coin data from $startDate to $endDate: $coinDataList',
    );
    return coinDataList;
  }

  Future<CoinData?> getCoinDataByDate(String date) async {
    final sql =
        '''
          SELECT date, btc, eth, xrp 
          FROM ${_dbHelper.dbname} 
          WHERE date = ?;
        ''';
    final result = await _dbHelper.fetchOne(sql, [date]);
    if (result != null) {
      final CoinData coinData = CoinData.fromMap(result);
      debugPrint('Repository: Fetched coin data for $date: $coinData');
      return coinData;
    }
    debugPrint('Repository: No coin data found for $date');
    return null;
  }

  Future<String?> getLastUpdatedDate() async {
    final sql = '''
        SELECT MAX(date) AS last_date 
        FROM major_coins;
      ''';
    final result = await _dbHelper.fetchOne(sql);
    final String? lastDate = result?['last_date'] as String?;
    debugPrint('Repository: Last updated date: $lastDate');
    return lastDate;
  }
}
