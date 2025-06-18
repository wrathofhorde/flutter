// lib/models/asset.dart

enum AssetType { stock, crypto, deposit, bond, fund, etf, wrap, cash, other }

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
  DateTime? createdAt; // DateTime 타입으로 변경, nullable 허용
  DateTime? updatedAt; // DateTime 타입으로 변경, nullable 허용

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
    this.createdAt, // 생성자에도 추가
    this.updatedAt, // 생성자에도 추가
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
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'last_profit_rate': lastProfitRate,
      'created_at': createdAt != null
          ? createdAt!.toIso8601String()
          : DateTime.now().toIso8601String(), // null이면 현재 시간으로 설정
      'updated_at': updatedAt != null
          ? updatedAt!.toIso8601String()
          : DateTime.now().toIso8601String(), // null이면 현재 시간으로 설정
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
        orElse: () => AssetType.other, // 찾지 못했을 경우 기본값 (other) 설정
      ),
      assetLocation: AssetLocation.values.firstWhere(
        (e) => e.toString().split('.').last == map['asset_location'],
        orElse: () => AssetLocation.domestic, // 기본값 처리
      ),
      memo: map['memo'] as String?,
      purchasePrice: map['purchase_price'] != null
          ? (map['purchase_price'] as num).toInt()
          : null,
      currentValue: map['current_value'] != null
          ? (map['current_value'] as num).toInt()
          : null,
      lastProfitRate: map['last_profit_rate'] != null
          ? (map['last_profit_rate'] as num).toDouble()
          : null,
      // String을 DateTime 객체로 변환
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null, // 이 부분 추가
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null, // 이 부분 추가
    );
  }

  // AssetType enum 값을 한글 텍스트로 변환하는 getter 추가
  String get assetTypeInKorean {
    switch (assetType) {
      case AssetType.stock:
        return '주식';
      case AssetType.crypto:
        return '가상화폐';
      case AssetType.deposit:
        return '예금';
      case AssetType.bond:
        return '채권';
      case AssetType.fund:
        return '펀드';
      case AssetType.etf:
        return 'ETF';
      case AssetType.wrap:
        return 'Wrap';
      case AssetType.cash: // 'cash' 추가
        return '현금';
      case AssetType.other:
        return '기타';
    }
  }

  // AssetLocation enum 값을 한글 텍스트로 변환하는 getter 추가
  String get assetLocationInKorean {
    switch (assetLocation) {
      case AssetLocation.domestic:
        return '국내';
      case AssetLocation.overseas:
        return '해외';
    }
  }

  // toString (디버깅 용이)
  @override
  String toString() {
    return 'Asset(id: $id, '
        'accountId: $accountId, name: $name, '
        'assetType: $assetType, assetLocation: $assetLocation, '
        'memo: $memo, purchasePrice: $purchasePrice, '
        'currentValue: $currentValue, lastProfitRate: $lastProfitRate '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
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
    DateTime? createdAt, // copyWith에도 추가
    DateTime? updatedAt, // copyWith에도 추가
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
