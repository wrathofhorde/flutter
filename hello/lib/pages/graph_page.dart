import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// user defined
import 'package:hello/utils/duration.dart';
import 'package:hello/models/coin_data.dart';
import 'package:hello/utils/coin_price_db.dart';
import 'package:hello/widgets/coin_line_chart.dart';
import 'package:hello/widgets/coin_price_table.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  bool _hasFetchedData = false;
  String _currentDateTitle = "";
  late final Days _days;
  late final CoinPriceDb _priceDb;
  final _formatter = DateFormat('yyyy년 M월 d일(E)', 'ko_KR');

  List<CoinData> _dailyCoinData = [];
  Map<String, dynamic>? _yearAggregatedData;

  @override
  void initState() {
    super.initState();
    _updateDateTitle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetchedData) {
      _days = Provider.of<Days>(context, listen: false);
      _priceDb = Provider.of<CoinPriceDb>(context, listen: false);
      _fetchAndDisplayPrices();
      _hasFetchedData = true;
    }
  }

  void _updateDateTitle() {
    final now = DateTime.now();

    setState(() {
      _currentDateTitle = _formatter.format(now);
    });
  }

  Future<void> _fetchAndDisplayPrices() async {
    final startDate = _days.startDay;
    final endDate = _days.endDay;

    try {
      setState(() {
        _currentDateTitle = '${_days.startDay} ~ ${_days.endDay}';
      });
      final dailyData = await _priceDb.getCoinDataByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      final Map<String, dynamic> yearAggregatedData = await _priceDb
          .getAggregatedCoinPrices(startDate: startDate, endDate: endDate);
      setState(() {
        _dailyCoinData = dailyData; // 일별 데이터 저장
        _yearAggregatedData = yearAggregatedData; // 연간 집계 데이터 저장
      });
      for (var price in dailyData) {
        debugPrint(price.toString());
      }
    } catch (e) {
      debugPrint('데이터 불러오기 중 오류 발생: $e');
      setState(() {
        _dailyCoinData = [];
        _yearAggregatedData = null;
        _currentDateTitle = '데이터 불러오기 중 오류 발생했습니다.';
      });
    }
  }

  // --- CSV 저장 함수 추가 ---
  Future<void> _saveDailyDataAsCsv() async {
    // 1. 저장 권한 요청
    var status = await Permission.storage.request();
    // 비동기 작업(await Permission.storage.request()) 후에 BuildContext를 사용하기 전에 mounted 확인
    if (!mounted) {
      return; // 위젯이 트리에 없으면 더 이상 진행하지 않음
    }
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('파일 저장을 위한 저장소 권한이 필요합니다.')));
      return;
    }
    if (_dailyCoinData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장할 일별 코인 데이터가 없습니다.')));
      return;
    }
    // 2. CSV 데이터 준비
    List<List<dynamic>> csvData = [];
    // 헤더 추가
    csvData.add(['Date', 'BTC', 'ETH', 'XRP']);
    // 평균가 추가
    final avgBtc = _yearAggregatedData?['btc']['avg'];
    final avgEth = _yearAggregatedData?['eth']['avg'];
    final avgXrp = _yearAggregatedData?['xrp']['avg'];
    csvData.add(["Average", avgBtc, avgEth, avgXrp]);
    // 데이터 추가
    for (var data in _dailyCoinData) {
      csvData.add(data.toList());
    }
    // 3. CSV 문자열로 변환
    // 3. CSV 문자열로 변환 (구분자 탭으로 변경)
    String csvString = const ListToCsvConverter().convert(csvData);
    // 4. 파일 경로 설정 및 저장
    try {
      final directory = await getApplicationDocumentsDirectory();
      final subDirectory = 'coin prices';
      // 서브 디렉터리 경로 생성
      final targetDirectory = Directory('${directory.path}/$subDirectory');
      // 서브 디렉터리가 없으면 생성 (recursive: true로 중간 경로도 함께 생성)
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }
      final filename = '${_days.startDay}-${_days.endDay}.csv';
      final path = '${targetDirectory.path}/$filename'; // 수정된 경로 사용
      final file = File(path);

      await file.writeAsString(csvString);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV 파일이 $path 에 저장되었습니다.')));
      debugPrint('CSV 파일 저장 완료: $path');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV 파일 저장 중 오류 발생: $e')));
      debugPrint('CSV 파일 저장 오류: $e');
    }
  }

  // BTC 그래프 데이터를 FlSpot 리스트로 변환하는 함수
  List<FlSpot> _getBtcSpots() {
    return _dailyCoinData.asMap().entries.map((entry) {
      int index = entry.key;
      CoinData data = entry.value;
      return FlSpot(index.toDouble(), data.btc.toDouble());
    }).toList();
  }

  // ETH 그래프 데이터를 FlSpot 리스트로 변환하는 함수
  List<FlSpot> _getEthSpots() {
    return _dailyCoinData.asMap().entries.map((entry) {
      int index = entry.key;
      CoinData data = entry.value;
      return FlSpot(index.toDouble(), data.eth.toDouble());
    }).toList();
  }

  // XRP 그래프 데이터를 FlSpot 리스트로 변환하는 함수
  List<FlSpot> _getXrpSpots() {
    return _dailyCoinData.asMap().entries.map((entry) {
      int index = entry.key;
      CoinData data = entry.value;
      return FlSpot(index.toDouble(), data.xrp.toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const double subtitleFontSize = 18;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDateTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          // CSV 저장 버튼 추가
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _saveDailyDataAsCsv, // CSV 저장 함수 호출
            tooltip: '일별 코인 가격 CSV로 저장',
          ),
        ],
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- 1. 집계 가격 정보 테이블 ---
                CoinPriceTable(
                  // startDate: _days.startDay,
                  // endDate: _days.endDay,
                  yearAggregatedData: _yearAggregatedData,
                ),
                const SizedBox(height: 10),
                // --- 2. 코인별 그래프 섹션 ---
                const Text(
                  '코인별 1년 종가 변화',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                // BTC 그래프 - CoinLineChart 위젯 사용
                CoinLineChart(
                  coinName: 'BTC',
                  spots: _getBtcSpots(),
                  lineColor: Colors.deepOrangeAccent,
                  fullCoinData: _dailyCoinData,
                ),
                const SizedBox(height: 5),
                // ETH 그래프 - CoinLineChart 위젯 사용
                CoinLineChart(
                  coinName: 'ETH',
                  spots: _getEthSpots(),
                  lineColor: Colors.blueAccent, // ETH 그래프 색상 지정
                  fullCoinData: _dailyCoinData,
                ),
                const SizedBox(height: 5),
                // XRP 그래프 - CoinLineChart 위젯 사용
                CoinLineChart(
                  coinName: 'XRP',
                  spots: _getXrpSpots(),
                  lineColor: Colors.green, // XRP 그래프 색상 지정
                  fullCoinData: _dailyCoinData,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      // !!! 원래 페이지로 돌아갈 버튼 추가 !!!
      bottomNavigationBar: SizedBox(
        height: 60,
        child: BottomAppBar(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '메인으로 돌아가기',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 18,
                    ), // 버튼 텍스트 색상
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 이 함수들은 이제 CoinPriceTable 위젯 내부로 이동했습니다.
  // TableRow _buildTableDataRow(String coinName, Map<String, dynamic> data) { ... }
  // Widget _buildTableCell(String text, { ... }) { ... }
  // Widget _buildTableHeaderCell(String text) { ... }
}
