import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
// user defined
import 'package:hello/pages/graph_page.dart';
import 'package:hello/pages/price_page.dart';

void main() async {
  const windowSize = Size(1024, 720);
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화 보장
  await windowManager.ensureInitialized();

  // 창 옵션 설정
  WindowOptions windowOptions = const WindowOptions(
    size: windowSize, // 원하는 폭과 높이 설정 (예: 폭 360, 높이 800)
    center: false, // 창을 화면 중앙에 배치
    skipTaskbar: false, // 작업 표시줄에 앱 표시
    titleBarStyle: TitleBarStyle.normal, // 일반적인 타이틀 바 사용
    minimumSize: windowSize, // 창의 최소 크기를 고정 크기와 동일하게 설정
    maximumSize: windowSize, // 창의 최대 크기를 고정 크기와 동일하게 설정
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await initializeDateFormatting('ko_KR', null); // 한국어 로케일 데이터 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const PricePage(),
    );
  }
}
