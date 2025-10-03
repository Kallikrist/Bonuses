import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/company.dart';
import '../models/workplace.dart';
import '../models/user.dart';
import 'admin_dashboard.dart'; // For StoreProfileScreen, EmployeeProfileScreen, and EmployeesListScreen

class CompanyProfileScreen extends StatefulWidget {
  final Company company;
  final AppProvider appProvider;

  const CompanyProfileScreen({
    super.key,
    required this.company,
    required this.appProvider,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  late Company _currentCompany;

  @override
  void initState() {
    super.initState();
    _currentCompany = widget.company;
  }

  void _showEditCompanyDialog() {
    final nameController = TextEditingController(text: _currentCompany.name);
    final addressController =
        TextEditingController(text: _currentCompany.address ?? '');
    final emailController =
        TextEditingController(text: _currentCompany.contactEmail ?? '');
    final phoneController =
        TextEditingController(text: _currentCompany.contactPhone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a company name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final updatedCompany = _currentCompany.copyWith(
                name: nameController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                contactEmail: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                contactPhone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
              );

              await widget.appProvider.updateCompany(updatedCompany);

              setState(() {
                _currentCompany = updatedCompany;
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Company updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddWorkplaceDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Workplace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Workplace Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a workplace name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newWorkplace = Workplace(
                id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                address: addressController.text.trim(),
                createdAt: DateTime.now(),
                companyId: _currentCompany.id, // Associate with this company
              );

              await widget.appProvider.addWorkplace(newWorkplace);

              Navigator.pop(context);
              setState(() {}); // Refresh the list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Workplace "${newWorkplace.name}" added'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _currentCompany.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditCompanyDialog,
            tooltip: 'Edit Company',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Company Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.business,
                      size: 50,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentCompany.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentCompany.address != null &&
                      _currentCompany.address!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _currentCompany.address!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Company Information Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Company Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_currentCompany.contactEmail != null &&
                          _currentCompany.contactEmail!.isNotEmpty)
                        _buildInfoRow(Icons.email, 'Email',
                            _currentCompany.contactEmail!),
                      if (_currentCompany.contactPhone != null &&
                          _currentCompany.contactPhone!.isNotEmpty)
                        _buildInfoRow(Icons.phone, 'Phone',
                            _currentCompany.contactPhone!),
                    ],
                  ),
                ),
              ),
            ),

            // Employees Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Employees',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<AppProvider>(
                            builder: (context, provider, child) {
                              return FutureBuilder<List<User>>(
                                future: provider.getUsers(),
                                builder: (context, snapshot) {
                                  final companyEmployees = snapshot.data
                                          ?.where((user) => user.companyIds
                                              .contains(_currentCompany.id))
                                          .toList() ??
                                      [];

                                  return Text(
                                    '${companyEmployees.length} ${companyEmployees.length == 1 ? 'Employee' : 'Employees'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.blue[700], size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'View and manage all employees in this company',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmployeesListScreen(
                                  appProvider: widget.appProvider,
                                  filterCompanyId: _currentCompany.id,
                                  customTitle:
                                      'Employees - ${_currentCompany.name}',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View Employees'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Workplaces Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Workplaces',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddWorkplaceDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Workplace'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      return FutureBuilder<List<Workplace>>(
                        future: provider.getWorkplaces(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData) {
                            return const Text('No workplaces found');
                          }

                          // Filter workplaces by company
                          final companyWorkplaces = snapshot.data!
                              .where((wp) => wp.companyId == _currentCompany.id)
                              .toList();

                          if (companyWorkplaces.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.store_outlined,
                                          size: 60, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No workplaces yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Click "Add Workplace" to create one',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: companyWorkplaces.length,
                            itemBuilder: (context, index) {
                              final workplace = companyWorkplaces[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green[700],
                                    child: const Icon(
                                      Icons.store,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    workplace.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: workplace.address.isNotEmpty
                                      ? Text(workplace.address)
                                      : null,
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StoreProfileScreen(
                                          workplace: workplace,
                                          appProvider: provider,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
