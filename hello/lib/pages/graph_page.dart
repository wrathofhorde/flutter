import 'package:hello/utils/coin_price_db.dart';
import 'package:hello/utils/duration.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  int _counter = 0;
  bool _hasFetchedData = false;
  String _currentDateTitle = "";
  late final Days _days;
  late final CoinPriceDb _priceDb;
  final _formatter = DateFormat('yyyy년 M월 d일(E)', 'ko_KR');

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

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  Future<void> _fetchAndDisplayPrices() async {
    setState(() {
      _currentDateTitle = '${_days.startDay}~${_days.endDay} 주요 코인 가격';
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _decrementCounter,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 40),
                ElevatedButton(
                  onPressed: _incrementCounter,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      // !!! 원래 페이지로 돌아갈 버튼 추가 !!!
      bottomNavigationBar: BottomAppBar(
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
    );
  }
}
