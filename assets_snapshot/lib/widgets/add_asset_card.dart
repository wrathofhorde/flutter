// lib/widgets/add_asset_card.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/screens/add_asset_screen.dart'; // AddAssetScreen 임포트

class AddAssetCard extends StatelessWidget {
  final int accountId; // 새 종목 추가 시 필요한 accountId
  final VoidCallback onRefreshAssets; // 종목 목록 갱신 콜백

  const AddAssetCard({
    super.key,
    required this.accountId,
    required this.onRefreshAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // 추가 버튼 타일의 배경색
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.blue.shade200, width: 1), // 테두리 추가
      ),
      margin: const EdgeInsets.all(0), // <--- 다른 카드와 크기 일치를 위해 마진 0 설정
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAssetScreen(accountId: accountId),
            ),
          );
          if (result == true && context.mounted) {
            // <--- context.mounted 체크 추가
            onRefreshAssets(); // 새 종목 추가 후 목록 갱신
          }
        },
        borderRadius: BorderRadius.circular(
          12.0,
        ), // Card의 borderRadius와 일치시켜야 효과가 자연스러움
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 50.0, color: Colors.blue),
              SizedBox(height: 8.0),
              Text(
                '새 종목 추가',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
