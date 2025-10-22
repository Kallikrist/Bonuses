import 'package:flutter/material.dart';
import '../models/bank_account.dart';
import '../services/storage_service.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  List<BankAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await StorageService.getBankAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bank accounts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? _buildEmptyState()
              : _buildAccountsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Bank Accounts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a bank account to receive payments from companies',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddAccountDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Bank Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(account.status).withOpacity(0.1),
              child: Text(
                account.accountIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              '${account.bankName} • ${account.maskedAccountNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${account.accountTypeDisplay} • ${account.accountHolderName}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusChip(account.status),
                    if (account.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleAccountAction(value, account),
              itemBuilder: (context) => [
                if (!account.isDefault)
                  const PopupMenuItem(
                    value: 'set_default',
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 16),
                        SizedBox(width: 8),
                        Text('Set as Default'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showAccountDetails(account),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BankAccountStatus status) {
    Color color;
    String text;

    switch (status) {
      case BankAccountStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case BankAccountStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case BankAccountStatus.suspended:
        color = Colors.red;
        text = 'Suspended';
        break;
      case BankAccountStatus.closed:
        color = Colors.grey;
        text = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(BankAccountStatus status) {
    switch (status) {
      case BankAccountStatus.active:
        return Colors.green;
      case BankAccountStatus.pending:
        return Colors.orange;
      case BankAccountStatus.suspended:
        return Colors.red;
      case BankAccountStatus.closed:
        return Colors.grey;
    }
  }

  void _handleAccountAction(String action, BankAccount account) {
    switch (action) {
      case 'set_default':
        _setDefaultAccount(account);
        break;
      case 'edit':
        _showEditAccountDialog(account);
        break;
      case 'delete':
        _deleteAccount(account);
        break;
    }
  }

  Future<void> _setDefaultAccount(BankAccount account) async {
    try {
      // Remove default from other accounts
      for (final acc in _accounts) {
        if (acc.isDefault && acc.id != account.id) {
          final updatedAccount = acc.copyWith(isDefault: false);
          await StorageService.updateBankAccount(updatedAccount);
        }
      }

      // Set this account as default
      final updatedAccount = account.copyWith(isDefault: true);
      await StorageService.updateBankAccount(updatedAccount);

      await _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default account updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating default account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(BankAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: Text(
            'Are you sure you want to delete the ${account.bankName} account ending in ${account.maskedAccountNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageService.deleteBankAccount(account.id);
        await _loadAccounts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank account deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAccountDetails(BankAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bank Account Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Bank Name', account.bankName),
              _buildDetailRow('Account Holder', account.accountHolderName),
              _buildDetailRow('Account Number', account.maskedAccountNumber),
              _buildDetailRow('Routing Number', account.routingNumber),
              _buildDetailRow('Account Type', account.accountTypeDisplay),
              _buildDetailRow('Status', account.statusDisplay),
              if (account.address != null)
                _buildDetailRow('Address', account.address!),
              if (account.city != null) _buildDetailRow('City', account.city!),
              if (account.state != null)
                _buildDetailRow('State', account.state!),
              if (account.zipCode != null)
                _buildDetailRow('ZIP Code', account.zipCode!),
              if (account.country != null)
                _buildDetailRow('Country', account.country!),
              if (account.swiftCode != null)
                _buildDetailRow('SWIFT Code', account.swiftCode!),
              if (account.iban != null) _buildDetailRow('IBAN', account.iban!),
              _buildDetailRow(
                  'Created', account.createdAt.toString().split(' ')[0]),
              if (account.verifiedAt != null)
                _buildDetailRow(
                    'Verified', account.verifiedAt!.toString().split(' ')[0]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditAccountDialog(account);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddAccountDialog() {
    _showAccountDialog();
  }

  void _showEditAccountDialog(BankAccount account) {
    _showAccountDialog(account: account);
  }

  void _showAccountDialog({BankAccount? account}) {
    showDialog(
      context: context,
      builder: (context) => BankAccountDialog(
        account: account,
        onAccountSaved: () {
          Navigator.pop(context);
          _loadAccounts();
        },
      ),
    );
  }
}

class BankAccountDialog extends StatefulWidget {
  final BankAccount? account;
  final VoidCallback onAccountSaved;

  const BankAccountDialog({
    super.key,
    this.account,
    required this.onAccountSaved,
  });

  @override
  State<BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends State<BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  final _ibanController = TextEditingController();

  BankAccountType _selectedAccountType = BankAccountType.checking;
  BankAccountStatus _selectedStatus = BankAccountStatus.pending;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final account = widget.account!;
    _accountHolderController.text = account.accountHolderName;
    _accountNumberController.text = account.accountNumber;
    _routingNumberController.text = account.routingNumber;
    _bankNameController.text = account.bankName;
    _addressController.text = account.address ?? '';
    _cityController.text = account.city ?? '';
    _stateController.text = account.state ?? '';
    _zipCodeController.text = account.zipCode ?? '';
    _countryController.text = account.country ?? '';
    _swiftCodeController.text = account.swiftCode ?? '';
    _ibanController.text = account.iban ?? '';
    _selectedAccountType = account.accountType;
    _selectedStatus = account.status;
    _isDefault = account.isDefault;
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _swiftCodeController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.account == null ? 'Add Bank Account' : 'Edit Bank Account'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account holder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _accountNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Account Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _routingNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Routing Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter bank name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BankAccountType>(
                  value: _selectedAccountType,
                  decoration: const InputDecoration(
                    labelText: 'Account Type',
                    border: OutlineInputBorder(),
                  ),
                  items: BankAccountType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == BankAccountType.checking
                          ? 'Checking Account'
                          : type == BankAccountType.savings
                              ? 'Savings Account'
                              : 'Business Account'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAccountType = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BankAccountStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: BankAccountStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status == BankAccountStatus.active
                          ? 'Active'
                          : status == BankAccountStatus.pending
                              ? 'Pending Verification'
                              : status == BankAccountStatus.suspended
                                  ? 'Suspended'
                                  : 'Closed'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Set as Default Account'),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() => _isDefault = value ?? false);
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Optional Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _zipCodeController,
                        decoration: const InputDecoration(
                          labelText: 'ZIP Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _swiftCodeController,
                        decoration: const InputDecoration(
                          labelText: 'SWIFT Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _ibanController,
                        decoration: const InputDecoration(
                          labelText: 'IBAN',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.account == null ? 'Add Account' : 'Update Account'),
        ),
      ],
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final account = BankAccount(
        id: widget.account?.id ??
            'bank_${DateTime.now().millisecondsSinceEpoch}',
        accountHolderName: _accountHolderController.text,
        accountNumber: _accountNumberController.text,
        routingNumber: _routingNumberController.text,
        bankName: _bankNameController.text,
        accountType: _selectedAccountType,
        status: _selectedStatus,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        state: _stateController.text.isEmpty ? null : _stateController.text,
        zipCode:
            _zipCodeController.text.isEmpty ? null : _zipCodeController.text,
        country:
            _countryController.text.isEmpty ? null : _countryController.text,
        swiftCode: _swiftCodeController.text.isEmpty
            ? null
            : _swiftCodeController.text,
        iban: _ibanController.text.isEmpty ? null : _ibanController.text,
        createdAt: widget.account?.createdAt ?? DateTime.now(),
        verifiedAt: widget.account?.verifiedAt,
        isDefault: _isDefault,
      );

      if (widget.account == null) {
        await StorageService.addBankAccount(account);
      } else {
        await StorageService.updateBankAccount(account);
      }

      widget.onAccountSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.account == null
              ? 'Bank account added successfully'
              : 'Bank account updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
