// lib/widgets/add_account_card.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/screens/add_account_screen.dart';

class AddAccountCard extends StatelessWidget {
  final VoidCallback onRefreshAccounts; // 계좌 목록 갱신 콜백

  const AddAccountCard({super.key, required this.onRefreshAccounts});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // 추가 버튼 타일의 배경색 (연한 파란색)
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.blue.shade200, width: 1), // 테두리 추가
      ),
      margin: const EdgeInsets.all(0), // <--- 이 부분을 추가하여 마진을 0으로 설정합니다.
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAccountScreen()),
          );
          if (result == true && context.mounted) {
            // mounted 체크 추가
            onRefreshAccounts(); // 새 계좌 추가 후 계좌 목록 갱신
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
                '새 계좌 추가',
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
