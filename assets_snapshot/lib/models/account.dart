// account.dart

class Account {
  // SQLite의 INTEGER PRIMARY KEY AUTOINCREMENT는 null이 될 수 있음 (삽입 시 자동 생성)
  int? id;
  String name;
  String? description; // description은 null이 될 수 있음
  String createdAt;
  String updatedAt;
  // 새로 추가될 요약 정보 필드
  double? totalPurchasePrice;
  double? totalCurrentValue;
  double? totalProfitRate;

  // 생성자: 필수 필드를 포함하여 Account 객체를 생성합니다.
  Account({
    this.id, // id는 데이터베이스에서 자동 생성될 수 있으므로 선택적 (null 허용)
    required this.name,
    this.description,
    required this.createdAt, // 생성 시점의 타임스탬프를 외부에서 주입
    required this.updatedAt, // 생성 시점의 타임스탬프를 외부에서 주입
    // 생성자에도 추가 (기본값 null)
    this.totalPurchasePrice,
    this.totalCurrentValue,
    this.totalProfitRate,
  });

  // Map<String, dynamic> 형태로 변환하는 팩토리 메서드 (데이터베이스 저장을 위해)
  // SQLite는 Map 형태로 데이터를 받기 때문에 이 메서드가 유용합니다.
  Map<String, dynamic> toMap() {
    return {
      'id': id, // id가 null이면 SQLite가 자동 생성해줌
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
      // 이 필드들은 DB에 직접 저장되지 않으므로 toMap에는 포함하지 않습니다.
    };
  }

  // Map<String, dynamic> 형태를 Account 객체로 변환하는 팩토리 생성자 (데이터베이스에서 읽어올 때)
  // 데이터베이스에서 조회한 결과를 Account 객체로 쉽게 매핑할 수 있도록 돕습니다.
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?, // SQLite에서 읽어온 id (int로 캐스팅)
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      // fromMap에서는 요약 정보를 로드하지 않음 (따로 계산되어 주입될 것이므로)
      totalPurchasePrice: null,
      totalCurrentValue: null,
      totalProfitRate: null,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    String? description,
    String? createdAt,
    String? updatedAt,
    double? totalPurchasePrice, // copyWith에 추가
    double? totalCurrentValue, // copyWith에 추가
    double? totalProfitRate, // copyWith에 추가
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPurchasePrice: totalPurchasePrice ?? this.totalPurchasePrice, // 업데이트
      totalCurrentValue: totalCurrentValue ?? this.totalCurrentValue, // 업데이트
      totalProfitRate: totalProfitRate ?? this.totalProfitRate, // 업데이트
    );
  }

  // (선택 사항) 객체를 문자열로 표현하여 디버깅에 유용하게 사용합니다.
  @override
  String toString() {
    return 'Account(id: $id, name: $name, '
        'description: $description, createdAt: $createdAt, '
        'updatedAt: $updatedAt totalPurchasePrice: $totalPurchasePrice '
        'totalCurrentValue: $totalCurrentValue totalProfitRate: $totalProfitRate)';
  }
}
