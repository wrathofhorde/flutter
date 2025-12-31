// lib/models/coin_data.dart

import 'package:intl/intl.dart';

class CoinData {
  final int? id;
  final String date;
  final int btc;
  final int eth;
  final int xrp;
  final int usdt;

  CoinData({
    this.id,
    required this.date,
    required this.btc,
    required this.eth,
    required this.xrp,
    required this.usdt,
  });

  // Map에서 CoinData 객체를 생성하는 팩토리 생성자
  factory CoinData.fromMap(Map<String, dynamic> map) => CoinData(
    id: map['id'] as int?,
    date: map['date'] as String,
    btc: map['btc'] as int,
    eth: map['eth'] as int,
    xrp: map['xrp'] as int,
    usdt: map['usdt'] as int,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'btc': btc,
    'eth': eth,
    'xrp': xrp,
    'usdt': usdt,
  };

  List<dynamic> toList() => [date, btc, eth, xrp, usdt];

  NumberFormat get _numberFormatter => NumberFormat('#,###');

  String get fbtc => _numberFormatter.format(btc);

  String get feth => _numberFormatter.format(eth);

  String get fxrp => _numberFormatter.format(xrp);

  String get fusdt => _numberFormatter.format(usdt);

  @override
  String toString() => '$date BTC:$fbtc원, ETH:$feth원, XRP:$fxrp원, USDT:$fusdt원';
}
