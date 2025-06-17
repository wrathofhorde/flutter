// lib/models/asset_snapshot.dart
class AssetSnapshot {
  int? id;
  int assetId; // 어떤 Asset(종목)의 스냅샷인지 참조
  String snapshotDate; // YYYY-MM-DD 형식의 날짜 문자열
  int purchasePrice; // 해당 날짜 기준 매수금액 (정수)
  int currentValue; // 해당 날짜 기준 평가금액 (정수)
  double profitRate; // 해당 날짜 기준 수익률 (실수)
  double? profitRateChange; // 해당 날짜 기준 수익률 변화율 (실수, Nullable)

  AssetSnapshot({
    this.id,
    required this.assetId,
    required this.snapshotDate,
    required this.purchasePrice,
    required this.currentValue,
    required this.profitRate,
    this.profitRateChange,
  });

  // Map<String, dynamic>으로 변환하여 데이터베이스에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId, // 컬럼명 일치
      'snapshot_date': snapshotDate,
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'profit_rate': profitRate,
      'profit_rate_change': profitRateChange,
    };
  }

  // Map<String, dynamic>에서 AssetSnapshot 객체로 변환하여 데이터베이스에서 읽어올 때 사용
  factory AssetSnapshot.fromMap(Map<String, dynamic> map) {
    return AssetSnapshot(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int, // 컬럼명 일치
      snapshotDate: map['snapshot_date'] as String,
      purchasePrice: map['purchase_price'] as int,
      currentValue: map['current_value'] as int,
      profitRate: map['profit_rate'] as double,
      profitRateChange: map['profit_rate_change'] as double?,
    );
  }

  @override
  String toString() {
    return 'AssetSnapshot(id: $id, assetId: $assetId, date: $snapshotDate, '
        'purchase: $purchasePrice, current: $currentValue, '
        'profitRate: $profitRate%, profitRateChange: $profitRateChange%)';
  }
}
