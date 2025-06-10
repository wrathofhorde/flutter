import 'package:flutter/material.dart';
import 'package:hello/model/coin_data.dart';
import 'package:hello/utils/coin_price_db.dart';
import 'package:hello/utils/database_helper.dart';
import 'package:hello/utils/duration.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
// user defined
import 'package:hello/pages/price_page.dart';

void main() async {
  final String dbname = "sample_market.sq3";
  final String tablename = "major_coins";
  try {
    const windowSize = Size(1024, 720);
    WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화 보장
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: windowSize,
      center: false, // 창을 화면 중앙에 배치
      skipTaskbar: false, // 작업 표시줄에 앱 표시
      titleBarStyle: TitleBarStyle.normal,
      minimumSize: windowSize, // 창의 최소 크기를 고정 크기와 동일하게 설정
      maximumSize: windowSize, // 창의 최대 크기를 고정 크기와 동일하게 설정
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await initializeDateFormatting('ko_KR', null); // 한국어 로케일 데이터 초기화

    // 데이터베이스 초기화
    await DatabaseHelper.instance.init(dbname);
    debugPrint('DatabaseHelper initialized in main.');

    // Repository 인스턴스는 여기서 생성하여 Provider에 제공할 것
    CoinPriceDb priceDb = CoinPriceDb(DatabaseHelper.instance, tablename);
    priceDb.createTableIfNotExists();
    await priceDb.insertMajorCoinPrices(
      date: "2025-06-04",
      btc: 150000000,
      eth: 5000000,
      xrp: 4000,
    );

    String? lastUpdateDay = await priceDb.getLastUpdatedDate();

    List<CoinData> prices = await priceDb.getCoinDataByDateRange(
      startDate: "2025-06-01",
      endDate: "2025-06-08",
    );
    for (var price in prices) {
      debugPrint(price.toString());
    }

    Days days = Days(lastUpdateDay);
    days.print();

    runApp(
      Provider<CoinPriceDb>(
        create: (context) => priceDb, // 생성된 인스턴스를 제공
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('Fail to init App: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 2, 43, 65),
        ),
      ),
      home: const PricePage(),
    );
  }
}
