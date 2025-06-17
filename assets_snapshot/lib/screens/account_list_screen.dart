import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/account.dart';

// 분리한 위젯 임포트
import 'package:assets_snapshot/widgets/account_card.dart';
import 'package:assets_snapshot/widgets/add_account_card.dart';

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

    if (!mounted) return;

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
        actions: const [], // AppBar의 "+" 버튼은 제거되었으므로 비워둡니다.
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else {
            final List<Account> accounts = snapshot.data ?? [];
            final int itemCount = accounts.length + 1;

            return GridView.builder(
              padding: const EdgeInsets.all(2.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 1.0,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index < accounts.length) {
                  // 기존 계좌 타일은 AccountCard 위젯 사용
                  final account = accounts[index];
                  return AccountCard(
                    account: account,
                    onDelete: () => _deleteAccount(account.id!), // 삭제 콜백 연결
                    onRefreshAccounts: _loadAccounts, // 계좌 목록 갱신 콜백 연결
                  );
                } else {
                  // "새 계좌 추가" 타일은 AddAccountCard 위젯 사용
                  return AddAccountCard(
                    onRefreshAccounts: _loadAccounts, // 계좌 목록 갱신 콜백 연결
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
