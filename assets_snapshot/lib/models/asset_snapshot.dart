// lib/models/asset_snapshot.dart

class AssetSnapshot {
  int? id; // 스냅샷 고유 ID (SQLite PK)
  int assetId; // 연결된 자산의 ID
  String snapshotDate; // 스냅샷 날짜 (YYYY-MM-DD 형식)
  int purchasePrice; // 해당 날짜의 매수 금액
  int currentValue; // 해당 날짜의 평가 금액
  double profitRate; // 해당 날짜의 수익률
  double profitRateChange; // 이전 스냅샷 대비 수익률 변화율

  AssetSnapshot({
    this.id,
    required this.assetId,
    required this.snapshotDate,
    required this.purchasePrice,
    required this.currentValue,
    required this.profitRate,
    required this.profitRateChange,
  });

  // Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'snapshot_date': snapshotDate,
      'purchasePrice': purchasePrice,
      'currentValue': currentValue,
      'profitRate': profitRate,
      'profitRateChange': profitRateChange,
    };
  }

  // Map에서 AssetSnapshot 객체 생성
  factory AssetSnapshot.fromMap(Map<String, dynamic> map) {
    return AssetSnapshot(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      snapshotDate: map['snapshot_date'] as String,
      purchasePrice: (map['purchasePrice'] as num).toInt(),
      currentValue: (map['currentValue'] as num).toInt(),
      profitRate: (map['profitRate'] as num).toDouble(),
      profitRateChange: (map['profitRateChange'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'AssetSnapshot(id: $id, assetId: $assetId, snapshotDate: $snapshotDate, purchasePrice: $purchasePrice, currentValue: $currentValue, profitRate: $profitRate, profitRateChange: $profitRateChange)';
  }
}
