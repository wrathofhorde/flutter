// lib/models/data_models.dart
class UsdKrwData {
  final DateTime date;
  final double rate;

  UsdKrwData({required this.date, required this.rate});

  // 데이터베이스 또는 JSON에서 객체로 변환
  factory UsdKrwData.fromMap(Map<String, dynamic> map) {
    return UsdKrwData(
      date: DateTime.parse(map['date']),
      rate: map['rate'] as double,
    );
  }

  // 객체에서 데이터베이스 또는 JSON으로 변환
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().split('T').first, // 'yyyy-MM-dd' 형식으로 저장
      'rate': rate,
    };
  }
}

class GoldData {
  final DateTime date;
  final double price;

  GoldData({required this.date, required this.price});

  factory GoldData.fromMap(Map<String, dynamic> map) {
    return GoldData(
      date: DateTime.parse(map['date']),
      price: map['price'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String().split('T').first, 'price': price};
  }
}

class SilverData {
  final DateTime date;
  final double price;

  SilverData({required this.date, required this.price});

  factory SilverData.fromMap(Map<String, dynamic> map) {
    return SilverData(
      date: DateTime.parse(map['date']),
      price: map['price'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String().split('T').first, 'price': price};
  }
}

class DollarIndexData {
  final DateTime date;
  final double price;

  DollarIndexData({required this.date, required this.price});

  factory DollarIndexData.fromMap(Map<String, dynamic> map) {
    return DollarIndexData(
      date: DateTime.parse(map['date']),
      price: map['price'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String().split('T').first, 'price': price};
  }
}

// 모든 데이터를 한번에 담을 수 있는 모델 (선택 사항이지만 편리함)
class AllFinancialData {
  final List<UsdKrwData> usdKrw;
  final List<GoldData> gold;
  final List<SilverData> silver;
  final List<DollarIndexData> dollarIndex;

  AllFinancialData({
    required this.usdKrw,
    required this.gold,
    required this.silver,
    required this.dollarIndex,
  });
}
