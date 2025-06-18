// lib/screens/asset_list_screen.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/asset.dart';

// 분리한 위젯 임포트
import 'package:assets_snapshot/widgets/asset_card.dart';
import 'package:assets_snapshot/widgets/add_asset_card.dart'; // AddAssetCard 임포트

class AssetListScreen extends StatefulWidget {
  final Account account; // 현재 보고 있는 계좌 정보
  final VoidCallback onAssetUpdated; // 부모 (AccountListScreen) 갱신을 위한 콜백

  const AssetListScreen({
    // 생성자 업데이트
    super.key,
    required this.account, // 'account' 매개변수 필수
    required this.onAssetUpdated, // 'onAssetUpdated' 매개변수 필수
  });

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Asset> _assets = [];

  @override
  void initState() {
    super.initState();
    _loadAssets(); // 초기 자산 목록 로드
  }

  // 특정 계좌(account_id)에 속한 자산만 로드하는 비동기 메서드
  Future<void> _loadAssets() async {
    try {
      final assets = await _dbHelper.getAssetsByAccountId(widget.account.id!);
      setState(() {
        _assets = assets;
      });
      debugPrint(
        'Loaded assets for account ${widget.account.name}: ${_assets.length} items',
      );
    } catch (e) {
      debugPrint('Failed to load assets: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('종목을 불러오는 데 실패했습니다: $e')));
    }
  }

  // 자산 정보 수정/추가 후 목록을 새로고침하는 내부 콜백
  void _onAssetUpdatedInternal() {
    _loadAssets(); // 현재 화면의 자산 목록 갱신
    widget.onAssetUpdated(); // 부모(AccountListScreen)에게도 자산 업데이트 알림
  }

  // 자산 삭제 후 목록을 새로고침하는 내부 콜백
  void _onAssetDeletedInternal(String assetName) {
    _loadAssets(); // 현재 화면의 자산 목록 갱신
    widget.onAssetUpdated(); // 부모(AccountListScreen)에게도 자산 삭제 알림
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$assetName 종목이 삭제되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.name} 계좌 자산'), // 앱바 제목을 계좌명으로
        actions: const [], // 앱바의 '+' 아이콘 제거
      ),
      body: GridView.builder(
        // <--- _assets.isEmpty 조건문 제거, 항상 GridView.builder 렌더링
        padding: const EdgeInsets.all(8.0), // 그리드 전체 패딩
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 한 줄에 4개의 종목 카드 표시 (태블릿에 적합)
          crossAxisSpacing: 2.0, // 가로 간격
          mainAxisSpacing: 2.0, // 세로 간격
          childAspectRatio: 1.0, // 카드 비율 (정사각형)
        ),
        itemCount: _assets.length + 1, // 자산 목록 + "새 종목 추가" 타일 (항상 1 이상)
        itemBuilder: (context, index) {
          if (index == _assets.length) {
            // 마지막 인덱스에 "새 종목 추가" 타일 배치
            return AddAssetCard(
              // AddAssetCard 위젯 사용
              accountId: widget.account.id!, // 현재 계좌 ID 전달
              onRefreshAssets: _onAssetUpdatedInternal, // 자산 목록 갱신 콜백 전달
            );
          }
          // 기존 종목 타일 (AssetCard) 표시
          final asset = _assets[index];
          return AssetCard(
            asset: asset, // 종목 정보 전달
            onAssetUpdated: _onAssetUpdatedInternal, // 종목 업데이트 시 내부 콜백 호출
            onAssetDeleted: () =>
                _onAssetDeletedInternal(asset.name), // 종목 삭제 시 내부 콜백 호출
          );
        },
      ),
    );
  }
}
