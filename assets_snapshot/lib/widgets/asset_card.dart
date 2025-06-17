// lib/widgets/asset_card.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/asset.dart';
import 'package:assets_snapshot/screens/add_asset_screen.dart'; // AddAssetScreen 임포트
import 'package:assets_snapshot/database/database_helper.dart'; // 삭제를 위해 필요

class AssetCard extends StatelessWidget {
  final Asset asset;
  final int accountId; // Asset 추가/수정 시 필요한 accountId
  final VoidCallback onRefreshAssets; // 종목 목록 갱신 콜백

  const AssetCard({
    super.key,
    required this.asset,
    required this.accountId,
    required this.onRefreshAssets,
  });

  Future<void> _deleteAsset(BuildContext context, int assetId) async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.deleteAsset(assetId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종목이 삭제되었습니다.')));
      onRefreshAssets(); // 삭제 후 목록 갱신
    } catch (e) {
      debugPrint('Failed to delete asset: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('종목 삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8.0),
                Text(
                  '유형: ${asset.assetType.name}',
                  style: const TextStyle(fontSize: 14.0, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (asset.memo != null && asset.memo!.isNotEmpty)
                  Text(
                    '메모: ${asset.memo}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
              ],
            ),
          ),
          // 수정 버튼 (좌상단)
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              tooltip: '수정',
              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAssetScreen(
                      accountId: accountId, // accountId 전달
                      asset: asset, // 수정할 asset 객체 전달
                    ),
                  ),
                );
                if (result == true) {
                  onRefreshAssets(); // 수정 후 목록 갱신
                }
              },
            ),
          ),
          // 삭제 버튼 (우상단)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: '삭제',
              icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('종목 삭제'),
                    content: Text('${asset.name} 종목을 정말 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          _deleteAsset(context, asset.id!); // 삭제 함수 호출
                          Navigator.of(ctx).pop();
                        },
                        child: const Text(
                          '삭제',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
