import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:csv/csv.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../models/points_transaction.dart';

class ImportEmployeesScreen extends StatefulWidget {
  final AppProvider appProvider;

  const ImportEmployeesScreen({
    super.key,
    required this.appProvider,
  });

  @override
  State<ImportEmployeesScreen> createState() => _ImportEmployeesScreenState();
}

class _ImportEmployeesScreenState extends State<ImportEmployeesScreen> {
  String? _filePath;
  String? _fileName;
  List<Map<String, dynamic>> _previewData = [];
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
          _isLoading = true;
        });

        await _parseFile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _parseFile() async {
    if (_filePath == null) return;

    try {
      final file = File(_filePath!);
      final bytes = await file.readAsBytes();

      List<List<dynamic>> rows = [];

      if (_fileName!.endsWith('.csv')) {
        // Parse CSV
        final csvString = String.fromCharCodes(bytes);
        rows = const CsvToListConverter().convert(csvString);
      } else {
        // Parse Excel
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first];

        if (sheet != null) {
          rows = sheet.rows
              .map((row) => row.map((cell) => cell?.value).toList())
              .toList();
        }
      }

      if (rows.isEmpty) {
        throw Exception('File is empty');
      }

      // Parse employee data
      // Expected format: Name | Email | Phone number | current points
      final employeeData = <Map<String, dynamic>>[];

      // Skip header row (index 0)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.length < 4) continue; // Skip incomplete rows

        final name = row[0]?.toString().trim() ?? '';
        final email = row[1]?.toString().trim() ?? '';
        final phone = row[2]?.toString().trim() ?? '';
        final pointsStr = row[3]?.toString().trim() ?? '0';

        if (name.isEmpty || email.isEmpty)
          continue; // Skip rows without name or email

        // Parse points
        int points = 0;
        try {
          points = int.parse(pointsStr.replaceAll(RegExp(r'[^0-9]'), ''));
        } catch (e) {
          points = 0;
        }

        employeeData.add({
          'name': name,
          'email': email,
          'phone': phone,
          'points': points,
        });
      }

      setState(() {
        _previewData = employeeData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error parsing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      int imported = 0;
      int skipped = 0;

      final existingUsers = await widget.appProvider.getUsers();
      final existingEmails =
          existingUsers.map((u) => u.email.toLowerCase()).toSet();

      for (final data in _previewData) {
        final email = data['email'] as String;

        // Check if user with this email already exists
        if (existingEmails.contains(email.toLowerCase())) {
          skipped++;
          continue;
        }

        // Create new employee
        final newEmployee = User(
          id: 'emp_${DateTime.now().millisecondsSinceEpoch}_$imported',
          name: data['name'],
          email: email,
          phoneNumber: data['phone'],
          role: UserRole.employee,
          createdAt: DateTime.now(),
        );

        await widget.appProvider.addUser(newEmployee);

        // Add initial points if any
        final points = data['points'] as int;
        if (points > 0) {
          final transaction = PointsTransaction(
            id: 'import_points_${DateTime.now().millisecondsSinceEpoch}_$imported',
            userId: newEmployee.id,
            type: PointsTransactionType.earned,
            points: points,
            description: 'Initial points from import',
            date: DateTime.now(),
          );

          await widget.appProvider.addPointsTransaction(transaction);
        }

        imported++;
      }

      // Force a reload of data to ensure UI updates
      await widget.appProvider.initialize();

      if (mounted) {
        Navigator.pop(context);

        String message =
            'Successfully imported $imported employee${imported != 1 ? 's' : ''}';
        if (skipped > 0) {
          message += ' ($skipped skipped - email already exists)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing employees: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Employees'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'File Format Instructions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Excel or CSV file should have the following columns in order:',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          _buildFormatItem(
                              'Column A', 'Name', 'Employee full name'),
                          _buildFormatItem('Column B', 'Email',
                              'Email address (must be unique)'),
                          _buildFormatItem('Column C', 'Phone number',
                              'Contact phone number'),
                          _buildFormatItem('Column D', 'current points',
                              'Initial points balance'),
                          const SizedBox(height: 12),
                          Text(
                            '• First row should contain headers\n'
                            '• Employees with existing emails will be skipped\n'
                            '• Default password will be "changeme123"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // File Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select File',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Select Excel or CSV File'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          if (_fileName != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Selected: $_fileName',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Preview
                  if (_previewData.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_previewData.length} employee${_previewData.length != 1 ? 's' : ''} found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                      Colors.grey[100]),
                                  columns: const [
                                    DataColumn(
                                        label: Text('Name',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Email',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Phone',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Points',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _previewData.take(10).map((employee) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(employee['name'])),
                                        DataCell(Text(employee['email'])),
                                        DataCell(Text(employee['phone'])),
                                        DataCell(
                                          Text(
                                            employee['points'].toString(),
                                            style: TextStyle(
                                              color: employee['points'] > 0
                                                  ? Colors.green
                                                  : Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            if (_previewData.length > 10) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Showing first 10 of ${_previewData.length} employees',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _importEmployees,
                        icon: const Icon(Icons.download),
                        label: Text(
                            'Import ${_previewData.length} Employee${_previewData.length != 1 ? 's' : ''}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFormatItem(String column, String header, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              column,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: header,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' - $description',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
