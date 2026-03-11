// lib/ui/screens/asset_list_screen.dart
import 'package:asset_tracker/ui/screens/account_list_screen.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/asset_model.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  List<Institution> _institutions = [];

  @override
  void initState() {
    super.initState();
    _refreshInstitutions();
  }

  // 데이터 새로고침
  Future<void> _refreshInstitutions() async {
    final data = await DatabaseService.getAllInstitutions();
    setState(() {
      _institutions = data;
    });
  }

  // 추가 팝업 띄우기
  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('금융기관 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '예: 신한은행, 삼성증권'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await DatabaseService.addInstitution(name);

                // 중요: 비동기 작업 이후 context 상태 확인
                if (!context.mounted) return;

                Navigator.pop(context); // 다이얼로그 닫기
                _refreshInstitutions(); // 부모 위젯의 목록 새로고침
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _institutions.isEmpty
          ? const Center(child: Text('등록된 금융기관이 없습니다.'))
          : ListView.builder(
              itemCount: _institutions.length,
              itemBuilder: (context, index) {
                final item = _institutions[index];
                return ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: Text(item.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AccountListScreen(institution: item),
                      ),
                    ).then((_) => _refreshInstitutions()); // 돌아왔을 때 갱신 (선택사항)
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('금융기관 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
