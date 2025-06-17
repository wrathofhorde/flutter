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
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAssetScreen(accountId: accountId),
            ),
          );
          if (result == true) {
            onRefreshAssets(); // 새 종목 추가 후 목록 갱신
          }
        },
        borderRadius: BorderRadius.circular(8.0),
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
