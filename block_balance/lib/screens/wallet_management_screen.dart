import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../services/database_helper.dart';
import '../services/csv_service.dart';
import '../services/log_service.dart';

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({super.key});
  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CsvService _csvService = CsvService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();

  String _selectedNetwork = 'ETHEREUM';
  String? _selectedFilePath;
  int? _selectedWalletId;
  List<Map<String, dynamic>> _wallets = [];

  @override
  void initState() {
    super.initState();
    _refreshWallets();
  }

  Future<void> _refreshWallets() async {
    final data = await _dbHelper.getAllWallets();
    setState(() {
      _wallets = data;
      if (_wallets.isNotEmpty && _selectedWalletId == null)
        _selectedWalletId = _wallets.first['id'];
    });
  }

  // 1. 지갑 등록 (한 줄)
  Widget _buildWalletInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. 새 지갑 등록',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: DropdownButtonFormField<String>(
                value: _selectedNetwork,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                  border: OutlineInputBorder(),
                ),
                items: ['ETHEREUM', 'POLYGON']
                    .map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text(n, style: const TextStyle(fontSize: 9)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedNetwork = v!),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Address',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: TextField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  hintText: 'Alias',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
            const SizedBox(width: 5),
            ElevatedButton(onPressed: _addWallet, child: const Text('등록')),
          ],
        ),
      ],
    );
  }

  Future<void> _addWallet() async {
    if (_addressController.text.isEmpty) return;
    final db = await _dbHelper.database;
    db.execute(
      'INSERT INTO wallets (address, network, alias) VALUES (?, ?, ?)',
      [
        _addressController.text.trim(),
        _selectedNetwork,
        _aliasController.text.trim(),
      ],
    );
    _addressController.clear();
    _aliasController.clear();
    _refreshWallets();
    LogService().addLog('✅ 지갑 등록 완료');
  }

  // 2. CSV 임포트 (한 줄 UI)
  Widget _buildCsvSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. 데이터 임포트',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedWalletId,
          decoration: const InputDecoration(
            labelText: '대상 지갑',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
          ),
          items: _wallets
              .map(
                (w) => DropdownMenuItem<int>(
                  value: w['id'],
                  child: Text(
                    "${w['alias']} (${w['network']})",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedWalletId = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_present, size: 16),
                label: Text(
                  _selectedFilePath == null
                      ? '파일 선택'
                      : p.basename(_selectedFilePath!),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _importCsv,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              child: const Text('실행'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null)
      setState(() => _selectedFilePath = result.files.single.path);
  }

  Future<void> _importCsv() async {
    if (_selectedWalletId == null || _selectedFilePath == null) return;
    final wallet = await _dbHelper.getWalletById(_selectedWalletId!);
    if (wallet == null) return;
    await _csvService.importCsv(
      _selectedFilePath!,
      _selectedWalletId!,
      wallet['network'],
    );
    setState(() => _selectedFilePath = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('데이터 관리')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWalletInputSection(),
                  const Divider(height: 30),
                  _buildCsvSection(),
                  const SizedBox(height: 20),
                  const Text(
                    '3. 지갑 목록',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ..._wallets.map(
                    (w) => Card(
                      child: ListTile(
                        title: Text(w['alias'] ?? ''),
                        subtitle: Text(
                          w['address'],
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildLogConsole(),
        ],
      ),
    );
  }

  Widget _buildLogConsole() {
    return Container(
      height: 150,
      color: Colors.grey[200],
      child: Column(
        children: [
          Container(
            color: Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "LOGS",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => LogService().clearLogs(),
                  child: const Icon(Icons.delete_sweep, size: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: LogService(),
              builder: (context, _) {
                final logs = LogService().logs;
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: logs.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SelectableText(
                      // <-- 이 부분을 수정
                      logs[i],
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                      // 길게 누르면 전체 선택 등의 기능 제공
                      cursorColor: Colors.blue,
                      showCursor: false,
                    ),
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
