// lib/models/asset.dart

// 자산(종목)의 유형을 정의하는 enum
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
  int accountId;
  String name;
  AssetType assetType; // String 대신 enum 타입 사용
  String? memo;

  Asset({
    this.id,
    required this.accountId,
    required this.name,
    required this.assetType,
    this.memo,
  });

  // 데이터베이스 저장을 위한 Map 변환
  // DB 컬럼명과 필드명을 일치시킵니다.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'asset_type': assetType.name, // enum 값을 String으로 변환하여 저장
      'memo': memo,
    };
  }

  // 데이터베이스 Map에서 Asset 객체 생성
  // DB 컬럼명에 맞춰 데이터를 읽어옵니다.
  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      accountId: map['account_id'],
      name: map['name'],
      // DB에서 읽어온 String 값을 enum으로 변환.
      // AssetType.values는 모든 AssetType enum 값의 리스트를 반환합니다.
      // firstWhere를 사용하여 map['asset_type'] (String)과 이름이 같은 enum을 찾습니다.
      // orElse: () => AssetType.other: 만약 저장된 asset_type 값이 enum에 없는 경우,
      // 'other'로 기본값을 지정하여 앱이 크래시되지 않도록 합니다.
      assetType: AssetType.values.firstWhere(
        (e) => e.name == map['asset_type'],
        orElse: () => AssetType.other,
      ),
      memo: map['memo'],
    );
  }

  @override
  String toString() {
    return 'Asset{id: $id, accountId: $accountId, name: $name, assetType: $assetType, memo: $memo}';
  }
}
