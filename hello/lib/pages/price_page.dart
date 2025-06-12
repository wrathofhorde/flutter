import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hello/utils/duration.dart';
import 'package:hello/model/coin_data.dart';
import 'package:hello/utils/closing_price.dart';
import 'package:hello/utils/coin_price_db.dart';

import 'package:provider/provider.dart';
import 'package:hello/pages/graph_page.dart';

class PricePage extends StatefulWidget {
  const PricePage({super.key});

  @override
  State<PricePage> createState() => _PricePageState();
}

class _PricePageState extends State<PricePage> {
  bool _hasFetchedData = false;
  String _apiDataDisplay = "";
  String _currentDateTitle = "";

  late final Days _days;
  late final CoinPriceDb _priceDb;
  late final ClosePrice _closePriceFetcher;

  @override
  void initState() {
    super.initState();
    _updateDateTitle();
    _closePriceFetcher = ClosePrice();
    _apiDataDisplay = "저장된 가격 정보를 불러오는 중입니다...\n";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetchedData) {
      _days = Provider.of<Days>(context, listen: false);
      _priceDb = Provider.of<CoinPriceDb>(context, listen: false);
      if (_days.lastUpdateDay == _days.yesterday) {
        setState(() {
          _apiDataDisplay += '최신 데이터로 업데이트 되어 있습니다.\n';
          _apiDataDisplay += '"가격 정보 보기" 페이지에서 직전달 1년 평균가를 확인할 수 있습니다.\n';
        });
      } else {
        _fetchAndDisplayPrices(); // 비동기 함수 호출 시작
      }
      _hasFetchedData = true; // 플래그 설정
    }
  }

  void _updateDateTitle() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 M월 d일(E)', 'ko_KR');
    // final formatter = DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR');
    setState(() {
      _currentDateTitle = formatter.format(now);
    });
  }

  Future<void> _fetchAndDisplayPrices() async {
    final formatter = _days.dateFormatter;

    setState(() {
      _apiDataDisplay += "서버에서 주요 코인 가격 정보를 가져오는 중...\n";
    });

    try {
      List<List<dynamic>> coinPirces = [];
      DateTime updateDay = _days.updateStartDay;
      final Duration oneDay = Duration(days: 1);
      final DateTime updateEndDay = _days.updateEndDay;

      while (updateDay.isBefore(updateEndDay) ||
          updateDay.isAtSameMomentAs(updateEndDay)) {
        debugPrint('현재 처리 중인 날짜: ${formatter.format(updateDay)}');

        final date = formatter.format(updateDay);
        final [btc, eth, xrp] = await _closePriceFetcher.getTradePricesForDay(
          date,
        );
        final coindata = CoinData(date: date, btc: btc, eth: eth, xrp: xrp);

        setState(() {
          _apiDataDisplay += "$coindata\n";
        });

        coinPirces.add(coindata.toList());
        updateDay = updateDay.add(oneDay);
      }

      setState(() {
        _apiDataDisplay += "주요 코인 가격 정보 저장 중...\n";
      });

      _priceDb.bulkInsertMajorCoinPrices(params: coinPirces);
      setState(() {
        _apiDataDisplay += '주요 코인 가격 정보 저장이 완료되었습니다.\n';
        _apiDataDisplay += '"가격 정보 보기" 페이지에서 확인할 수 있습니다.';
      });
    } catch (e) {
      setState(() {
        _apiDataDisplay = "가격 정보를 불러오는 데 실패했습니다: $e\n";
        _apiDataDisplay += "인터넷 연결을 확인하거나 잠시 후 다시 시도해 주세요.";
      });
      debugPrint('API 호출 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDateTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 전체적인 여백
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 자식 위젯을 가로로 최대한 늘림
          children: [
            const Text(
              '코인 가격 정보 업데이트', // 제목을 좀 더 명확하게 변경
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                // 남은 모든 공간을 SingleChildScrollView가 차지하도록 함
                child: Container(
                  padding: const EdgeInsets.all(12.0), // 텍스트와 테두리 사이 여백
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1.0), // 테두리
                    borderRadius: BorderRadius.circular(8.0), // 모서리 둥글게
                    color: Colors.grey[50], // 배경색 (선택 사항)
                  ),
                  child: SingleChildScrollView(
                    // 내용이 길어지면 스크롤 가능하게
                    child: SelectableText(
                      _apiDataDisplay, // _apiDataDisplay 변수 사용
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Cascadia Code', // 가독성을 위해 고정폭 폰트 추천
                        height: 1.5, // 줄 간격 조절
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 다른 위젯들이 있다면 여기에 추가될 수 있습니다.
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.primaryContainer, // 앱 테마에 맞는 색상
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 50,
              child: Tooltip(
                // Tooltip 위젯 추가
                message: '코인 가격 그래프, 직전 달 일년 평균 가격을 확인합니다.',
                child: TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(_createSlideRoute(const GraphPage()));
                  },
                  child: const Text(
                    '가격 정보 보기',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 18,
                    ), // 버튼 텍스트 색상
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageRoute _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // 오른쪽에서 시작 (다음 페이지가 들어올 때)
        const end = Offset.zero; // 원래 위치로 이동
        const curve = Curves.ease; // 부드러운 애니메이션 곡선

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
