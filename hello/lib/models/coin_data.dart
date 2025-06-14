// lib/models/coin_data.dart

import 'package:intl/intl.dart';

class CoinData {
  final int? id;
  final String date;
  final int btc;
  final int eth;
  final int xrp;

  CoinData({
    this.id,
    required this.date,
    required this.btc,
    required this.eth,
    required this.xrp,
  });

  // Map에서 CoinData 객체를 생성하는 팩토리 생성자
  factory CoinData.fromMap(Map<String, dynamic> map) {
    return CoinData(
      id: map['id'] as int?,
      date: map['date'] as String,
      btc: map['btc'] as int,
      eth: map['eth'] as int,
      xrp: map['xrp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'date': date, 'btc': btc, 'eth': eth, 'xrp': xrp};
  }

  List<dynamic> toList() {
    return [date, btc, eth, xrp];
  }

  NumberFormat get numberFormatter {
    return NumberFormat('#,###');
  }

  String get fbtc {
    return numberFormatter.format(btc);
  }

  String get feth {
    return numberFormatter.format(eth);
  }

  String get fxrp {
    return numberFormatter.format(xrp);
  }

  @override
  String toString() {
    return '$date BTC: $fbtc원, ETH: $feth원, XRP: $fxrp원';
  }
}
