import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/csv_service.dart';
import '../services/log_service.dart';
import 'package:file_picker/file_picker.dart';

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _csvService = CsvService();

  String _selectedNetwork = 'ETHEREUM';
  final _addressController = TextEditingController();
  final _aliasController = TextEditingController();
  String? _importPath;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("새 지갑 등록"),
            _buildRegistrationCard(),
            const SizedBox(height: 25),
            _buildSectionTitle("데이터 임포트 (CSV)"),
            _buildImportCard(),
            const SizedBox(height: 25),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 6, child: _buildLogConsoleSection()),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildWalletListSection()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildRegistrationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: _selectedNetwork,
                decoration: const InputDecoration(labelText: "Network", border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'ETHEREUM', child: Text("ETHEREUM")),
                  DropdownMenuItem(value: 'POLYGON', child: Text("POLYGON")),
                ],
                onChanged: (v) => setState(() => _selectedNetwork = v!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Address", border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: TextField(controller: _aliasController, decoration: const InputDecoration(labelText: "Alias", border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: _registerWallet, style: ElevatedButton.styleFrom(minimumSize: const Size(80, 50), backgroundColor: Colors.indigo, foregroundColor: Colors.white), child: const Text("등록")),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text("지갑을 따로 선택할 필요가 없습니다.\n파일명 규칙(eth_, pol_, int_ 등)에 따라 자동 분류됩니다.", style: TextStyle(color: Colors.blueGrey, fontSize: 13))),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickFile,
              icon: const Icon(Icons.file_open, size: 18),
              label: Text(_importPath == null ? "CSV 파일 선택" : "파일 선택됨"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 50), backgroundColor: Colors.white),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isImporting ? null : _runImport,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800], foregroundColor: Colors.white, minimumSize: const Size(120, 50)),
              child: _isImporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("임포트 실행"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogConsoleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("작업 로그"),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey[100]!, width: 1.5)),
            padding: const EdgeInsets.all(12),
            child: ListenableBuilder(
              listenable: LogService(),
              builder: (context, _) {
                final logs = LogService().logs;
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, i) => Text(logs[i], style: TextStyle(color: logs[i].contains("✅") ? Colors.indigo : (logs[i].contains("❌") ? Colors.red : Colors.black87), fontSize: 13, height: 1.5)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("등록된 지갑 목록"),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _dbHelper.getAllWallets(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("등록된 지갑이 없습니다."));
              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final w = snapshot.data![i];
                  return ListTile(
                    dense: true,
                    title: Text(w['alias'] ?? '이름없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${w['network']} | ${w['address'].toString().substring(0, 10)}..."),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _deleteWallet(w['id'])),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _registerWallet() async {
    if (_addressController.text.isEmpty) return;
    await _dbHelper.insertWallet(_addressController.text, _selectedNetwork, _aliasController.text);
    _addressController.clear();
    _aliasController.clear();
    setState(() {});
    LogService().addLog("✅ 새 지갑 등록 완료");
  }

  void _deleteWallet(int id) async {
    await _dbHelper.deleteWallet(id);
    setState(() {});
    LogService().addLog("🗑️ 지갑 삭제 완료");
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) setState(() => _importPath = result.files.single.path);
  }

  Future<void> _runImport() async {
    if (_importPath == null) {
      LogService().addLog("❌ 파일을 먼저 선택해주세요.");
      return;
    }

    setState(() => _isImporting = true);
    
    // UI 업데이트를 위한 짧은 지연 (스피너 표시 보장)
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await _csvService.importCsv(_importPath!);
      setState(() => _importPath = null);
    } catch (e) {
      LogService().addLog("❌ 오류 발생: $e");
    } finally {
      setState(() => _isImporting = false);
    }
  }
}