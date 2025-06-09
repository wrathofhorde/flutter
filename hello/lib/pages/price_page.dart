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
  // final repository = Provider.of<CoinPriceDb>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _updateDateTitle();
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
      body: const Center(
        child: Text('This is the Price Page!', style: TextStyle(fontSize: 24)),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.primaryContainer, // 앱 테마에 맞는 색상
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              // TextButton 또는 ElevatedButton 사용
              onPressed: () {
                // Navigator를 사용하여 새 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GraphPage()),
                );
              },
              child: const Text(
                'Go to Second Page',
                style: TextStyle(color: Colors.blueAccent), // 버튼 텍스트 색상
              ),
            ),
          ],
        ),
      ),
    );
  }
}
