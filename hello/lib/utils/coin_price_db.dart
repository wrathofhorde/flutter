import 'package:flutter/foundation.dart';
import 'package:hello/model/coin_data.dart';
import 'package:hello/utils/database_helper.dart';

class CoinPriceDb {
  final _columnId = "id";
  final _columnBtc = "btc";
  final _columnEth = "eth";
  final _columnXrp = "xrp";
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
            $_columnXrp INTEGER
          );
        ''';

    await _dbHelper.execute(sql);
    debugPrint('Repository: Create table');
  }

  Future<void> insertMajorCoinPrices({
    required String date,
    required int btc,
    required int eth,
    required int xrp,
  }) async {
    final sql =
        '''
          INSERT OR IGNORE INTO $_tableName 
          ($_columnDate, $_columnBtc, $_columnEth, $_columnXrp) 
          VALUES (?, ?, ?, ?);
        ''';
    await _dbHelper.execute(sql, [date, btc, eth, xrp]);
    debugPrint('Repository: Inserted coin data for $date');
  }

  Future<List<CoinData>> getAllCoinData() async {
    final sql =
        '''
          SELECT $_columnDate, $_columnBtc, $_columnEth, $_columnXrp 
          FROM $_tableName 
          ORDER BY date DESC;
        ''';
    final result = await _dbHelper.fetchAll(sql);
    final List<CoinData> coinDataList = result
        .map((map) => CoinData.fromMap(map))
        .toList();
    debugPrint('Repository: Fetched all coin data: $coinDataList');
    return coinDataList;
  }

  Future<List<CoinData>> getCoinDataByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final sql =
        '''
          SELECT $_columnDate, $_columnBtc, $_columnEth, $_columnXrp 
          FROM $_tableName
          WHERE $_columnDate BETWEEN ? AND ? 
          ORDER BY $_columnDate DESC;
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
          SELECT $_columnDate, $_columnBtc, $_columnEth, $_columnXrp 
          FROM $_tableName
          WHERE $_columnDate = ?;
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
    final sql =
        '''
          SELECT MAX($_columnDate) AS last_date 
          FROM $_tableName;
        ''';
    final result = await _dbHelper.fetchOne(sql);
    final String? lastDate = result?['last_date'] as String?;
    debugPrint('Repository: Last updated date: $lastDate');
    return lastDate;
  }
}
