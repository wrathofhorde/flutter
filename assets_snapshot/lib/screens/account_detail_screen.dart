// lib/screens/account_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/asset.dart';

// 분리한 위젯 임포트
import 'package:assets_snapshot/widgets/asset_card.dart';
import 'package:assets_snapshot/widgets/add_asset_card.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Asset> _assets = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.name} 상세'),
        actions: const [],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 2.0,
          mainAxisSpacing: 2.0,
          childAspectRatio: 1.0,
        ),
        itemCount: _assets.length + 1, // 자산 목록 + "새 종목 추가" 타일
        itemBuilder: (context, index) {
          if (index == _assets.length) {
            // "새 종목 추가" 타일
            return AddAssetCard(
              accountId: widget.account.id!, // accountId 전달
              onRefreshAssets: _loadAssets, // 목록 갱신 콜백 전달
            );
          }
          // 기존 종목 타일
          final asset = _assets[index];
          return AssetCard(
            asset: asset,
            // accountId는 AssetCard 내부에서 asset.accountId로 접근 가능하므로 불필요합니다.
            // onRefreshAssets 대신 AssetCard가 요구하는 콜백으로 변경합니다.
            onAssetUpdated: _loadAssets, // !!! 추가: 종목 업데이트 시 _loadAssets 호출 !!!
            onAssetDeleted: _loadAssets, // !!! 추가: 종목 삭제 시 _loadAssets 호출 !!!
          );
        },
      ),
    );
  }
}
