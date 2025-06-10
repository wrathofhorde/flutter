import 'package:hello/utils/coin_price_db.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:hello/pages/graph_page.dart';
import 'package:provider/provider.dart';

class PricePage extends StatefulWidget {
  const PricePage({super.key});

  @override
  State<PricePage> createState() => _PricePageState();
}

class _PricePageState extends State<PricePage> {
  String _currentDateTitle = "";
  String _apiDataDisplay = "";
  // final repository = Provider.of<CoinPriceDb>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _updateDateTitle();
    _apiDataDisplay = "가격 정보를 로딩 중입니다...\n";
    _apiDataDisplay += "비트코인: 70,000,000원\n";
    _apiDataDisplay += "이더리움: 4,000,000원\n";
    _apiDataDisplay += "리플: 700원\n";
    _apiDataDisplay += "도지코인: 200원\n";
    _apiDataDisplay += "솔라나: 200,000원\n";
    _apiDataDisplay += "에이다: 800원\n";
    _apiDataDisplay += "체인링크: 25,000원\n";
    _apiDataDisplay += "폴카닷: 10,000원\n";
    _apiDataDisplay += "시바: 0.03원\n";
    _apiDataDisplay += "테조스: 3,000원\n";
    _apiDataDisplay += "라이트코인: 100,000원\n";
    _apiDataDisplay += "비트코인 캐시: 500,000원\n";
    _apiDataDisplay += "모네로: 200,000원\n";
    _apiDataDisplay += "이더리움 클래식: 40,000원\n";
    _apiDataDisplay += "네오: 15,000원\n";
    _apiDataDisplay += "퀀텀: 5,000원\n";
    _apiDataDisplay += "아이오타: 500원\n";
    _apiDataDisplay += "웨이브즈: 4,000원\n";
    _apiDataDisplay += "카르다노: 800원\n";
    _apiDataDisplay += "트론: 150원\n";
    _apiDataDisplay += "이오스: 1,000원\n";
    _apiDataDisplay += "스텔라 루멘: 200원\n";
    _apiDataDisplay += "아톰: 12,000원\n";
    _apiDataDisplay += "유니스왑: 10,000원\n";
    _apiDataDisplay += "링크: 25,000원\n";
    _apiDataDisplay += "도미노: 50,000원\n";
    _apiDataDisplay += "팬텀: 1,500원\n";
    _apiDataDisplay += "코스모스: 12,000원\n";
    _apiDataDisplay += "아발란체: 30,000원\n";
    _apiDataDisplay += "솔라나: 200,000원\n";
    _apiDataDisplay += "루나: 1,000,000원\n";
  }

  void _updateDateTitle() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR');
    setState(() {
      _currentDateTitle = formatter.format(now);
    });
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
              '실시간 가격 정보', // 제목을 좀 더 명확하게 변경
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
                        fontFamily: 'monospace', // 가독성을 위해 고정폭 폰트 추천
                        height: 1.5, // 줄 간격 조절
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
              child: TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(_createSlideRoute(const GraphPage()));
                },
                child: const Text(
                  '결과 보기',
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
