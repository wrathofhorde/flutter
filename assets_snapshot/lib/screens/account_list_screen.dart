// lib/screens/account_list_screen.dart

import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/screens/add_account_screen.dart';
import 'package:provider/provider.dart'; // Provider 패키지 임포트
import 'package:assets_snapshot/providers/theme_provider.dart'; // ThemeProvider 임포트

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
    await _dbHelper.deleteAccount(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('계좌가 삭제되었습니다.')));
    _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider 인스턴스에 접근
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 계좌 목록'),
        actions: [
          // 테마 토글 스위치 추가
          Switch(
            value: themeProvider.themeMode == ThemeMode.dark, // 현재 다크 모드인지 여부
            onChanged: (isDark) {
              themeProvider.setThemeMode(
                isDark ? ThemeMode.dark : ThemeMode.light,
              );
            },
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.nightlight_round); // 다크 모드 아이콘
              }
              return const Icon(Icons.wb_sunny_rounded); // 라이트 모드 아이콘
            }),
            activeColor: Colors.blueGrey, // 스위치 활성화 시 색상
            inactiveThumbColor: Colors.yellow, // 비활성화 시 엄지 색상
            inactiveTrackColor: Colors.yellow.shade200, // 비활성화 시 트랙 색상
          ),
          IconButton(
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(account.description ?? '설명 없음'),
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
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${account.name} 상세 정보 보기 (아직 미구현)'),
                        ),
                      );
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
