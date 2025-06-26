// lib/data_crawler.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 사용
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // SQLite FFI
import 'package:path_provider/path_provider.dart'; // 앱 데이터 경로
import 'dart:io' show Platform, Directory;
import 'dart:developer' as developer; // logging 대신 사용
import '../data/database_helper.dart';

final String fredApiKey = dotenv.env['FRED_API_KEY']!;

// 데이터베이스 관련 함수는 별도의 파일로 분리할 예정이지만,
// 여기서는 데이터 저장 로직만 간단히 구현합니다.
// 먼저 data_manager.dart 파일로 데이터베이스 관련 로직을 옮겨둘게요.
// 임시로 DB 경로를 정의합니다.
String? _dbPath;

Future<String> getDatabasePath() async {
  if (_dbPath == null) {
    // .env 파일에서 DB_NAME을 가져오고, 없으면 기본값 'data.db' 사용
    final dbFileName = dotenv.env['DB_NAME'] ?? 'data.db';

    if (Platform.isWindows) {
      // Windows의 경우, 앱 실행 파일이 있는 디렉토리에 저장
      _dbPath = '${Directory.current.path}/$dbFileName';
      developer.log('Windows 데이터베이스 경로: $_dbPath', name: 'DataCrawler');
    } else if (Platform.isMacOS) {
      // macOS의 경우, getApplicationSupportDirectory 사용
      final directory = await getApplicationSupportDirectory();
      _dbPath = '${directory.path}/$dbFileName';
      developer.log('macOS 데이터베이스 경로: $_dbPath', name: 'DataCrawler');
    } else {
      // 다른 OS (Linux 등) 또는 모바일 (계획 없다고 하셨지만, 안전을 위해 기본값 설정)
      final directory = await getApplicationSupportDirectory();
      _dbPath = '${directory.path}/$dbFileName';
      developer.log('기타 OS 데이터베이스 경로: $_dbPath', name: 'DataCrawler');
    }
  }
  return _dbPath!;
}

// 기존 database.py의 init_db 함수를 Dart로 포팅
Future<Database> initDb() async {
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
          name: 'DataCrawler',
        );
      },
    ),
  );
  return database;
}

// 기존 database.py의 get_latest_date 함수를 Dart로 포팅
Future<DateTime?> getLatestDate(Database db, String tableName) async {
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
        name: 'DataCrawler',
      );
      return latestDate;
    }
    developer.log('$tableName 테이블에 데이터가 없습니다.', name: 'DataCrawler');
    return null;
  } catch (e) {
    developer.log('$tableName 최근 날짜 조회 오류: $e', error: e, name: 'DataCrawler');
    rethrow;
  }
}

// 기존 database.py의 save_data 함수를 Dart로 포팅
Future<void> saveData(
  Database db,
  String tableName,
  List<Map<String, dynamic>> data,
) async {
  final batch = db.batch();
  for (var item in data) {
    final date = item['date'];
    final valueKey = tableName == 'usd_krw'
        ? 'usd_krw'
        : tableName == 'silver'
        ? 'silver_price'
        : tableName == 'gold'
        ? 'gold_price'
        : 'dollar_index_price';
    final value = item[valueKey];

    batch.insert(tableName, {
      'date': date,
      tableName == 'usd_krw' ? 'rate' : 'price': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  try {
    await batch.commit(noResult: true);
    developer.log(
      '$tableName 테이블에 ${data.length}개의 데이터가 저장되었습니다.',
      name: 'DataCrawler',
    );
  } catch (e) {
    developer.log('$tableName 데이터 저장 오류: $e', error: e, name: 'DataCrawler');
    rethrow;
  }
}

// --- 크롤링/API 호출 함수 ---

// 네이버 금융 크롤링 공통 함수 (USD/KRW, Gold, Silver 공통)
Future<List<Map<String, dynamic>>> _fetchNaverFinanceData({
  required String marketIndexCode,
  required String dataKey,
  required String logName,
  required DateTime? latestDate,
}) async {
  String baseUrl =
      "https://finance.naver.com/marketindex/exchangeDailyQuote.naver";
  if (logName == "Gold" || logName == "Silver") {
    // Gold/Silver는 worldDailyQuote 사용
    baseUrl = "https://finance.naver.com/marketindex/worldDailyQuote.naver";
  }

  final Map<String, String> headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
  };

  final today = DateTime.now();
  final cutoffDate = DateTime.parse("2021-01-01");

  List<Map<String, dynamic>> data = [];
  int page = 1;

  while (true) {
    try {
      String url;
      if (logName == "Gold" || logName == "Silver") {
        url = "$baseUrl?marketindexCd=$marketIndexCode&fdtc=2&page=$page";
      } else {
        url = "$baseUrl?marketindexCd=$marketIndexCode&page=$page";
      }

      developer.log('$logName 크롤링 요청: $url (페이지 $page)', name: 'DataCrawler');
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        developer.log(
          '$logName 페이지 $page 요청 실패: ${response.statusCode}',
          name: 'DataCrawler',
          error: response.body,
        );
        break;
      }

      final document = parse(response.body);
      final table = document.querySelector('table.tbl_exchange');
      if (table == null) {
        developer.log(
          '페이지 $page: $logName 테이블을 찾을 수 없습니다. 크롤링 종료.',
          name: 'DataCrawler',
        );
        break;
      }

      final rows = table.querySelectorAll('tr').skip(1).toList(); // 헤더 제외
      if (rows.isEmpty) {
        developer.log(
          '페이지 $page: $logName 데이터가 없습니다. 크롤링 종료.',
          name: 'DataCrawler',
        );
        break;
      }

      List<Map<String, dynamic>> pageData = [];
      bool shouldStop = false;

      for (var row in rows) {
        final cols = row.querySelectorAll('td');
        if (cols.length < 2) {
          continue;
        }

        final dateStr = cols[0].text.trim().replaceAll('.', '-');
        try {
          final date = DateTime.parse(dateStr);

          // 시간 정보를 제거하여 날짜만 비교 (Python의 .date()와 유사)
          final DateFormat formatter = DateFormat('yyyy-MM-dd');
          final compareDate = DateTime.parse(formatter.format(date));
          final compareToday = DateTime.parse(formatter.format(today));

          if (compareDate.isAfter(compareToday) ||
              compareDate.isAtSameMomentAs(compareToday)) {
            developer.log(
              '날짜 ${formatter.format(date)}가 오늘(${formatter.format(today)})이므로 제외.',
              name: 'DataCrawler',
            );
            continue;
          }
          if (latestDate != null) {
            final compareLatestDate = DateTime.parse(
              formatter.format(latestDate),
            );
            if (compareDate.isBefore(compareLatestDate) ||
                compareDate.isAtSameMomentAs(compareLatestDate)) {
              developer.log(
                '날짜 ${formatter.format(date)}가 최종 업데이트(${formatter.format(latestDate)}) 이하이므로 $logName 크롤링 종료.',
                name: 'DataCrawler',
              );
              shouldStop = true;
              break; // 이 페이지의 나머지 데이터도 수집할 필요 없음
            }
          }
          if (compareDate.isBefore(cutoffDate)) {
            developer.log(
              '날짜 ${formatter.format(date)}가 2021-01-01 이전이므로 $logName 크롤링 종료.',
              name: 'DataCrawler',
            );
            shouldStop = true;
            break; // 이 페이지의 나머지 데이터도 수집할 필요 없음
          }

          final value = double.parse(cols[1].text.trim().replaceAll(',', ''));
          pageData.add({'date': formatter.format(date), dataKey: value});
          developer.log(
            '${formatter.format(date)}, $logName: $value',
            name: 'DataCrawler',
          );
        } catch (e) {
          developer.log(
            '$logName 날짜 파싱 오류: $dateStr, 에러: $e',
            error: e,
            name: 'DataCrawler',
          );
          continue;
        }
      }

      if (shouldStop) {
        data.addAll(pageData); // 현재 페이지까지의 유효한 데이터는 추가
        break;
      }

      if (pageData.isEmpty) {
        developer.log(
          '페이지 $page: $logName 유효한 데이터가 없습니다.',
          name: 'DataCrawler',
        );
        break;
      }

      data.addAll(pageData);
      developer.log(
        '페이지 $page: ${pageData.length}개 $logName 데이터 수집.',
        name: 'DataCrawler',
      );
      page++;
      developer.log('$logName 다음 페이지로 이동: $page', name: 'DataCrawler');
      await Future.delayed(const Duration(seconds: 1)); // 딜레이
    } catch (e) {
      developer.log(
        '$logName 페이지 $page 요청 오류: $e',
        error: e,
        name: 'DataCrawler',
      );
      break;
    }
  }
  return data;
}

// USD/KRW 환율 데이터 수집
Future<List<Map<String, dynamic>>> fetchUsdKrwExchangeRate(
  DateTime? latestDate,
) {
  return _fetchNaverFinanceData(
    marketIndexCode: 'FX_USDKRW',
    dataKey: 'usd_krw',
    logName: 'USD/KRW',
    latestDate: latestDate,
  );
}

// Gold 종가 데이터 수집
Future<List<Map<String, dynamic>>> fetchGoldPrice(DateTime? latestDate) {
  return _fetchNaverFinanceData(
    marketIndexCode: 'CMDT_GC',
    dataKey: 'gold_price',
    logName: 'Gold',
    latestDate: latestDate,
  );
}

// Silver 종가 데이터 수집
Future<List<Map<String, dynamic>>> fetchSilverPrice(DateTime? latestDate) {
  return _fetchNaverFinanceData(
    marketIndexCode: 'CMDT_SI',
    dataKey: 'silver_price',
    logName: 'Silver',
    latestDate: latestDate,
  );
}

// FRED API에서 달러 인덱스 데이터 수집
Future<List<Map<String, dynamic>>> fetchDollarIndex(
  DateTime? latestDate,
) async {
  final String baseUrl = "https://api.stlouisfed.org/fred/series/observations";
  final Map<String, String> headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
  };

  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  final cutoffDate = DateTime.parse("2021-01-01");
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  final Map<String, String> params = {
    "series_id": "DTWEXAFEGS",
    "api_key": fredApiKey,
    "file_type": "json",
    "observation_start": formatter.format(cutoffDate),
    "observation_end": formatter.format(yesterday),
    "frequency": "d",
  };

  List<Map<String, dynamic>> data = [];
  try {
    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    developer.log('Dollar Index API 요청: $uri', name: 'DataCrawler');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      developer.log(
        'Dollar Index API 요청 실패: ${response.statusCode}',
        name: 'DataCrawler',
        error: response.body,
      );
      return data;
    }

    final jsonResponse = json.decode(response.body);

    if (jsonResponse is! Map || !jsonResponse.containsKey('observations')) {
      developer.log(
        "FRED API 응답에 'observations' 키가 없습니다.",
        name: 'DataCrawler',
        error: jsonResponse,
      );
      return data;
    }

    for (var obs in jsonResponse['observations']) {
      final dateStr = obs["date"];
      try {
        final date = DateTime.parse(dateStr);
        final compareDate = DateTime.parse(formatter.format(date));
        final compareToday = DateTime.parse(formatter.format(today));

        if (compareDate.isAfter(compareToday) ||
            compareDate.isAtSameMomentAs(compareToday)) {
          developer.log(
            '날짜 ${formatter.format(date)}가 오늘(${formatter.format(today)})이므로 제외.',
            name: 'DataCrawler',
          );
          continue;
        }

        if (latestDate != null) {
          final compareLatestDate = DateTime.parse(
            formatter.format(latestDate),
          );
          if (compareDate.isBefore(compareLatestDate) ||
              compareDate.isAtSameMomentAs(compareLatestDate)) {
            // developer.log('날짜 ${formatter.format(date)}가 최종 업데이트(${formatter.format(latestDate)}) 이하이므로 Dollar Index 크롤링 스킵.', name: 'DataCrawler');
            continue; // 이미 저장된 데이터는 스킵
          }
        }

        if (compareDate.isBefore(cutoffDate)) {
          developer.log(
            '날짜 ${formatter.format(date)}가 2021-01-01 이전이므로 Dollar Index 크롤링 스킵.',
            name: 'DataCrawler',
          );
          continue;
        }

        final value = obs["value"];
        if (value == ".") {
          developer.log(
            '${formatter.format(date)}의 Dollar Index 값이 유효하지 않음 (\'.\').',
            name: 'DataCrawler',
          );
          continue;
        }

        final price = double.parse(value);
        data.add({'date': formatter.format(date), 'dollar_index_price': price});
        developer.log(
          '${formatter.format(date)}, Dollar Index: $price',
          name: 'DataCrawler',
        );
      } catch (e) {
        developer.log(
          'Dollar Index 데이터 파싱 오류: $dateStr, 에러: $e',
          error: e,
          name: 'DataCrawler',
        );
        continue;
      }
    }
    developer.log('Dollar Index: ${data.length}개 데이터 수집.', name: 'DataCrawler');
  } catch (e) {
    developer.log('Dollar Index API 요청 오류: $e', error: e, name: 'DataCrawler');
  }
  return data;
}

Future<void> runDataCollectionAndSave() async {
  developer.log("데이터 수집 및 저장 프로세스 시작", name: 'DataCrawler');
  try {
    // DatabaseHelper.database를 통해 데이터베이스 인스턴스 얻기 (자동 초기화 및 열기)
    // final db = await DatabaseHelper.database; // 여기서는 직접 db 객체를 사용할 필요 없음

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // USD/KRW 크롤링 및 저장
    DateTime? latestUsdKrwDate = await DatabaseHelper.getLatestDate(
      'usd_krw',
    ); // DatabaseHelper 사용
    if (latestUsdKrwDate == null || latestUsdKrwDate.isBefore(yesterday)) {
      developer.log(
        "USD/KRW 데이터 업데이트 필요. 최신 날짜: $latestUsdKrwDate",
        name: 'DataCrawler',
      );
      final usdKrwData = await fetchUsdKrwExchangeRate(latestUsdKrwDate);
      if (usdKrwData.isNotEmpty) {
        await DatabaseHelper.saveData(
          'usd_krw',
          usdKrwData,
        ); // DatabaseHelper 사용
      } else {
        developer.log("USD/KRW 수집된 데이터가 없습니다.", name: 'DataCrawler');
      }
    } else {
      developer.log(
        "USD/KRW 데이터가 ${DateFormat('yyyy-MM-dd').format(latestUsdKrwDate)}까지 업데이트되어 있으므로 크롤링을 스킵합니다.",
        name: 'DataCrawler',
      );
    }

    // Gold 크롤링 및 저장
    DateTime? latestGoldDate = await DatabaseHelper.getLatestDate(
      'gold',
    ); // DatabaseHelper 사용
    if (latestGoldDate == null || latestGoldDate.isBefore(yesterday)) {
      developer.log(
        "Gold 데이터 업데이트 필요. 최신 날짜: $latestGoldDate",
        name: 'DataCrawler',
      );
      final goldData = await fetchGoldPrice(latestGoldDate);
      if (goldData.isNotEmpty) {
        await DatabaseHelper.saveData('gold', goldData); // DatabaseHelper 사용
      } else {
        developer.log("Gold 수집된 데이터가 없습니다.", name: 'DataCrawler');
      }
    } else {
      developer.log(
        "Gold 데이터가 ${DateFormat('yyyy-MM-dd').format(latestGoldDate)}까지 업데이트되어 있으므로 크롤링을 스킵합니다.",
        name: 'DataCrawler',
      );
    }

    // Silver 크롤링 및 저장
    DateTime? latestSilverDate = await DatabaseHelper.getLatestDate(
      'silver',
    ); // DatabaseHelper 사용
    if (latestSilverDate == null || latestSilverDate.isBefore(yesterday)) {
      developer.log(
        "Silver 데이터 업데이트 필요. 최신 날짜: $latestSilverDate",
        name: 'DataCrawler',
      );
      final silverData = await fetchSilverPrice(latestSilverDate);
      if (silverData.isNotEmpty) {
        await DatabaseHelper.saveData(
          'silver',
          silverData,
        ); // DatabaseHelper 사용
      } else {
        developer.log("Silver 수집된 데이터가 없습니다.", name: 'DataCrawler');
      }
    } else {
      developer.log(
        "Silver 데이터가 ${DateFormat('yyyy-MM-dd').format(latestSilverDate)}까지 업데이트되어 있으므로 크롤링을 스킵합니다.",
        name: 'DataCrawler',
      );
    }

    // 테이블 전환 시 1초 딜레이 추가
    await Future.delayed(Duration(seconds: 1));

    // Dollar Index 크롤링 및 저장
    DateTime? latestDollarIndexDate = await DatabaseHelper.getLatestDate(
      'dollar_index',
    ); // DatabaseHelper 사용
    if (latestDollarIndexDate == null ||
        latestDollarIndexDate.isBefore(yesterday)) {
      developer.log(
        "Dollar Index 데이터 업데이트 필요. 최신 날짜: $latestDollarIndexDate",
        name: 'DataCrawler',
      );
      final dollarIndexData = await fetchDollarIndex(latestDollarIndexDate);
      if (dollarIndexData.isNotEmpty) {
        await DatabaseHelper.saveData(
          'dollar_index',
          dollarIndexData,
        ); // DatabaseHelper 사용
      } else {
        developer.log("Dollar Index 수집된 데이터가 없습니다.", name: 'DataCrawler');
      }
    } else {
      developer.log(
        "Dollar Index 데이터가 ${DateFormat('yyyy-MM-dd').format(latestDollarIndexDate)}까지 업데이트되어 있으므로 크롤링을 스킵합니다.",
        name: 'DataCrawler',
      );
    }
    developer.log("데이터 수집 및 저장 프로세스 완료", name: 'DataCrawler');
  } catch (e) {
    developer.log("데이터 수집 및 저장 중 오류 발생: $e", error: e, name: 'DataCrawler');
    rethrow;
  } finally {
    // 데이터베이스 연결은 DatabaseHelper 내에서 관리되므로 여기서 명시적으로 닫을 필요 없음
    // 다만, 앱 종료 시점에는 닫아주는 로직이 필요할 수 있습니다 (추후 논의)
  }
}
