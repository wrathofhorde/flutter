// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:collection/collection.dart';
import 'dart:developer' as developer;

// 데이터 관련 import
import 'data/database_helper.dart';
import 'models/data_models.dart';
import 'utils/data_crawler.dart';
import 'widgets/gold_silver_chart.dart';

// 앱 시작점
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '환율 및 원자재 현황',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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
  late Future<Map<String, dynamic>> _dataFuture;
  int _monthsToShow = 36;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadDataAndCalculateMetrics();
  }

  Future<Map<String, dynamic>> _loadDataAndCalculateMetrics() async {
    developer.log('데이터 업데이트 시작...', name: 'MyHomePage');
    try {
      await runDataCollectionAndSave();
      developer.log('데이터 업데이트 완료.', name: 'MyHomePage');
    } catch (e) {
      developer.log('데이터 업데이트 중 오류 발생: $e', error: e, name: 'MyHomePage');
    }

    developer.log('데이터 로드 시작 (지난 $_monthsToShow개월)...', name: 'MyHomePage');
    final List<Map<String, dynamic>> rawData = await DatabaseHelper.loadData(
      _monthsToShow == 999 ? 9999 : _monthsToShow,
    );
    developer.log('${rawData.length}개의 데이터 로드 완료.', name: 'MyHomePage');

    double avgUsdKrw = 0.0;
    double avgGoldPrice = 0.0;
    double avgSilverPrice = 0.0;
    double avgDollarIndex = 0.0;
    double avgGoldSilverRatio = 0.0;

    if (rawData.isNotEmpty) {
      List<UsdKrwData> usdKrwList = rawData
          .where((e) => e.containsKey('usd_krw') && e['usd_krw'] != null)
          .map(
            (e) => UsdKrwData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              rate: e['usd_krw'] as double,
            ),
          )
          .toList();
      if (usdKrwList.isNotEmpty) {
        avgUsdKrw = usdKrwList.map((e) => e.rate).average;
      }

      List<GoldData> goldList = rawData
          .where((e) => e.containsKey('gold_price') && e['gold_price'] != null)
          .map(
            (e) => GoldData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              price: e['gold_price'] as double,
            ),
          )
          .toList();
      if (goldList.isNotEmpty) {
        avgGoldPrice = goldList.map((e) => e.price).average;
      }

      List<SilverData> silverList = rawData
          .where(
            (e) => e.containsKey('silver_price') && e['silver_price'] != null,
          )
          .map(
            (e) => SilverData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              price: e['silver_price'] as double,
            ),
          )
          .toList();
      if (silverList.isNotEmpty) {
        avgSilverPrice = silverList.map((e) => e.price).average;
      }

      List<DollarIndexData> dollarIndexList = rawData
          .where(
            (e) =>
                e.containsKey('dollar_index_price') &&
                e['dollar_index_price'] != null,
          )
          .map(
            (e) => DollarIndexData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              price: e['dollar_index_price'] as double,
            ),
          )
          .toList();
      if (dollarIndexList.isNotEmpty) {
        avgDollarIndex = dollarIndexList.map((e) => e.price).average;
      }

      List<double> goldSilverRatios = [];
      for (var item in rawData) {
        if (item.containsKey('gold_price') &&
            item.containsKey('silver_price') &&
            item['gold_price'] != null &&
            item['silver_price'] != null &&
            item['silver_price'] != 0) {
          goldSilverRatios.add(item['gold_price'] / item['silver_price']);
        }
      }
      if (goldSilverRatios.isNotEmpty) {
        avgGoldSilverRatio = goldSilverRatios.average;
      }
    }

    final allFinancialData = AllFinancialData(
      usdKrw: rawData
          .where((e) => e.containsKey('usd_krw') && e['usd_krw'] != null)
          .map(
            (e) => UsdKrwData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              rate: e['usd_krw'] as double,
            ),
          )
          .toList(),
      gold: rawData
          .where((e) => e.containsKey('gold_price') && e['gold_price'] != null)
          .map(
            (e) => GoldData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              price: e['gold_price'] as double,
            ),
          )
          .toList(),
      silver: rawData
          .where(
            (e) => e.containsKey('silver_price') && e['silver_price'] != null,
          )
          .map(
            (e) => SilverData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              price: e['silver_price'] as double,
            ),
          )
          .toList(),
      dollarIndex: rawData
          .where(
            (e) =>
                e.containsKey('dollar_index_price') &&
                e['dollar_index_price'] != null,
          )
          .map(
            (e) => DollarIndexData(
              date: e['date'] is String
                  ? DateTime.parse(e['date'] as String)
                  : e['date'] as DateTime,
              price: e['dollar_index_price'] as double,
            ),
          )
          .toList(),
    );

    return {
      'data': allFinancialData,
      'metrics': {
        'avgUsdKrw': avgUsdKrw,
        'avgGoldPrice': avgGoldPrice,
        'avgSilverPrice': avgSilverPrice,
        'avgDollarIndex': avgDollarIndex,
        'avgGoldSilverRatio': avgGoldSilverRatio,
      },
      'months': _monthsToShow,
    };
  }

  void _refreshData() {
    setState(() {
      _dataFuture = _loadDataAndCalculateMetrics();
    });
  }

  Future<void> _showMonthsSelectionDialog() async {
    final selectedMonths = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('조회 기간 선택 (개월)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(
                title: const Text('3개월'),
                value: 3,
                groupValue: _monthsToShow,
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
              RadioListTile<int>(
                title: const Text('6개월'),
                value: 6,
                groupValue: _monthsToShow,
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
              RadioListTile<int>(
                title: const Text('12개월'),
                value: 12,
                groupValue: _monthsToShow,
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
              RadioListTile<int>(
                title: const Text('24개월'),
                value: 24,
                groupValue: _monthsToShow,
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
              RadioListTile<int>(
                title: const Text('36개월 (기본)'),
                value: 36,
                groupValue: _monthsToShow,
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
              RadioListTile<int>(
                title: const Text('전체 기간'),
                value: 999,
                groupValue: _monthsToShow,
                onChanged: (value) {
                  Navigator.pop(dialogContext, value);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );

    if (selectedMonths != null && selectedMonths != _monthsToShow) {
      setState(() {
        _monthsToShow = selectedMonths;
        _dataFuture = _loadDataAndCalculateMetrics();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환율 및 원자재 현황'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: '조회 기간 선택',
            onPressed: _showMonthsSelectionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '데이터 새로고침',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('데이터 업데이트 및 로드 중...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text('데이터 로드 오류: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final AllFinancialData financialData = snapshot.data!['data'];
            final Map<String, dynamic> metrics = snapshot.data!['metrics'];
            final int displayMonths = snapshot.data!['months'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '지난 ${displayMonths == 999 ? "모든" : displayMonths}개월 데이터 현황',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  _buildMetricsTable(metrics, displayMonths),
                  const SizedBox(height: 30),
                  GoldSilverChart(
                    goldData: financialData.gold,
                    silverData: financialData.silver,
                    monthsToShow: displayMonths,
                  ),
                  const SizedBox(height: 20),
                  // TODO: 여기에 다른 차트를 하나씩 추가할 예정입니다.
                  Center(child: Text('Gold/Silver Ratio 차트가 여기에 표시될 예정입니다.')),
                  const SizedBox(height: 20),
                  Center(
                    child: Text('Gold vs Dollar Index 차트가 여기에 표시될 예정입니다.'),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text('USD/KRW vs Dollar Index 차트가 여기에 표시될 예정입니다.'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          } else {
            return const Center(child: Text('데이터를 로드할 수 없습니다.'));
          }
        },
      ),
    );
  }

  Widget _buildMetricsTable(Map<String, dynamic> metrics, int months) {
    final List<String> labels = [
      'USD/KRW 평균',
      '금 가격 평균 (USD/OZS)',
      '은 가격 평균 (USD/OZS)',
      '달러 인덱스 평균',
      '금/은 비율 평균',
    ];
    final List<double> values = [
      metrics['avgUsdKrw'] ?? 0.0,
      metrics['avgGoldPrice'] ?? 0.0,
      metrics['avgSilverPrice'] ?? 0.0,
      metrics['avgDollarIndex'] ?? 0.0,
      metrics['avgGoldSilverRatio'] ?? 0.0,
    ];
    final List<String> formattedValues = values
        .map((e) => e.toStringAsFixed(2))
        .toList();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '평균 지표 (지난 ${months == 999 ? "모든" : months}개월)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Row(
              children: labels
                  .map(
                    (label) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(), // <--- 이 부분에 .toList() 추가
            ),
            const Divider(height: 10),
            Row(
              children: formattedValues
                  .map(
                    (value) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(), // <--- 이 부분에 .toList() 추가
            ),
          ],
        ),
      ),
    );
  }
}

extension ListDoubleExtension on List<double> {
  double get average {
    if (isEmpty) return 0.0;
    return sum / length;
  }
}
