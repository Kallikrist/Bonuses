import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';
import 'employee_profile_screen.dart';
import 'import_employees_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  final AppProvider appProvider;
  final String?
      filterCompanyId; // Optional: filter to show only employees from this company
  final String? customTitle; // Optional: custom title for the screen
  final bool readOnly; // Optional: if true, hide add/import/delete buttons

  const EmployeesListScreen({
    super.key,
    required this.appProvider,
    this.filterCompanyId,
    this.customTitle,
    this.readOnly = false,
  });

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  Set<String> _selectedEmployeeIds = <String>{};
  bool _isSelectionMode = false;
  List<String> _allEmployeeIds = [];
  String? _filterRole; // Filter by role (admin/employee)
  String _searchQuery = ''; // Search by name
  final TextEditingController _searchController = TextEditingController();

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEmployeeIds.clear();
      }
    });
  }

  void _selectAllEmployees() {
    setState(() {
      _selectedEmployeeIds = _allEmployeeIds.toSet();
      // Exclude current admin if they exist
      final currentUserId = widget.appProvider.currentUser?.id;
      if (currentUserId != null) {
        _selectedEmployeeIds.remove(currentUserId);
      }
    });
  }

  void _deselectAllEmployees() {
    setState(() {
      _selectedEmployeeIds.clear();
    });
  }

  void _toggleSelectAll() {
    if (_selectedEmployeeIds.length == _allEmployeeIds.length &&
        _allEmployeeIds.isNotEmpty) {
      _deselectAllEmployees();
    } else {
      _selectAllEmployees();
    }
  }

  void _toggleEmployeeSelection(String employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
  }

  void _showDeleteSelectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Employees'),
        content: Text(
          'Are you sure you want to delete ${_selectedEmployeeIds.length} selected employees? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final selectedCount = _selectedEmployeeIds.length;

              try {
                // Delete selected employees
                for (String employeeId in List.from(_selectedEmployeeIds)) {
                  await widget.appProvider.deleteUser(employeeId);
                }

                Navigator.pop(context);
                _toggleSelectionMode(); // Exit selection mode

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('$selectedCount employees deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting employees: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // Initialize with admin's current company
        String? selectedCompanyId =
            widget.appProvider.currentUser?.primaryCompanyId;

        return StatefulBuilder(
          builder: (context, setState) => FutureBuilder<List<Company>>(
            future: widget.appProvider.getCompanies(),
            builder: (context, snapshot) {
              final allCompanies = snapshot.data ?? [];
              final currentUser = widget.appProvider.currentUser;

              // Filter companies to only show those where the current user is a member
              final companies = allCompanies.where((company) {
                return currentUser != null &&
                    currentUser.companyIds.contains(company.id);
              }).toList();

              // Validate selectedCompanyId is in the filtered list
              if (selectedCompanyId != null &&
                  !companies.any((c) => c.id == selectedCompanyId)) {
                selectedCompanyId = null;
              }

              return AlertDialog(
                title: const Text('Add Employee'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      TextField(
                        controller: passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      // Replaced dropdown with informational card that uses admin's current company
                      Builder(builder: (context) {
                        final currentCompanyId =
                            widget.appProvider.currentUser?.primaryCompanyId;
                        final company = companies.firstWhere(
                          (c) => c.id == currentCompanyId,
                          orElse: () => Company(
                            id: '',
                            name: 'Unknown Company',
                            address: '',
                            createdAt: DateTime.now(),
                            adminUserId: '',
                          ),
                        );
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business,
                                  color: Colors.blue.shade700, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Will be added to:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      company.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
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
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty &&
                          emailController.text.isNotEmpty &&
                          phoneController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        final currentCompanyId =
                            widget.appProvider.currentUser?.primaryCompanyId;
                        final selectedCompany = companies.firstWhere(
                          (c) => c.id == currentCompanyId,
                          orElse: () => Company(
                            id: '',
                            name: 'Unknown Company',
                            address: '',
                            createdAt: DateTime.now(),
                            adminUserId: '',
                          ),
                        );

                        final companyIds = currentCompanyId != null
                            ? [currentCompanyId]
                            : <String>[];
                        final companyNames = currentCompanyId != null
                            ? [selectedCompany.name]
                            : <String>[];

                        final user = User(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          email: emailController.text,
                          phoneNumber: phoneController.text,
                          role: UserRole.employee,
                          createdAt: DateTime.now(),
                          totalPoints: 0,
                          companyIds: companyIds,
                          companyNames: companyNames,
                          primaryCompanyId: currentCompanyId,
                        );
                        await widget.appProvider.addUser(user);

                        // Save password for the new user
                        await StorageService.savePassword(
                            user.id, 'password123');
                        print(
                            'DEBUG: Saved password for new user ${user.email}');

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Employee added successfully' +
                                (selectedCompany != null
                                    ? ' to ${selectedCompany.name}'
                                    : '') +
                                '. Default password: password123'),
                          ),
                        );
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showRoleFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('All Roles'),
              value: null,
              groupValue: _filterRole,
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            RadioListTile<String?>(
              title: const Text('Admins Only'),
              value: 'admin',
              groupValue: _filterRole,
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String?>(
              title: const Text('Employees Only'),
              value: 'employee',
              groupValue: _filterRole,
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customTitle ?? 'Employees List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Show role filter icon when not in selection mode
          if (!_isSelectionMode)
            IconButton(
              icon: Icon(
                _filterRole != null ? Icons.filter_alt : Icons.filter_list,
              ),
              onPressed: _showRoleFilterDialog,
              tooltip: 'Filter by Role',
            ),
          // Hide selection mode toggle when in read-only mode
          if (!widget.readOnly)
            _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Cancel Selection',
                  )
                : IconButton(
                    icon: const Icon(Icons.checklist),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Select Employees',
                  ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // Force fresh data each time Consumer rebuilds
          return FutureBuilder<List<User>>(
            key: ValueKey(provider
                .pointsTransactions.length), // Changes when points update
            future: provider.getUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var employees = snapshot.data!
                  .where((u) =>
                      u.role == UserRole.employee || u.role == UserRole.admin)
                  .toList();

              // Always filter by current company
              final activeCompanyFilter = widget.filterCompanyId ??
                  provider.currentUser?.primaryCompanyId;

              if (activeCompanyFilter != null) {
                employees = employees
                    .where((u) => u.companyIds.contains(activeCompanyFilter))
                    .toList();
              }

              // Filter by role if role filter is active
              if (_filterRole != null) {
                final targetRole =
                    _filterRole == 'admin' ? UserRole.admin : UserRole.employee;
                employees = employees
                    .where((u) =>
                        u.getRoleForCompany(activeCompanyFilter) == targetRole)
                    .toList();
              }

              // Filter by search query
              if (_searchQuery.isNotEmpty) {
                employees = employees
                    .where((u) =>
                        u.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        u.email
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              // Update employee IDs for selection
              final currentUserId = widget.appProvider.currentUser?.id;
              _allEmployeeIds = employees
                  .where((e) => e.id != currentUserId)
                  .map((e) => e.id)
                  .toList();

              return Column(
                children: [
                  // Search bar
                  if (!_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  // Select All and selection count bar
                  if (_isSelectionMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Colors.blue.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _toggleSelectAll,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              (_selectedEmployeeIds.length ==
                                          _allEmployeeIds.length &&
                                      _allEmployeeIds.isNotEmpty)
                                  ? 'Deselect All'
                                  : 'Select All',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${_selectedEmployeeIds.length} Selected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Employee list
                  Expanded(
                    child: ListView.builder(
                      padding: _isSelectionMode
                          ? const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8)
                          : const EdgeInsets.all(16),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        // Get company-specific points based on active filter
                        final displayCompanyId = activeCompanyFilter ??
                            provider.currentUser?.primaryCompanyId;
                        final userPoints = displayCompanyId != null
                            ? provider.getUserCompanyPoints(
                                employee.id, displayCompanyId)
                            : 0;
                        final isSelected =
                            _selectedEmployeeIds.contains(employee.id);
                        final isCurrentUser =
                            widget.appProvider.currentUser?.id == employee.id;

                        return Card(
                          color:
                              isSelected ? Colors.blue.shade50 : Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () {
                              if (_isSelectionMode && !isCurrentUser) {
                                _toggleEmployeeSelection(employee.id);
                              } else if (!_isSelectionMode) {
                                // Navigate to employee profile/detail view
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmployeeProfileScreen(
                                      employee: employee,
                                      appProvider: provider,
                                      companyContext:
                                          displayCompanyId, // Pass the company context
                                      readOnly: widget
                                          .readOnly, // Pass read-only mode from parent
                                    ),
                                  ),
                                );
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: employee.role == UserRole.admin
                                  ? Colors.purple
                                  : Colors.blue,
                              child: Text(
                                employee.name.isNotEmpty
                                    ? employee.name[0].toUpperCase()
                                    : 'E',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              employee.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(employee.email),
                                Text(
                                  employee.role == UserRole.admin
                                      ? 'Admin • $userPoints points'
                                      : '$userPoints points',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.blue.shade600
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: _isSelectionMode && !isCurrentUser
                                ? ElevatedButton(
                                    onPressed: () =>
                                        _toggleEmployeeSelection(employee.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      foregroundColor: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      minimumSize: const Size(40, 32),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    child: Text(
                                      isSelected ? 'Selected' : 'Select',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )
                                : _isSelectionMode && isCurrentUser
                                    ? Container(
                                        width: 40,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.lock,
                                              size: 16, color: Colors.grey),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            employee.role == UserRole.admin
                                                ? Icons.admin_panel_settings
                                                : Icons.person,
                                            color:
                                                employee.role == UserRole.admin
                                                    ? Colors.purple
                                                    : Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: widget.readOnly
          ? null
          : _isSelectionMode
              ? (_selectedEmployeeIds.isNotEmpty
                  ? FloatingActionButton(
                      onPressed: _showDeleteSelectedDialog,
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.delete),
                    )
                  : null)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImportEmployeesScreen(
                              appProvider: widget.appProvider,
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      heroTag: 'import_employees',
                      child: const Icon(Icons.upload_file),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      onPressed: _showAddEmployeeDialog,
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      heroTag: 'add_employee',
                      child: const Icon(Icons.person_add),
                    ),
                  ],
                ),
    );
  }
}
