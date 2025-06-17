// lib/widgets/account_card.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/screens/account_detail_screen.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onDelete; // 삭제 콜백
  final VoidCallback onRefreshAccounts; // 계좌 목록 갱신 콜백

  const AccountCard({
    super.key,
    required this.account,
    required this.onDelete,
    required this.onRefreshAccounts,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountDetailScreen(account: account),
          ),
        );
        if (result == true) {
          onRefreshAccounts(); // 상세 화면에서 돌아왔을 때 계좌 목록 갱신
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
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
                    account.description != null &&
                            account.description!.isNotEmpty
                        ? account.description!
                        : '설명 없음',
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
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('계좌 삭제'),
                      content: Text(
                        '${account.name} 계좌를 정말 삭제하시겠습니까? 관련 자산 및 스냅샷 정보도 모두 삭제됩니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            onDelete(); // 외부에서 전달받은 삭제 콜백 실행
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
      ),
    );
  }
}
