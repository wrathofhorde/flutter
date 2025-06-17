// lib/models/asset.dart

// 1. 자산(종목)의 투자 지역을 정의하는 enum 추가
enum AssetLocation {
  domestic, // 국내
  overseas, // 해외
}

// 기존 AssetType enum (유지)
enum AssetType {
  stock, // 주식
  crypto, // 가상화폐
  deposit, // 예금
  bond, // 채권
  fund, // 펀드
  etf, // ETF
  wrap, // Wrap
  other, // 기타
}

class Asset {
  int? id;
  int accountId; // 어느 계좌에 속하는지
  String name;
  AssetType assetType;
  AssetLocation assetLocation;
  String? memo;
  int? purchasePrice;
  int? currentValue;
  double? lastProfitRate;

  Asset({
    this.id,
    required this.accountId,
    required this.name,
    required this.assetType,
    required this.assetLocation,
    this.memo,
    this.purchasePrice,
    this.currentValue,
    this.lastProfitRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'name': name,
      'assetType': assetType.name,
      'asset_location': assetLocation.name,
      'memo': memo,
      'purchasePrice': purchasePrice,
      'currentValue': currentValue,
      'lastProfitRate': lastProfitRate,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      accountId: map['accountId'] as int,
      name: map['name'] as String,
      assetType: AssetType.values.firstWhere(
        (e) => e.name == map['assetType'],
        orElse: () => AssetType.other,
      ),
      // !!! fromMap()에 추가: String에서 enum으로 변환. 기본값 'domestic' 처리 !!!
      assetLocation: AssetLocation.values.firstWhere(
        (e) =>
            e.name ==
            map['asset_location'], // 'domestic' 또는 'overseas' 문자열을 enum으로
        orElse: () => AssetLocation.domestic, // 찾지 못할 경우 기본값 'domestic'
      ),
      memo: map['memo'] as String?,
      purchasePrice: map['purchasePrice'] as int?,
      currentValue: map['currentValue'] as int?,
      lastProfitRate: map['lastProfitRate'] as double?,
    );
  }

  @override
  String toString() {
    return 'Asset(id: $id, accountId: $accountId, name: $name, assetType: ${assetType.name}, assetLocation: ${assetLocation.name}, memo: $memo, purchasePrice: $purchasePrice, currentValue: $currentValue, lastProfitRate: $lastProfitRate)';
  }
}
