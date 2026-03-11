import 'package:asset_tracker/ui/screens/asset_item_screen.dart';
import 'package:flutter/material.dart';
import '../../models/asset_model.dart';
import '../../services/database_service.dart';

class AccountListScreen extends StatefulWidget {
  final Institution institution;

  const AccountListScreen({super.key, required this.institution});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  Future<void> _refreshAccounts() async {
    final data = await DatabaseService.getAccountsByInstitution(
      widget.institution.id,
    );
    setState(() => _accounts = data);
  }

  void _showAddAccountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.institution.name} 계좌 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '예: ISA, IRP, 연금저축'),
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
                await DatabaseService.addAccount(widget.institution.id, name);
                if (!context.mounted) return;
                Navigator.pop(context);
                _refreshAccounts();
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
      appBar: AppBar(title: Text('${widget.institution.name} 계좌 목록')),
      body: _accounts.isEmpty
          ? const Center(child: Text('등록된 계좌가 없습니다.'))
          : ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(account.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetItemScreen(account: account),
                      ),
                    ).then((_) => _refreshAccounts());
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountDialog,
        label: const Text('계좌 추가'),
        icon: const Icon(Icons.add_card),
      ),
    );
  }
}
