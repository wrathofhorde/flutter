// lib/models/asset.dart

enum AssetType { stock, crypto, deposit, bond, fund, etf, wrap, other }

enum AssetLocation { domestic, overseas }

class Asset {
  int? id;
  int accountId; // 주의: Dart 필드명은 camelCase (accountId)
  String name;
  AssetType assetType;
  AssetLocation assetLocation; // 새 컬럼 추가
  String? memo;
  int? purchasePrice;
  int? currentValue;
  double? lastProfitRate;

  Asset({
    this.id,
    required this.accountId,
    required this.name,
    required this.assetType,
    this.assetLocation = AssetLocation.domestic, // 기본값 설정
    this.memo,
    this.purchasePrice,
    this.currentValue,
    this.lastProfitRate,
  });

  // Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId, // !!! 여기서 'account_id'로 변경 !!!
      'name': name,
      'asset_type': assetType.toString().split('.').last,
      'asset_location': assetLocation.toString().split('.').last, // 새 컬럼
      'memo': memo,
      'purchasePrice': purchasePrice,
      'currentValue': currentValue,
      'lastProfitRate': lastProfitRate,
    };
  }

  // Map에서 Asset 객체 생성
  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      accountId: map['account_id'] as int, // !!! 여기서 'account_id'로 변경 !!!
      name: map['name'] as String,
      assetType: AssetType.values.firstWhere(
        (e) => e.toString().split('.').last == map['asset_type'],
      ),
      assetLocation: AssetLocation.values.firstWhere(
        (e) => e.toString().split('.').last == map['asset_location'],
        orElse: () => AssetLocation.domestic, // 기본값 처리
      ),
      memo: map['memo'] as String?,
      purchasePrice: map['purchasePrice'] != null
          ? (map['purchasePrice'] as num).toInt()
          : null,
      currentValue: map['currentValue'] != null
          ? (map['currentValue'] as num).toInt()
          : null,
      lastProfitRate: map['lastProfitRate'] != null
          ? (map['lastProfitRate'] as num).toDouble()
          : null,
    );
  }

  // toString (디버깅 용이)
  @override
  String toString() {
    return 'Asset(id: $id, accountId: $accountId, name: $name, assetType: $assetType, assetLocation: $assetLocation, memo: $memo, purchasePrice: $purchasePrice, currentValue: $currentValue, lastProfitRate: $lastProfitRate)';
  }

  // 데이터 업데이트를 위한 copyWith 메서드
  Asset copyWith({
    int? id,
    int? accountId,
    String? name,
    AssetType? assetType,
    AssetLocation? assetLocation,
    String? memo,
    int? purchasePrice,
    int? currentValue,
    double? lastProfitRate,
  }) {
    return Asset(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      assetType: assetType ?? this.assetType,
      assetLocation: assetLocation ?? this.assetLocation,
      memo: memo ?? this.memo,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValue: currentValue ?? this.currentValue,
      lastProfitRate: lastProfitRate ?? this.lastProfitRate,
    );
  }
}
