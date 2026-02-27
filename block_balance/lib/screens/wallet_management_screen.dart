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

  int? _importWalletId;
  String? _importPath;

  // 로딩 상태 관리를 위한 변수
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽: 작업 로그 (60% 비중)
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("작업 로그"),
                        Expanded(child: _buildLogConsole()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 오른쪽: 등록된 지갑 리스트 (40% 비중)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("등록된 지갑 목록"),
                        Expanded(child: _buildWalletList()),
                      ],
                    ),
                  ),
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
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  // 1. 지갑 등록 카드
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
                decoration: const InputDecoration(
                  labelText: "Network",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'ETHEREUM', child: Text("ETHEREUM")),
                  DropdownMenuItem(value: 'POLYGON', child: Text("POLYGON")),
                ],
                onChanged: (v) => setState(() => _selectedNetwork = v!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  labelText: "Alias",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _registerWallet,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text("등록"),
            ),
          ],
        ),
      ),
    );
  }

  // 2. 임포트 카드 (로딩 인디케이터 적용됨)
  Widget _buildImportCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _dbHelper.getAllWallets(),
                builder: (context, snapshot) {
                  final wallets = snapshot.data ?? [];
                  return DropdownButtonFormField<int>(
                    value: _importWalletId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "대상 지갑 선택",
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                      isDense: true,
                    ),
                    items: wallets
                        .map(
                          (w) => DropdownMenuItem<int>(
                            value: w['id'],
                            child: Text(
                              "${w['alias'] ?? '이름없음'} (${w['network']})",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _importWalletId = v),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickFile, // 로딩 중 파일 선택 금지
              icon: const Icon(Icons.file_open, size: 18),
              label: Text(_importPath == null ? "파일 선택" : "선택됨"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(130, 50),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isImporting ? null : _runImport, // 로딩 중 중복 클릭 방지
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 50),
              ),
              child: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("임포트 실행"),
            ),
          ],
        ),
      ),
    );
  }

  // 3. 작업 로그 콘솔
  Widget _buildLogConsole() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListenableBuilder(
        listenable: LogService(),
        builder: (context, _) {
          final logs = LogService().logs;
          return SelectionArea(
            child: ListView.builder(
              reverse: false,
              itemCount: logs.length,
              itemBuilder: (context, i) {
                Color textColor = Colors.blueGrey[800]!;
                if (logs[i].contains("✅")) textColor = Colors.indigo[700]!;
                if (logs[i].contains("❌") || logs[i].contains("⚠️")) {
                  textColor = Colors.redAccent[700]!;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    logs[i],
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'Malgun Gothic',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 4. 등록된 지갑 리스트
  Widget _buildWalletList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbHelper.getAllWallets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("등록된 지갑이 없습니다."));
        }
        final wallets = snapshot.data!;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            itemCount: wallets.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final w = wallets[i];
              return ListTile(
                dense: true,
                title: Text(
                  w['alias'] ?? '이름없음',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${w['network']} | ${w['address'].toString().substring(0, 10)}...",
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: _isImporting
                      ? null
                      : () => _deleteWallet(w['id']), // 로딩 중 삭제 금지
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- 기능 함수들 ---
  void _registerWallet() async {
    if (_addressController.text.isEmpty) return;
    await _dbHelper.insertWallet(
      _addressController.text,
      _selectedNetwork,
      _aliasController.text,
    );
    _addressController.clear();
    _aliasController.clear();
    setState(() {});
    LogService().addLog("✅ 새 지갑 등록 완료");
  }

  void _deleteWallet(int id) async {
    await _dbHelper.deleteWallet(id);
    setState(() {});
    LogService().addLog("🗑️ 지갑 삭제 완료 (ID: $id)");
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) setState(() => _importPath = result.files.single.path);
  }

  void _runImport() async {
    if (_importWalletId == null || _importPath == null) {
      LogService().addLog("❌ 지갑과 파일을 먼저 선택해주세요.");
      return;
    }

    setState(() => _isImporting = true); // 로딩 시작

    try {
      final wallet = await _dbHelper.getWalletById(_importWalletId!);
      if (wallet != null) {
        await _csvService.importCsv(
          _importPath!,
          _importWalletId!,
          wallet['network'],
        );
        setState(() => _importPath = null);
      }
    } catch (e) {
      LogService().addLog("❌ 임포트 실패: $e");
    } finally {
      setState(() => _isImporting = false); // 로딩 종료
    }
  }
}
