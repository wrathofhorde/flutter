import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/screens/add_account_screen.dart';
// import 'package:provider/provider.dart'; // Provider 패키지 임포트 제거
// import 'package:assets_snapshot/providers/theme_provider.dart'; // ThemeProvider 임포트 제거
import 'package:intl/intl.dart';

import 'package:assets_snapshot/screens/account_detail_screen.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  late Future<List<Account>> _accountsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      _accountsFuture = _dbHelper.getAccounts();
    });
  }

  void _deleteAccount(int id) async {
    await _dbHelper.deleteAllAssetsByAccountId(id);
    await _dbHelper.deleteAccount(id);

    if (!mounted) return; // BuildContext 경고 방지

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('계좌가 삭제되었습니다.')));
    _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 계좌 목록'),
        actions: [
          IconButton(
            tooltip: "계좌 추가",
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAccountScreen(),
                ),
              );
              if (result == true) {
                _loadAccounts();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('아직 등록된 계좌가 없습니다. 새 계좌를 추가해주세요!'));
          } else {
            final List<Account> accounts = snapshot.data!;
            return ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // 명시적으로 검은색 지정 유지
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.description != null &&
                                  account.description!.isNotEmpty
                              ? account.description!
                              : '설명 없음',
                          style: const TextStyle(
                            color: Colors.black87,
                          ), // 명시적으로 검은색 지정 유지
                        ),
                        Text(
                          '생성일: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(account.createdAt))}',
                          style: const TextStyle(
                            color: Colors.black54,
                          ), // 명시적으로 검은색 지정 유지
                        ),
                        Text(
                          '최근 업데이트: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(account.updatedAt))}',
                          style: const TextStyle(
                            color: Colors.black54,
                          ), // 명시적으로 검은색 지정 유지
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
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
                                  _deleteAccount(account.id!);
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
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AccountDetailScreen(account: account),
                        ),
                      );
                      if (result == true) {
                        _loadAccounts();
                      }
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
