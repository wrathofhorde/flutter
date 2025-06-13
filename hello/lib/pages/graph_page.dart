import 'dart:io';

import 'package:csv/csv.dart';
import 'package:hello/model/coin_data.dart';
import 'package:hello/utils/coin_price_db.dart';
import 'package:hello/utils/duration.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
        _currentDateTitle = '데이터 로드 오류';
      });
    }
  }

  // --- CSV 저장 함수 추가 ---
  Future<void> _saveDailyDataAsCsv() async {
    // 1. 저장 권한 요청
    var status = await Permission.storage.request();
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- 1. 집계 가격 정보 테이블 ---
                Text(
                  '${_days.startDay} ~ ${_days.endDay} 평균가, 최고가, 최저가',
                  style: const TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _yearAggregatedData == null
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ), // 데이터 로딩 중 표시
                        )
                      : Table(
                          // DataTable 대신 Table 위젯 사용
                          border: TableBorder.all(
                            color: Colors.grey.shade400,
                          ), // 보더 추가
                          defaultColumnWidth: const FlexColumnWidth(
                            1.0,
                          ), // 모든 컬럼을 동일한 비율로 나눔
                          children: [
                            TableRow(
                              children: [
                                _buildTableHeaderCell('코인'),
                                _buildTableHeaderCell('평균가 (원)'),
                                _buildTableHeaderCell('최고가 (원)'),
                                _buildTableHeaderCell('최저가 (원)'),
                              ],
                            ),
                            _buildTableDataRow(
                              'BTC',
                              _yearAggregatedData!['btc'],
                            ),
                            _buildTableDataRow(
                              'ETH',
                              _yearAggregatedData!['eth'],
                            ),
                            _buildTableDataRow(
                              'XRP',
                              _yearAggregatedData!['xrp'],
                            ),
                          ],
                        ),
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
                const SizedBox(height: 10),
                // BTC 그래프 공간
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Text(
                    'BTC 그래프 (여기에 Fl_chart 등 라이브러리 사용 예정)',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 10),

                // ETH 그래프 공간
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Text(
                    'ETH 그래프 (여기에 Fl_chart 등 라이브러리 사용 예정)',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 10),

                // XRP 그래프 공간
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Text(
                    'XRP 그래프 (여기에 Fl_chart 등 라이브러리 사용 예정)',
                    style: TextStyle(color: Colors.black54),
                  ),
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

  TableRow _buildTableDataRow(String coinName, Map<String, dynamic> data) {
    final avg = data['avg'] as int;
    final max = data['max'] as int;
    final min = data['min'] as int;

    final numberFormat = NumberFormat('#,###', 'en_US');

    return TableRow(
      children: [
        _buildTableCell(coinName, textAlign: TextAlign.center),
        _buildTableCell(numberFormat.format(avg)),
        _buildTableCell(numberFormat.format(max)),
        _buildTableCell(numberFormat.format(min)),
      ],
    );
  }

  Widget _buildTableCell(
    String text, {
    TextAlign textAlign = TextAlign.right,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: 'Cascadia Code', // 폰트 패밀리 적용
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.center, // 헤더는 가운데 정렬
        style: const TextStyle(
          fontFamily: 'Cascadia Code', // 폰트 패밀리 적용
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
