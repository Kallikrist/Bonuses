import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/company.dart';
import '../models/user.dart';
import 'company_profile_screen.dart';

class CompaniesListScreen extends StatefulWidget {
  final AppProvider appProvider;

  const CompaniesListScreen({
    super.key,
    required this.appProvider,
  });

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  void _showAddCompanyDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Company'),
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
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone (Optional)',
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
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final newCompany = Company(
                id: 'company_${DateTime.now().millisecondsSinceEpoch}',
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
                adminUserId: widget.appProvider.currentUser!.id,
                createdAt: DateTime.now(),
              );

              await widget.appProvider.addCompany(newCompany);

              // Assign to current admin and set role
              final currentUser = widget.appProvider.currentUser!;
              if (currentUser.primaryCompanyId == null) {
                final updatedRoles =
                    Map<String, String>.from(currentUser.companyRoles);
                updatedRoles[newCompany.id] =
                    UserRole.admin.toString().split('.').last;

                final updatedUser = currentUser.copyWith(
                  primaryCompanyId: newCompany.id,
                  companyIds: [...currentUser.companyIds, newCompany.id],
                  companyNames: [...currentUser.companyNames, newCompany.name],
                  companyRoles: updatedRoles,
                );
                await widget.appProvider.updateUser(updatedUser);
              } else if (!currentUser.companyIds.contains(newCompany.id)) {
                final updatedRoles =
                    Map<String, String>.from(currentUser.companyRoles);
                updatedRoles[newCompany.id] =
                    UserRole.admin.toString().split('.').last;

                final updatedUser = currentUser.copyWith(
                  companyIds: [...currentUser.companyIds, newCompany.id],
                  companyNames: [...currentUser.companyNames, newCompany.name],
                  companyRoles: updatedRoles,
                );
                await widget.appProvider.updateUser(updatedUser);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Company "${newCompany.name}" created!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _navigateToCompanyProfile(Company company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProfileScreen(
          company: company,
          appProvider: widget.appProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Companies'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<List<Company>>(
            future: provider.getCompanies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No companies yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click + to create your first company',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final allCompanies = snapshot.data!;
              final currentUser = provider.currentUser;

              // Filter companies to only show the currently active company
              final companies = allCompanies.where((company) {
                return currentUser != null &&
                    company.id == currentUser.primaryCompanyId;
              }).toList();

              // Show empty state if user has no companies
              if (companies.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No companies yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click + to create your first company',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[700],
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        company.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (company.address != null &&
                              company.address!.isNotEmpty)
                            Text(
                              company.address!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          if (company.contactEmail != null &&
                              company.contactEmail!.isNotEmpty)
                            Text(
                              company.contactEmail!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _navigateToCompanyProfile(company),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCompanyDialog,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
