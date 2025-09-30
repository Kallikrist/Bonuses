import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/sales_target.dart';
import '../models/user.dart';
import '../models/workplace.dart';

class ImportTargetsScreen extends StatefulWidget {
  const ImportTargetsScreen({super.key});

  @override
  State<ImportTargetsScreen> createState() => _ImportTargetsScreenState();
}

class _ImportTargetsScreenState extends State<ImportTargetsScreen> {
  List<Map<String, dynamic>> _previewData = [];
  bool _isLoading = false;
  String? _fileName;
  List<String>? _workplaceNames;
  Map<String, String> _workplaceMapping = {}; // Maps file workplace names to IDs
  User? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Targets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, child) {
          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInstructionsCard(),
                      const SizedBox(height: 24),
                      _buildFilePickerButton(),
                      if (_fileName != null) ...[
                        const SizedBox(height: 16),
                        _buildFileInfoCard(),
                      ],
                      if (_workplaceNames != null && _workplaceNames!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildWorkplaceMappingSection(app),
                      ],
                      if (_workplaceNames != null) ...[
                        const SizedBox(height: 24),
                        _buildEmployeeSelection(app),
                      ],
                      if (_previewData.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildPreviewSection(),
                        const SizedBox(height: 24),
                        _buildImportButton(app),
                      ],
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'File Format Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your Excel/CSV file should be formatted as follows:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildInstruction('1', 'First row: Workplace names as column headers'),
            _buildInstruction('2', 'First column: Dates (DD.MM.YYYY format)'),
            _buildInstruction('3', 'Other cells: Target amounts for each location/date'),
            const SizedBox(height: 12),
            const Text(
              'Example:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Date          | Skeifan    | Smáralind  | Kringla\n'
                '1.7.2025  | 1106616 | 1349830 | 1349830\n'
                '2.7.2025  | 1240191 | 1698047 | 1698047',
                style: TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildFilePickerButton() {
    return ElevatedButton.icon(
      onPressed: _pickFile,
      icon: const Icon(Icons.upload_file),
      label: const Text('Select Excel or CSV File'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildFileInfoCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File Selected',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_fileName ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkplaceMappingSection(AppProvider app) {
    final existingWorkplaces = app.workplaces;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Workplaces',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Match the workplace names from your file to existing workplaces or create new ones:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...(_workplaceNames ?? []).map((name) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Workplace',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              value: _workplaceMapping[name],
                              items: existingWorkplaces.map((workplace) {
                                return DropdownMenuItem(
                                  value: workplace.id,
                                  child: Text(workplace.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _workplaceMapping[name] = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            tooltip: 'Create New Workplace',
                            onPressed: () => _showCreateWorkplaceDialog(app, name),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelection(AppProvider app) {
    return FutureBuilder<List<User>>(
      future: app.getUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final employees = snapshot.data!.where((u) => u.role == UserRole.employee).toList();
        employees.add(app.currentUser!); // Add admin as well

        return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Employee (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Optionally select an employee to assign all imported targets to. Leave empty for unassigned targets.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<User?>(
              decoration: const InputDecoration(
                labelText: 'Select Employee (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Leave empty for unassigned',
              ),
              value: _selectedEmployee,
              items: [
                const DropdownMenuItem<User?>(
                  value: null,
                  child: Text('None (Unassigned)'),
                ),
                ...employees.map((employee) {
                  return DropdownMenuItem<User?>(
                    value: employee,
                    child: Text(employee.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedEmployee = value;
                });
              },
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview (${_previewData.length} targets)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _previewData.take(10).length,
                itemBuilder: (context, index) {
                  final item = _previewData[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(item['workplace'] ?? 'Unknown'),
                    subtitle: Text(
                      'Date: ${item['date']}\nTarget: ${item['amount']}',
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            ),
            if (_previewData.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Showing first 10 of ${_previewData.length} targets',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton(AppProvider app) {
    final bool canImport = _workplaceMapping.length == (_workplaceNames?.length ?? 0) &&
        _workplaceMapping.values.every((id) => id.isNotEmpty);

    return ElevatedButton.icon(
      onPressed: canImport ? () => _importTargets(app) : null,
      icon: const Icon(Icons.cloud_upload),
      label: Text('Import ${_previewData.length} Targets'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
          _fileName = result.files.single.name;
        });

        final file = File(result.files.single.path!);
        final extension = result.files.single.extension;

        if (extension == 'csv') {
          await _parseCSV(file);
        } else {
          await _parseExcel(file);
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _parseExcel(File file) async {
    try {
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.isEmpty) {
        throw Exception('File is empty');
      }

      // First row contains workplace names
      final headerRow = rows[0];
      final workplaceNames = headerRow
          .skip(1) // Skip first column (dates)
          .where((cell) => cell != null && cell.value != null)
          .map((cell) => cell!.value.toString())
          .toList();

      final previewData = <Map<String, dynamic>>[];

      // Process data rows
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        // First cell is the date
        final dateCell = row[0];
        if (dateCell == null || dateCell.value == null) continue;

        DateTime? date = _parseDate(dateCell.value.toString());
        if (date == null) continue;

        // Process each workplace column
        for (int j = 1; j < row.length && j <= workplaceNames.length; j++) {
          final amountCell = row[j];
          if (amountCell == null || amountCell.value == null) continue;

          final amount = _parseAmount(amountCell.value.toString());
          if (amount == null || amount == 0) continue;

          previewData.add({
            'date': DateFormat('dd.MM.yyyy').format(date),
            'dateTime': date,
            'workplace': workplaceNames[j - 1],
            'amount': amount.toStringAsFixed(0),
            'amountValue': amount,
          });
        }
      }

      setState(() {
        _workplaceNames = workplaceNames;
        _previewData = previewData;
        // Auto-match workplaces by name similarity
        _autoMatchWorkplaces();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing Excel: $e')),
        );
      }
    }
  }

  Future<void> _parseCSV(File file) async {
    try {
      final input = file.readAsStringSync();
      final rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty) {
        throw Exception('File is empty');
      }

      // First row contains workplace names
      final headerRow = rows[0];
      final workplaceNames = headerRow
          .skip(1) // Skip first column (dates)
          .where((cell) => cell != null && cell.toString().isNotEmpty)
          .map((cell) => cell.toString())
          .toList();

      final previewData = <Map<String, dynamic>>[];

      // Process data rows
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        // First cell is the date
        DateTime? date = _parseDate(row[0].toString());
        if (date == null) continue;

        // Process each workplace column
        for (int j = 1; j < row.length && j <= workplaceNames.length; j++) {
          final amount = _parseAmount(row[j].toString());
          if (amount == null || amount == 0) continue;

          previewData.add({
            'date': DateFormat('dd.MM.yyyy').format(date),
            'dateTime': date,
            'workplace': workplaceNames[j - 1],
            'amount': amount.toStringAsFixed(0),
            'amountValue': amount,
          });
        }
      }

      setState(() {
        _workplaceNames = workplaceNames;
        _previewData = previewData;
        // Auto-match workplaces by name similarity
        _autoMatchWorkplaces();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing CSV: $e')),
        );
      }
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Try DD.MM.YYYY format
      if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      
      // Try other formats
      return DateFormat('dd.MM.yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  double? _parseAmount(String amountStr) {
    try {
      // Remove any spaces, commas, or other non-numeric characters except decimal point
      final cleaned = amountStr.replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  void _autoMatchWorkplaces() {
    final app = Provider.of<AppProvider>(context, listen: false);
    final existingWorkplaces = app.workplaces;

    for (final name in _workplaceNames ?? []) {
      // Try to find exact match first
      var match = existingWorkplaces.firstWhere(
        (w) => w.name.toLowerCase() == name.toLowerCase(),
        orElse: () => existingWorkplaces.first,
      );

      _workplaceMapping[name] = match.id;
    }
  }

  Future<void> _showCreateWorkplaceDialog(AppProvider app, String suggestedName) async {
    final nameController = TextEditingController(text: suggestedName);
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Workplace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Workplace Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a workplace name')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final newWorkplace = Workplace(
        id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        address: addressController.text.trim().isEmpty ? '' : addressController.text.trim(),
        createdAt: DateTime.now(),
      );

      await app.addWorkplace(newWorkplace);
      
      setState(() {
        _workplaceMapping[suggestedName] = newWorkplace.id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created workplace: ${newWorkplace.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _importTargets(AppProvider app) async {
    setState(() {
      _isLoading = true;
    });

    try {
      int imported = 0;
      
      for (final data in _previewData) {
        final workplaceName = data['workplace'];
        final workplaceId = _workplaceMapping[workplaceName];
        
        if (workplaceId == null) continue;

        final target = SalesTarget(
          id: 'imported_${DateTime.now().millisecondsSinceEpoch}_$imported',
          date: data['dateTime'],
          targetAmount: data['amountValue'],
          actualAmount: 0.0,
          isMet: false,
          status: TargetStatus.pending,
          createdAt: DateTime.now(),
          createdBy: app.currentUser!.id,
          assignedEmployeeId: _selectedEmployee?.id,
          assignedEmployeeName: _selectedEmployee?.name,
          assignedWorkplaceId: workplaceId,
          assignedWorkplaceName: workplaceName,
          collaborativeEmployeeIds: [],
          collaborativeEmployeeNames: [],
        );

        await app.addSalesTarget(target);
        imported++;
      }

      // Force a reload of data to ensure UI updates
      await app.initialize();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $imported targets'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing targets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
