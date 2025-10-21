import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/company.dart';
import '../models/user.dart';
import 'super_admin_dashboard.dart';
import 'admin_dashboard.dart';
import 'employee_dashboard.dart';

class CompanySelectionScreen extends StatefulWidget {
  final User user;

  const CompanySelectionScreen({
    super.key,
    required this.user,
  });

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  List<Company> _userCompanies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserCompanies();
  }

  Future<void> _loadUserCompanies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final allCompanies = await appProvider.getCompanies();

      // Filter to only active companies that the user has access to
      final userCompanies = allCompanies.where((company) {
        return widget.user.companyIds.contains(company.id) && company.isActive;
      }).toList();

      setState(() {
        _userCompanies = userCompanies;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user companies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCompany(Company company) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Update user's primary company
      final updatedUser = widget.user.copyWith(primaryCompanyId: company.id);
      await appProvider.updateUser(updatedUser);

      // Navigate to appropriate dashboard based on user role
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => _buildDashboardForUser(updatedUser.role),
          ),
        );
      }
    } catch (e) {
      print('Error selecting company: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting company: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDashboardForUser(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const SuperAdminDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.employee:
        return const EmployeeDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Company'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userCompanies.isEmpty
              ? _buildNoCompaniesView()
              : _buildCompanyList(),
    );
  }

  Widget _buildNoCompaniesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Companies',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have access to any active companies. Please contact your administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Go back to login
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a company to continue:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _userCompanies.length,
              itemBuilder: (context, index) {
                final company = _userCompanies[index];
                final userRole = widget.user.getRoleForCompany(company.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.business,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              userRole == UserRole.admin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              size: 16,
                              color: userRole == UserRole.admin
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userRole == UserRole.admin
                                  ? 'Administrator'
                                  : 'Employee',
                              style: TextStyle(
                                color: userRole == UserRole.admin
                                    ? Colors.orange
                                    : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                    onTap: () => _selectCompany(company),
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
