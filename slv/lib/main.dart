// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:slv/services/alpha_vantage_service.dart';
import 'package:slv/services/database_helper.dart';
import 'package:slv/services/fred_service.dart';
import 'package:slv/utils/date_utils.dart' as date_utils;
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper().database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLV Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AlphaVantageService _alphaVantageService = AlphaVantageService();
  final FredService _fredService = FredService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, Map<String, dynamic>> _allData = {};
  bool _isLoading = true;
  String _error = '';

  final String _effectiveStartDate =
      '2021-01-01'; // 실제 데이터 저장 시작 날짜 (API 요청 기준이 아님)

  @override
  void initState() {
    super.initState();
    _fetchAndStoreData();
  }

  Future<void> _fetchAndStoreData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      // 1. USD/KRW 데이터 처리 (Alpha Vantage)
      // Alpha Vantage는 특정 날짜 이후 데이터만 가져오는 파라미터가 없으므로,
      // 항상 full 데이터를 가져와서 DB의 마지막 날짜보다 최신인 데이터만 저장합니다.
      String? lastUsdKrwDateInDb = await _databaseHelper.getLastDate(
        'usd_krw_rates',
      );
      debugPrint('DB의 USD/KRW 최종 날짜: $lastUsdKrwDateInDb');

      debugPrint('Alpha Vantage에서 USD/KRW 전체 데이터를 가져옵니다...');
      Map<String, Map<String, dynamic>> usdKrwDataFromApi =
          await _alphaVantageService.fetchOnlyUsdKrwData();
      await _saveUsdKrwDataToDatabase(
        usdKrwDataFromApi,
        lastUsdKrwDateInDb ?? _effectiveStartDate,
      );

      // 2. 달러 인덱스 (DXY) 데이터 처리 (FRED)
      // FRED는 observation_start 파라미터를 지원하므로, 필요한 데이터만 요청합니다.
      String? lastDxyDateInDb = await _databaseHelper.getLastDate('dxy_index');
      debugPrint('DB의 DXY 최종 날짜: $lastDxyDateInDb');

      String fredFetchStartDate;
      if (lastDxyDateInDb != null) {
        // DB 마지막 날짜 다음 날부터 가져오기
        DateTime nextDay = date_utils.DateUtils.parseDate(
          lastDxyDateInDb,
        ).add(const Duration(days: 1));
        fredFetchStartDate = date_utils.DateUtils.formatDate(nextDay);
        debugPrint('FRED API $fredFetchStartDate부터 DXY 데이터 요청');
      } else {
        // DB에 데이터가 없으면 처음부터 가져오기
        fredFetchStartDate = _effectiveStartDate;
        debugPrint(
          'DB에 DXY 데이터가 없습니다. FRED API에서 $_effectiveStartDate부터 가져옵니다...',
        );
      }

      Map<String, dynamic> dxyDataFromApi = await _fredService.fetchDollarIndex(
        'DTWEXBGS',
        fredFetchStartDate,
      );
      // FRED에서 가져온 데이터를 DB에 저장 (시작 날짜는 API 요청 날짜와 일치)
      await _saveDxyDataToDatabase(dxyDataFromApi, fredFetchStartDate);

      // 최종적으로 DB에서 데이터를 로드하여 앱 상태를 업데이트합니다.
      _allData = await _loadDataFromDatabase();

      setState(() {
        _isLoading = false;
        debugPrint('데이터 로딩 및 저장/업데이트 완료!');
        debugPrint(
          'DB USD/KRW entries: ${_allData['USD_KRW_DB']?.length ?? 0}',
        );
        debugPrint('DB DXY entries: ${_allData['DXY_DB']?.length ?? 0}');
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오거나 저장하는 데 실패했습니다: $e';
        _isLoading = false;
      });
      debugPrint('Error in _fetchAndStoreData: $e');
    }
  }

  // Alpha Vantage (USD/KRW) 데이터 저장 로직
  // fromDate는 DB의 마지막 날짜이거나 _effectiveStartDate입니다.
  // 이 날짜 이후의 데이터만 저장합니다.
  Future<void> _saveUsdKrwDataToDatabase(
    Map<String, Map<String, dynamic>> fetchedData,
    String fromDate,
  ) async {
    final DateTime filterStartDate = date_utils.DateUtils.parseDate(fromDate);

    if (fetchedData.containsKey('USD_KRW') &&
        fetchedData['USD_KRW']!['Time Series FX (Daily)'] != null) {
      final timeSeries =
          fetchedData['USD_KRW']!['Time Series FX (Daily)']
              as Map<String, dynamic>;
      // 날짜를 기준으로 정렬하여 처리하는 것이 좋지만, 여기서는 이미 최신 데이터가 먼저 오는 것으로 가정합니다.
      final sortedDates = timeSeries.keys.toList()..sort(); // 날짜 순으로 정렬

      for (var dateString in sortedDates) {
        final dataDate = date_utils.DateUtils.parseDate(dateString);
        // filterStartDate와 같거나 이후인 데이터만 저장
        // 이는 DB에 이미 있는 데이터는 replace되고, 새로운 데이터만 추가될 것입니다.
        if (dataDate.isAtSameMomentAs(filterStartDate) ||
            dataDate.isAfter(filterStartDate)) {
          final data = timeSeries[dateString];
          await _databaseHelper.insertOrUpdateData('usd_krw_rates', {
            'date': dateString,
            'open': double.parse(data['1. open']),
            'high': double.parse(data['2. high']),
            'low': double.parse(data['3. low']),
            'close': double.parse(data['4. close']),
          });
        }
      }
      debugPrint('USD_KRW 데이터 저장 또는 업데이트 완료.');
    } else {
      debugPrint('USD_KRW 데이터가 API 응답에 없거나 형식이 올바르지 않습니다.');
    }
  }

  // FRED (DXY) 데이터 저장 로직
  // fromDate는 API 요청 시 사용된 시작 날짜입니다.
  // FRED는 해당 날짜부터의 데이터를 정확히 주므로 추가 필터링은 필요 없습니다.
  Future<void> _saveDxyDataToDatabase(
    Map<String, dynamic> fetchedData,
    String fromDate,
  ) async {
    // FRED API는 요청한 fromDate부터 데이터를 주기 때문에,
    // 여기서 추가적인 날짜 필터링 (dataDate.isAtSameMomentAs(startDateTime) || dataDate.isAfter(startDateTime))은
    // API 호출 시 `observation_start` 파라미터가 정확히 적용되었다면 불필요합니다.
    // 하지만 안전을 위해 _effectiveStartDate보다 이전 데이터는 저장하지 않도록 유지합니다.
    final DateTime effectiveFilterStartDate = date_utils.DateUtils.parseDate(
      _effectiveStartDate,
    );

    if (fetchedData.containsKey('observations')) {
      final List<dynamic> observations = fetchedData['observations'];
      // FRED 데이터는 오래된 날짜부터 정렬되어 오는 경향이 있습니다.
      // API 응답 순서에 따라 처리하거나, 명확히 날짜 순으로 정렬하는 것이 좋습니다.
      // (FRED API 문서 확인 필요) 일단 기본 순서대로 처리합니다.
      for (var obs in observations) {
        final String dateString = obs['date'];
        final String? valueString = obs['value'];

        // 값이 "." 이거나 null이 아니고, 유효 시작 날짜 이후의 데이터인 경우에만 저장
        if (valueString != null && valueString != '.') {
          final dataDate = date_utils.DateUtils.parseDate(dateString);
          if (dataDate.isAtSameMomentAs(effectiveFilterStartDate) ||
              dataDate.isAfter(effectiveFilterStartDate)) {
            await _databaseHelper.insertOrUpdateData('dxy_index', {
              'date': dateString,
              'value': double.parse(valueString),
            });
          }
        }
      }
      debugPrint('DXY 데이터 저장 또는 업데이트 완료.');
    } else {
      debugPrint('DXY 데이터가 FRED API 응답에 없거나 형식이 올바르지 않습니다.');
    }
  }

  // DB에서 데이터를 불러오는 함수
  Future<Map<String, Map<String, dynamic>>> _loadDataFromDatabase() async {
    final Map<String, Map<String, dynamic>> loadedData = {};

    List<Map<String, dynamic>> usdkrwList = await _databaseHelper.getPrices(
      'usd_krw_rates',
    );
    loadedData['USD_KRW_DB'] = {
      for (var item in usdkrwList) item['date'] as String: item,
    };

    List<Map<String, dynamic>> dxyList = await _databaseHelper.getPrices(
      'dxy_index',
    );
    loadedData['DXY_DB'] = {
      for (var item in dxyList) item['date'] as String: item,
    };

    return loadedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SLV Tracker')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text('Error: $_error'))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('데이터 로딩 및 저장 완료!'),
                  Text(
                    'DB USD/KRW entries: ${_allData['USD_KRW_DB']?.length ?? 0}',
                  ),
                  Text('DB DXY entries: ${_allData['DXY_DB']?.length ?? 0}'),
                  ElevatedButton(
                    onPressed: () async {
                      await _databaseHelper
                          .deleteAllTables(); // 모든 데이터 삭제 (테스트용)
                      await _fetchAndStoreData(); // 다시 로드
                    },
                    child: const Text('DB 초기화 및 다시 로드 (테스트용)'),
                  ),
                  ElevatedButton(
                    onPressed: _fetchAndStoreData, // 업데이트 로직 호출
                    child: const Text('데이터 업데이트 시도'),
                  ),
                ],
              ),
            ),
    );
  }
}
