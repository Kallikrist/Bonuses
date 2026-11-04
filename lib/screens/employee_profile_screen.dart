import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company.dart';
import '../models/points_transaction.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';
import 'chat_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final User employee;
  final AppProvider appProvider;
  final bool showBackButton; // Whether to show back button in AppBar
  final String?
      companyContext; // Optional: which company context to show points for
  final bool readOnly; // If true, hide all edit functionality

  const EmployeeProfileScreen({
    Key? key,
    required this.employee,
    required this.appProvider,
    this.showBackButton = true, // Default to true for backwards compatibility
    this.companyContext, // Optional company context
    this.readOnly = false, // Default to false (editable)
  }) : super(key: key);

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  late User currentEmployee;

  @override
  void initState() {
    super.initState();
    currentEmployee = widget.employee;
  }

  Widget _buildCompanySuspensionBanner() {
    return FutureBuilder<Company?>(
      future: _getUserPrimaryCompany(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Don't show anything while loading
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox
              .shrink(); // Don't show banner if company not found
        }

        final company = snapshot.data!;
        if (company.isActive) {
          return const SizedBox
              .shrink(); // Don't show banner if company is active
        }

        // Show suspension banner
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Suspended',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your company "${company.name}" has been suspended by the platform administrator. Some features may be limited.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Company?> _getUserPrimaryCompany() async {
    try {
      final currentUser = widget.appProvider.currentUser;
      if (currentUser?.primaryCompanyId == null) return null;

      return await widget.appProvider
          .getCompanyById(currentUser!.primaryCompanyId!);
    } catch (e) {
      print('Error getting user primary company: $e');
      return null;
    }
  }

  // Check if current user is admin in the company context
  bool _isAdminInContext() {
    final currentUser = widget.appProvider.currentUser;
    if (currentUser == null) return false;

    // Get the company context - use provided context or current user's primary company
    final contextCompanyId =
        widget.companyContext ?? currentUser.primaryCompanyId;
    if (contextCompanyId == null) return false;

    // Check if current user has admin role in this company
    final role = currentUser.getRoleForCompany(contextCompanyId);
    return role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${currentEmployee.name} Profile',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null, // No back button when viewing own profile from tab bar
        automaticallyImplyLeading:
            widget.showBackButton, // Prevent default back button
        actions: widget.readOnly
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement edit functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Edit functionality coming soon')),
                    );
                  },
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[600]!],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Text(
                        currentEmployee.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentEmployee.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentEmployee.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Consumer<AppProvider>(
                            builder: (context, provider, child) {
                              // Get company-specific points based on company context or admin's current company
                              final companyId = widget.companyContext ??
                                  provider.currentUser?.primaryCompanyId;
                              final currentPoints = companyId != null
                                  ? provider.getUserCompanyPoints(
                                      currentEmployee.id, companyId)
                                  : 0;
                              return Text(
                                '$currentPoints points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Company Suspension Status Banner
            _buildCompanySuspensionBanner(),

            // Profile Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileSection(
                    'Personal Information',
                    Icons.person,
                    [
                      _buildProfileField(
                        Icons.person,
                        'Full Name',
                        currentEmployee.name,
                        widget.readOnly
                            ? null
                            : () => _showEditFieldDialog(
                                    'Name', currentEmployee.name,
                                    (newValue) async {
                                  try {
                                    final updatedEmployee = currentEmployee
                                        .copyWith(name: newValue);
                                    await widget.appProvider
                                        .updateUser(updatedEmployee);
                                    setState(() {
                                      currentEmployee = updatedEmployee;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating name: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }),
                      ),
                      _buildProfileField(
                        Icons.email,
                        'Email Address',
                        currentEmployee.email,
                        widget.readOnly
                            ? null
                            : () => _showEditFieldDialog(
                                    'Email', currentEmployee.email,
                                    (newValue) async {
                                  try {
                                    final updatedEmployee = currentEmployee
                                        .copyWith(email: newValue);
                                    await widget.appProvider
                                        .updateUser(updatedEmployee);
                                    setState(() {
                                      currentEmployee = updatedEmployee;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating email: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }),
                      ),
                      _buildProfileField(
                        Icons.phone,
                        'Phone Number',
                        currentEmployee.phoneNumber ?? 'Not set',
                        widget.readOnly
                            ? null
                            : () => _showEditFieldDialog('Phone Number',
                                    currentEmployee.phoneNumber ?? '',
                                    (newValue) async {
                                  try {
                                    final updatedEmployee = currentEmployee
                                        .copyWith(phoneNumber: newValue);
                                    await widget.appProvider
                                        .updateUser(updatedEmployee);
                                    setState(() {
                                      currentEmployee = updatedEmployee;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating phone: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }),
                      ),
                      // Add message button if not viewing own profile
                      if (widget.appProvider.currentUser?.id !=
                          currentEmployee.id)
                        _buildMessageButton(),
                      // Add gift points button if not viewing own profile
                      if (widget.appProvider.currentUser?.id !=
                          currentEmployee.id)
                        _buildGiftPointsButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    'Performance & Statistics',
                    Icons.analytics,
                    [
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          // Get company-specific points based on company context or admin's current company
                          final companyId = widget.companyContext ??
                              provider.currentUser?.primaryCompanyId;
                          final currentPoints = companyId != null
                              ? provider.getUserCompanyPoints(
                                  currentEmployee.id, companyId)
                              : 0;
                          return _buildProfileField(
                            Icons.stars,
                            'Points',
                            '$currentPoints points',
                            null,
                          );
                        },
                      ),
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          // Get company-specific role
                          final companyId = widget.companyContext ??
                              provider.currentUser?.primaryCompanyId;
                          final currentRole = companyId != null
                              ? currentEmployee.getRoleForCompany(companyId)
                              : currentEmployee.role;
                          // Check if viewing own profile
                          final isOwnProfile =
                              provider.currentUser?.id == currentEmployee.id;
                          return _buildRoleDropdownField(
                            Icons.work,
                            'Role',
                            currentRole,
                            companyId, // Pass company ID for context
                            isOwnProfile, // Pass flag to disable editing own role
                          );
                        },
                      ),
                      Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          return _buildCompanyDropdownField(
                            Icons.business,
                            'Company',
                            currentEmployee,
                            provider,
                          );
                        },
                      ),
                      _buildProfileField(
                        Icons.calendar_today,
                        'Member Since',
                        'Recently joined',
                        null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    'Workplace Assignments',
                    Icons.business,
                    [
                      if (currentEmployee.workplaceNames.isNotEmpty)
                        _buildProfileField(
                          Icons.location_on,
                          'Works at',
                          currentEmployee.workplaceNames.join(', '),
                          null,
                        )
                      else
                        _buildProfileField(
                          Icons.location_off,
                          'No workplace assigned',
                          'This employee is not assigned to any workplace',
                          null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Always show Points History
                  _buildProfileSection(
                    'Points & History',
                    Icons.history,
                    [
                      _buildProfileField(
                        Icons.history,
                        'Points History',
                        'View points transactions',
                        () => _showPointsHistoryDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Only show Administrative Actions if current user is admin in this company context
                  if (_isAdminInContext())
                    _buildProfileSection(
                      'Administrative Actions',
                      Icons.admin_panel_settings,
                      [
                        _buildProfileField(
                          Icons.lock_reset,
                          'Reset Password',
                          'Send password reset email',
                          () => _showResetPasswordDialog(),
                        ),
                        _buildProfileField(
                          Icons.stars,
                          'Adjust Points',
                          'Add or remove points',
                          () => _showAdjustPointsDialog(),
                        ),
                        _buildProfileField(
                          Icons.notifications,
                          'Send Notification',
                          'Send message to employee',
                          () => _showSendNotificationDialog(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
      IconData icon, String label, String value, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: onTap != null ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _sendMessageToEmployee,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.message, color: Colors.blue[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Send a message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftPointsButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showGiftPointsDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.blue[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gift Points',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Send points as a gift',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showGiftPointsDialog() {
    final currentUser = widget.appProvider.currentUser;
    if (currentUser == null) return;

    // Get the company context for points
    final companyId = widget.companyContext ?? currentUser.primaryCompanyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No company context available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get sender's current points in this company
    final senderPoints = widget.appProvider.getUserCompanyPoints(
      currentUser.id,
      companyId,
    );

    final pointsController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gift Points'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send points to ${currentEmployee.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your available points: $senderPoints',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points to gift',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.stars),
                  hintText: 'Enter amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Add a note',
                ),
                maxLines: 3,
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
              final points = int.tryParse(pointsController.text);
              if (points == null || points <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid positive number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (points > senderPoints) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You don\'t have enough points'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Deduct points from sender and add to recipient
              final giftMessage = messageController.text.isNotEmpty
                  ? ': ${messageController.text}'
                  : '';

              await widget.appProvider.updateUserPoints(
                currentUser.id,
                -points,
                'Gifted to ${currentEmployee.name}$giftMessage',
                companyId: companyId,
              );

              await widget.appProvider.updateUserPoints(
                currentEmployee.id,
                points,
                'Gift from ${currentUser.name}$giftMessage',
                companyId: companyId,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Gifted $points points to ${currentEmployee.name}!'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {}); // Refresh the UI
              }
            },
            child: const Text('Send Gift'),
          ),
        ],
      ),
    );
  }

  void _showEditFieldDialog(
      String fieldName, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$fieldName updated successfully'),
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

  void _sendMessageToEmployee() {
    // Navigate to chat screen with this employee
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipient: currentEmployee,
        ),
      ),
    );
  }

  void _showQuickEditDialog() {
    UserRole selectedRole = currentEmployee.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Current role: ${_getRoleDisplayName(currentEmployee.role)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'New Role',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(_getRoleDisplayName(role)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),
              if (selectedRole != currentEmployee.role) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedRole == UserRole.admin
                        ? Colors.purple.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedRole == UserRole.admin
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: selectedRole == UserRole.admin
                            ? Colors.purple
                            : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'New permissions: ${_getRoleDescription(selectedRole)}',
                          style: TextStyle(
                            color: selectedRole == UserRole.admin
                                ? Colors.purple.shade700
                                : Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (selectedRole != currentEmployee.role)
              ElevatedButton(
                onPressed: () async {
                  try {
                    Navigator.pop(context);

                    // Update the employee's role
                    final updatedEmployee =
                        currentEmployee.copyWith(role: selectedRole);
                    await widget.appProvider.updateUser(updatedEmployee);

                    // Update the local currentEmployee instance
                    setState(() {
                      currentEmployee = updatedEmployee;
                    });

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${currentEmployee.name} role changed to ${_getRoleDisplayName(selectedRole)}',
                        ),
                        backgroundColor: selectedRole == UserRole.admin
                            ? Colors.purple
                            : Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating role: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRole == UserRole.admin
                      ? Colors.purple
                      : Colors.blue,
                ),
                child: Text(
                  'Update Role',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.employee:
        return 'Employee';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full admin access - can manage all users, targets, bonuses, and system settings';
      case UserRole.employee:
        return 'Employee access - can view and update their own targets and redeem bonuses';
      case UserRole.superAdmin:
        return 'Platform owner - full access to all companies, subscriptions, and billing management';
    }
  }

  Widget _buildRoleDropdownField(IconData icon, String label,
      UserRole currentRole, String? companyId, bool isOwnProfile) {
    // If viewing own profile or in read-only mode, show read-only field instead of dropdown
    if (isOwnProfile || widget.readOnly) {
      return _buildProfileField(
        icon,
        label,
        _getRoleDisplayName(currentRole),
        null, // No tap action - read-only
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: null, // Let the dropdown handle the interaction
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: currentRole,
                        icon: Icon(Icons.arrow_drop_down,
                            color: Colors.grey[400]),
                        isExpanded: true,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  role == UserRole.admin
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  size: 16,
                                  color: role == UserRole.admin
                                      ? Colors.purple
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getRoleDisplayName(role),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (UserRole? newRole) {
                          if (newRole != null && newRole != currentRole) {
                            // Show confirmation dialog when a different role is selected
                            _showRoleChangeConfirmation(newRole, companyId);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyDropdownField(
      IconData icon, String label, User employee, AppProvider provider) {
    // If in read-only mode, show as a simple read-only field
    if (widget.readOnly) {
      return FutureBuilder<List<Company>>(
        future: provider.getCompanies(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildProfileField(icon, label, 'Loading...', null);
          }

          final companies = snapshot.data!;
          final company = companies.firstWhere(
            (c) => c.id == employee.primaryCompanyId,
            orElse: () => Company(
                id: '',
                name: 'No company',
                address: null,
                contactEmail: null,
                contactPhone: null,
                adminUserId: '',
                createdAt: DateTime.now()),
          );

          return _buildProfileField(
            icon,
            label,
            company.name,
            null, // No tap action - read-only
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<List<Company>>(
                    future: provider.getCompanies(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...');
                      }

                      final allCompanies = snapshot.data!;
                      final currentCompanyId = employee.primaryCompanyId;
                      final currentUser = provider.currentUser;

                      // Determine which companies to show
                      final List<Company> displayCompanies;

                      // If viewing own profile, show ALL user's companies
                      if (currentUser?.id == employee.id) {
                        displayCompanies = allCompanies
                            .where((c) => employee.companyIds.contains(c.id))
                            .toList();
                      } else {
                        // If viewing another employee, only show shared companies
                        displayCompanies = allCompanies.where((company) {
                          final employeeInCompany =
                              employee.companyIds.contains(company.id);
                          final adminInCompany =
                              currentUser?.companyIds.contains(company.id) ??
                                  false;
                          return employeeInCompany && adminInCompany;
                        }).toList();
                      }

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: displayCompanies
                                  .any((c) => c.id == currentCompanyId)
                              ? currentCompanyId
                              : null,
                          icon: Icon(Icons.arrow_drop_down,
                              color: Colors.grey[400]),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.business_outlined,
                                      size: 16, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    'None',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...displayCompanies.map((company) {
                              return DropdownMenuItem<String?>(
                                value: company.id,
                                child: Row(
                                  children: [
                                    const Icon(Icons.business,
                                        size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      company.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (String? newCompanyId) {
                            if (newCompanyId != currentCompanyId) {
                              _showCompanyChangeConfirmation(employee,
                                  newCompanyId, displayCompanies, provider);
                            }
                          },
                        ),
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

  void _showCompanyChangeConfirmation(User employee, String? newCompanyId,
      List<Company> companies, AppProvider provider) {
    final newCompany = newCompanyId != null
        ? companies.firstWhere((c) => c.id == newCompanyId)
        : null;

    final oldCompanyName =
        employee.companyNames.isNotEmpty ? employee.companyNames.first : 'None';
    final newCompanyName = newCompany?.name ?? 'None';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Company Change'),
        content: Text(
          'Change company from "$oldCompanyName" to "$newCompanyName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Only update the primary company, keep all existing companies
              final updatedEmployee = employee.copyWith(
                primaryCompanyId: newCompany?.id,
              );

              await provider.updateUser(updatedEmployee);
              setState(() {
                currentEmployee = updatedEmployee;
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to $newCompanyName'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeConfirmation(UserRole newRole, String? companyId) {
    // Get current role for the company context
    final currentRole = companyId != null
        ? currentEmployee.getRoleForCompany(companyId)
        : currentEmployee.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  currentRole == UserRole.admin
                      ? Icons.admin_panel_settings
                      : Icons.person,
                  color: currentRole == UserRole.admin
                      ? Colors.purple
                      : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(_getRoleDisplayName(currentRole)),
                const Text(' → '),
                Icon(
                  newRole == UserRole.admin
                      ? Icons.admin_panel_settings
                      : Icons.person,
                  color:
                      newRole == UserRole.admin ? Colors.purple : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(_getRoleDisplayName(newRole)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: newRole == UserRole.admin
                    ? Colors.purple.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: newRole == UserRole.admin
                      ? Colors.purple.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Text(
                _getRoleDescription(newRole),
                style: TextStyle(
                  color: newRole == UserRole.admin
                      ? Colors.purple.shade700
                      : Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to change this user\'s role? This will affect their permissions immediately.',
              style: TextStyle(fontWeight: FontWeight.w500),
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
              try {
                Navigator.pop(context);

                // Update the employee's role for this company
                User updatedEmployee;
                if (companyId != null) {
                  // Update company-specific role
                  updatedEmployee =
                      currentEmployee.setRoleForCompany(companyId, newRole);
                } else {
                  // Update global role (fallback)
                  updatedEmployee = currentEmployee.copyWith(role: newRole);
                }

                await widget.appProvider.updateUser(updatedEmployee);

                // Update the local currentEmployee instance
                setState(() {
                  currentEmployee = updatedEmployee;
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${currentEmployee.name} role changed to ${_getRoleDisplayName(newRole)} successfully${companyId != null ? ' for this company' : ''}',
                    ),
                    backgroundColor: newRole == UserRole.admin
                        ? Colors.purple
                        : Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating role: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newRole == UserRole.admin ? Colors.purple : Colors.blue,
            ),
            child: const Text(
              'Confirm Role Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${currentEmployee.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Password reset email sent to ${currentEmployee.email}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAdjustPointsDialog() {
    final pointsController = TextEditingController();
    String selectedAction = 'add';

    // Get company ID from context or admin's current company
    final adminCompanyId = widget.companyContext ??
        widget.appProvider.currentUser?.primaryCompanyId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adjust Points'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final currentPoints = adminCompanyId != null
                      ? provider.getUserCompanyPoints(
                          currentEmployee.id, adminCompanyId)
                      : 0;
                  return Text('Current points: $currentPoints');
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAction,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'add', child: Text('Add Points')),
                  DropdownMenuItem(
                      value: 'remove', child: Text('Remove Points')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedAction = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final points = int.tryParse(pointsController.text);
                print(
                    'DEBUG: UI - Entered points: $points, Action: $selectedAction, Company: $adminCompanyId');
                if (points != null && points > 0) {
                  Navigator.pop(context);

                  // Calculate the points change (positive for add, negative for remove)
                  final pointsChange =
                      selectedAction == 'add' ? points : -points;
                  print('DEBUG: UI - Calculated pointsChange: $pointsChange');
                  final description = selectedAction == 'add'
                      ? 'Admin added $points points'
                      : 'Admin removed $points points';

                  try {
                    // Update the employee's points for the current company
                    await widget.appProvider.updateUserPoints(
                        currentEmployee.id, pointsChange, description,
                        companyId: adminCompanyId);

                    // Refresh the employee data from the provider
                    final updatedUsers = await StorageService.getUsers();
                    final updatedEmployee = updatedUsers.firstWhere(
                      (user) => user.id == currentEmployee.id,
                      orElse: () => currentEmployee,
                    );

                    // Update the local employee object with fresh data
                    setState(() {
                      currentEmployee = updatedEmployee;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${selectedAction == 'add' ? 'Added' : 'Removed'} $points points for ${currentEmployee.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating points: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendNotificationDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send a message to ${currentEmployee.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Enter your message here...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Notification sent to ${currentEmployee.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showPointsHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Points History - ${currentEmployee.name}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Points Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Consumer<AppProvider>(
                      builder: (context, provider, child) {
                        // Get the company context for filtering
                        final companyId = widget.companyContext ??
                            provider.currentUser?.primaryCompanyId;

                        final currentPoints = companyId != null
                            ? provider.getUserCompanyPoints(
                                currentEmployee.id, companyId)
                            : provider.getUserTotalPoints(currentEmployee.id);

                        // Calculate earned and spent from company-filtered transactions
                        final companyTransactions = provider.pointsTransactions
                            .where((t) =>
                                t.userId == currentEmployee.id &&
                                (companyId == null || t.companyId == companyId))
                            .toList();

                        final totalEarned =
                            companyTransactions.fold(0, (sum, t) {
                          if (t.type == PointsTransactionType.earned ||
                              t.type == PointsTransactionType.adjustment) {
                            return sum + t.points;
                          }
                          return sum;
                        });

                        final totalSpent =
                            companyTransactions.fold(0, (sum, t) {
                          if (t.type == PointsTransactionType.redeemed ||
                              t.type == PointsTransactionType.bonus) {
                            return sum + t.points;
                          }
                          return sum;
                        });

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPointsSummaryCard(
                              'Current Points',
                              '$currentPoints',
                              Icons.stars,
                              Colors.blue,
                            ),
                            _buildPointsSummaryCard(
                              'Total Earned',
                              '$totalEarned',
                              Icons.trending_up,
                              Colors.green,
                            ),
                            _buildPointsSummaryCard(
                              'Total Spent',
                              '$totalSpent',
                              Icons.trending_down,
                              Colors.red,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Points History List
              Expanded(
                child: FutureBuilder<List<PointsTransaction>>(
                  future: Future.value(widget.appProvider.pointsTransactions),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No points history found'));
                    }

                    // Get the company context for filtering
                    final companyId = widget.companyContext ??
                        widget.appProvider.currentUser?.primaryCompanyId;

                    // Filter transactions for this employee AND company
                    final employeeTransactions = snapshot.data!
                        .where((t) =>
                            t.userId == currentEmployee.id &&
                            (companyId == null || t.companyId == companyId))
                        .toList()
                      ..sort((a, b) => b.date
                          .compareTo(a.date)); // Sort by date, newest first

                    if (employeeTransactions.isEmpty) {
                      return const Center(
                          child: Text('No points history for this employee'));
                    }

                    // Calculate totals from actual transactions
                    final totalEarned = employeeTransactions
                        .where((t) =>
                            t.type == PointsTransactionType.earned ||
                            (t.type == PointsTransactionType.adjustment &&
                                t.points > 0))
                        .fold<int>(0, (sum, t) => sum + t.points);

                    final totalSpent = employeeTransactions
                        .where((t) =>
                            t.type == PointsTransactionType.redeemed ||
                            (t.type == PointsTransactionType.adjustment &&
                                t.points < 0))
                        .fold<int>(0, (sum, t) => sum + t.points.abs());

                    return Column(
                      children: [
                        // Updated Summary with real calculations
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Consumer<AppProvider>(
                                builder: (context, provider, child) {
                                  // Get company-specific points
                                  final companyId = widget.companyContext ??
                                      provider.currentUser?.primaryCompanyId;
                                  final currentPoints = companyId != null
                                      ? provider.getUserCompanyPoints(
                                          currentEmployee.id, companyId)
                                      : 0;
                                  return _buildPointsSummaryCard(
                                    'Current Points',
                                    '$currentPoints',
                                    Icons.stars,
                                    Colors.blue,
                                  );
                                },
                              ),
                              _buildPointsSummaryCard(
                                'Total Earned',
                                '$totalEarned',
                                Icons.trending_up,
                                Colors.green,
                              ),
                              _buildPointsSummaryCard(
                                'Total Spent',
                                '$totalSpent',
                                Icons.trending_down,
                                Colors.red,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Transaction List
                        Expanded(
                          child: ListView.builder(
                            itemCount: employeeTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = employeeTransactions[index];
                              return _buildPointsTransactionCard(
                                  transaction, index);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsTransactionCard(PointsTransaction transaction, int index) {
    // Consider adjustment transactions with positive points as "earned" for display
    final isEarned = transaction.type == PointsTransactionType.earned ||
        (transaction.type == PointsTransactionType.adjustment &&
            transaction.points > 0);
    final isRedeemed = transaction.type == PointsTransactionType.redeemed ||
        (transaction.type == PointsTransactionType.adjustment &&
            transaction.points < 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Transaction Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEarned ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isEarned ? Icons.add : Icons.remove,
                color: isEarned ? Colors.green[600] : Colors.red[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (transaction.relatedTargetId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Target ID: ${transaction.relatedTargetId}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Points Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isEarned ? '+' : '-'}${transaction.points}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEarned ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                Text(
                  'points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateTotalEarned() {
    // This will be calculated from actual transactions in the dialog
    return 0; // Placeholder, will be calculated dynamically
  }

  int _calculateTotalSpent() {
    // This will be calculated from actual transactions in the dialog
    return 0; // Placeholder, will be calculated dynamically
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
