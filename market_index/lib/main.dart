// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 추가

// 비동기 main 함수
Future<void> main() async {
  // Flutter 앱이 시작하기 전에 dotenv를 로드해야 함
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // .env 파일 로드

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '환율 및 원자재 현황',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(), // 여기에 실제 홈 페이지 위젯을 넣을 예정
    );
  }
}

// TODO: MyHomePage 위젯은 나중에 구현합니다.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('환율 및 원자재 현황')),
      body: Center(
        child: Text('앱이 시작되었습니다. 데이터 로딩 중...'), // 임시 텍스트
      ),
    );
  }
}
