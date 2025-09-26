import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/bonus.dart';
import '../models/points_transaction.dart';
import '../models/user.dart';

// Comprehensive Import Bonuses Screen for Admin
class ImportBonusesScreen extends StatefulWidget {
  final AppProvider appProvider;

  const ImportBonusesScreen({super.key, required this.appProvider});

  @override
  State<ImportBonusesScreen> createState() => _ImportBonusesScreenState();
}

class _ImportBonusesScreenState extends State<ImportBonusesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _bonusNameController = TextEditingController();
  final TextEditingController _bonusDescriptionController = TextEditingController();
  final TextEditingController _pointsRequiredController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bonusNameController.dispose();
    _bonusDescriptionController.dispose();
    _pointsRequiredController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Bonuses'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.card_giftcard), text: 'All Bonuses'),
            Tab(icon: Icon(Icons.history), text: 'Redemptions'),
            Tab(icon: Icon(Icons.add_circle), text: 'Add Bonus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllBonusesTab(),
          _buildRedemptionsTab(),
          _buildAddBonusTab(),
        ],
      ),
    );
  }

  // Tab 1: All Bonuses Management
  Widget _buildAllBonusesTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final bonuses = appProvider.bonuses;

        if (bonuses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No bonuses available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Add bonuses using the "Add Bonus" tab',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bonuses.length,
          itemBuilder: (context, index) {
            final bonus = bonuses[index];
            final redemptionCount = appProvider.pointsTransactions
                .where((t) => t.description.contains(bonus.name) && 
                             t.type == PointsTransactionType.redeemed)
                .length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    bonus.pointsRequired.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  bonus.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bonus.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.stars, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${bonus.pointsRequired} points',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('$redemptionCount redeemed'),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBonusDialog(bonus);
                    } else if (value == 'delete') {
                      _showDeleteBonusDialog(bonus);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Tab 2: Redemptions History
  Widget _buildRedemptionsTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final redemptions = appProvider.pointsTransactions
            .where((t) => t.type == PointsTransactionType.redeemed)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (redemptions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No redemptions yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Employee redemptions will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<User>>(
          future: appProvider.getUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!;
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: redemptions.length,
              itemBuilder: (context, index) {
                final transaction = redemptions[index];
                final user = users.firstWhere(
                  (u) => u.id == transaction.userId,
                  orElse: () => User(
                    id: transaction.userId,
                    name: 'Unknown User',
                    email: '',
                    role: UserRole.employee,
                    createdAt: DateTime.now(),
                  ),
                );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text(
                    transaction.points.abs().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  _cleanDescriptionFromSecretCode(transaction.description),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Redeemed by: ${user.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(transaction.date),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '-${transaction.points.abs()} pts',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
          },
        );
      },
    );
  }

  // Tab 3: Add New Bonus
  Widget _buildAddBonusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Bonus',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 24),
          
          // Bonus Name
          TextFormField(
            controller: _bonusNameController,
            decoration: const InputDecoration(
              labelText: 'Bonus Name',
              hintText: 'e.g., Coffee Voucher, Extra Day Off',
              prefixIcon: Icon(Icons.card_giftcard),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Bonus Description
          TextFormField(
            controller: _bonusDescriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what this bonus offers...',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Points Required
          TextFormField(
            controller: _pointsRequiredController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Points Required',
              hintText: 'e.g., 50, 100, 200',
              prefixIcon: Icon(Icons.stars),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Secret Code
          TextFormField(
            controller: _secretCodeController,
            decoration: const InputDecoration(
              labelText: 'Secret Code',
              hintText: 'e.g., COFFEE123, LUNCH2024',
              prefixIcon: Icon(Icons.security),
              border: OutlineInputBorder(),
              helperText: 'This code will be revealed when bonus is claimed',
            ),
          ),
          const SizedBox(height: 32),
          
          // Add Bonus Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _addNewBonus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle),
                  SizedBox(width: 8),
                  Text(
                    'Add Bonus',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Add Templates
          const Text(
            'Quick Templates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickTemplate('Coffee Voucher', 'Free coffee at any location', 50),
              _buildQuickTemplate('Lunch Voucher', 'Free lunch at company cafeteria', 100),
              _buildQuickTemplate('Extra Day Off', 'Take an extra day off with pay', 200),
              _buildQuickTemplate('Gift Card \$25', '\$25 gift card to any store', 300),
              _buildQuickTemplate('Parking Spot', 'Reserved parking for one month', 150),
              _buildQuickTemplate('Team Lunch', 'Team lunch at a restaurant', 400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplate(String name, String description, int points) {
    return GestureDetector(
      onTap: () {
        _bonusNameController.text = name;
        _bonusDescriptionController.text = description;
        _pointsRequiredController.text = points.toString();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$points points',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewBonus() async {
    if (_bonusNameController.text.isEmpty ||
        _bonusDescriptionController.text.isEmpty ||
        _pointsRequiredController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final points = int.tryParse(_pointsRequiredController.text);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of points'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newBonus = Bonus(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _bonusNameController.text,
      description: _bonusDescriptionController.text,
      pointsRequired: points,
      createdAt: DateTime.now(),
      secretCode: _secretCodeController.text.isNotEmpty ? _secretCodeController.text : null,
    );

    try {
      await widget.appProvider.addBonus(newBonus);
      
      // Clear form
      _bonusNameController.clear();
      _bonusDescriptionController.clear();
      _pointsRequiredController.clear();
      _secretCodeController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bonus "${newBonus.name}" added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Switch to All Bonuses tab to see the new bonus
      _tabController.animateTo(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding bonus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditBonusDialog(Bonus bonus) {
    final nameController = TextEditingController(text: bonus.name);
    final descriptionController = TextEditingController(text: bonus.description);
    final pointsController = TextEditingController(text: bonus.pointsRequired.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bonus'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Bonus Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Points Required',
                  border: OutlineInputBorder(),
                ),
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
                    content: Text('Please enter a valid number of points'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final updatedBonus = bonus.copyWith(
                name: nameController.text,
                description: descriptionController.text,
                pointsRequired: points,
              );

              try {
                await widget.appProvider.updateBonus(updatedBonus);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bonus updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating bonus: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBonusDialog(Bonus bonus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bonus'),
        content: Text('Are you sure you want to delete "${bonus.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.appProvider.deleteBonus(bonus.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bonus deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting bonus: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Remove secret code from transaction description for admin redemptions display
  String _cleanDescriptionFromSecretCode(String description) {
    return description.replaceAll(RegExp(r'\s*\(Secret Code: .+?\)'), '');
  }
}
