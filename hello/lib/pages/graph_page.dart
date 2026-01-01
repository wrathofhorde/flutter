import 'dart:io';
import 'package:csv/csv.dart';
// import 'package:intl/intl.dart';
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
  // final _formatter = DateFormat('yyyy년 M월 d일(E)', 'ko_KR'); // 이 포맷터는 더 이상 앱바 타이틀에 직접 사용되지 않습니다.

  List<CoinData> _dailyCoinData = [];
  Map<String, dynamic>? _yearAggregatedData;

  @override
  void initState() {
    super.initState();
    // initState에서는 _days가 아직 초기화되지 않았으므로 _updateDateTitle 호출을 didChangeDependencies로 옮기거나,
    // initState에서 _days를 직접 초기화해야 합니다. 여기서는 didChangeDependencies에서 처리하는 방식 유지.
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

  Future<void> _fetchAndDisplayPrices() async {
    // _days 객체에서 현재 표시될 날짜를 가져옵니다.
    final startDate = _days.startDay;
    final endDate = _days.endDay;

    try {
      setState(() {
        _currentDateTitle = '$startDate ~ $endDate';
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
      debugPrint('[_fetchAndDisplayPrices]데이터 불러오기 중 오류 발생: $e');
      setState(() {
        _dailyCoinData = [];
        _yearAggregatedData = null;
        _currentDateTitle = '데이터 불러오기 중 오류 발생했습니다.';
      });
    }
  }

  // --- CSV 저장 함수 추가 ---
  Future<void> _saveDailyDataAsCsv() async {
    try {
      // 1. 저장 권한 요청
      var status = await Permission.storage.request();
      // 비동기 작업(await Permission.storage.request()) 후에 BuildContext를 사용하기 전에 mounted 확인
      if (!mounted) {
        return; // 위젯이 트리에 없으면 더 이상 진행하지 않음
      }
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 저장을 위한 저장소 권한이 필요합니다.')),
        );
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
      csvData.add(['Date', 'BTC', 'ETH', 'XRP', 'USDT']);
      // 평균가 추가
      final avgBtc = _yearAggregatedData?['btc']['avg'];
      final avgEth = _yearAggregatedData?['eth']['avg'];
      final avgXrp = _yearAggregatedData?['xrp']['avg'];
      final avgUsdt = _yearAggregatedData?['usdt']['avg'];
      csvData.add(["Average", avgBtc, avgEth, avgXrp, avgUsdt]);
      // 데이터 추가
      for (var data in _dailyCoinData) {
        csvData.add(data.toList());
      }
      // 3. CSV 문자열로 변환
      // 3. CSV 문자열로 변환 (구분자 탭으로 변경)
      String csvString = const ListToCsvConverter().convert(csvData);
      // 4. 파일 경로 설정 및 저장

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

  // USDT 그래프 데이터를 FlSpot 리스트로 변환하는 함수
  List<FlSpot> _getUsdtSpots() {
    return _dailyCoinData.asMap().entries.map((entry) {
      int index = entry.key;
      CoinData data = entry.value;
      return FlSpot(index.toDouble(), data.usdt.toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const double titleFontSize = 24;
    const double subtitleFontSize = 18;
    const double iconBtnSideMargin = 120.0;

    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        // AppBar의 title을 Stack으로 변경하여 아이콘 버튼과 겹쳐서 배치
        title: SizedBox(
          // AppBar의 title 공간을 차지하도록 SizedBox로 감쌈
          width: double.infinity, // 가로 전체를 사용하도록 함
          child: Stack(
            alignment:
                Alignment.center, // Stack의 기본 정렬을 중앙으로 설정 (Text 위젯 중앙 정렬)
            children: [
              // 텍스트 타이틀
              Text(
                _currentDateTitle,
                style: const TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ), // 타이틀 텍스트 스타일
                textAlign: TextAlign.center, // 텍스트 자체를 중앙 정렬
              ),
              // 이전 날짜 보기 버튼
              Positioned(
                left: iconBtnSideMargin, // AppBar의 왼쪽 끝에 붙임
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 30),
                  onPressed: () {
                    _days.goToPreviousMonth(); // 이전 달로 이동
                    _fetchAndDisplayPrices(); // 변경된 날짜로 데이터 다시 불러오기
                  },
                  tooltip: '이전 기간 보기',
                ),
              ),
              // 다음 날짜 보기 버튼
              Positioned(
                right: iconBtnSideMargin, // AppBar의 오른쪽 끝에 붙임
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 30),
                  onPressed: () {
                    _days.goToNextMonth(); // 다음 달로 이동
                    _fetchAndDisplayPrices(); // 변경된 날짜로 데이터 다시 불러오기
                  },
                  tooltip: '다음 기간 보기',
                ),
              ),
            ],
          ),
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- 1. 집계 가격 정보 테이블 ---
                CoinPriceTable(yearAggregatedData: _yearAggregatedData),
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
                // XRP 그래프 - CoinLineChart 위젯 사용
                CoinLineChart(
                  coinName: 'USDT',
                  spots: _getUsdtSpots(),
                  lineColor: Colors.purple, // USDT 그래프 색상 지정
                  fullCoinData: _dailyCoinData,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: BottomAppBar(
          color: Theme.of(context).colorScheme.primaryContainer,
          // Stack을 사용하여 위젯을 겹치고 위치를 정밀하게 제어
          child: Stack(
            children: [
              // '메인으로 돌아가기' 버튼 (중앙 정렬)
              Align(
                alignment: Alignment.center, // 중앙 정렬
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '메인으로 돌아가기',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 18),
                    ),
                  ),
                ),
              ),
              // CSV 다운로드 아이콘 버튼 (오른쪽 하단 정렬)
              Positioned(
                right: 10, // 오른쪽에서 10px 떨어진 위치
                bottom: 0, // 하단에 정렬 (BottomAppBar의 높이에 따라 조정될 수 있음)
                child: Tooltip(
                  message: 'CSV 저장',
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Colors.blueAccent),
                    onPressed: _saveDailyDataAsCsv,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
