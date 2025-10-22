import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/financial_transaction.dart';
import '../services/payment_service.dart';

class FinancialTransactionsScreen extends StatefulWidget {
  const FinancialTransactionsScreen({super.key});

  @override
  State<FinancialTransactionsScreen> createState() => _FinancialTransactionsScreenState();
}

class _FinancialTransactionsScreenState extends State<FinancialTransactionsScreen> {
  List<FinancialTransaction> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final companyId = appProvider.currentUser?.primaryCompanyId;
      if (companyId != null) {
        final transactions = await PaymentService.getCompanyTransactions(companyId);
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<FinancialTransaction> get _filteredTransactions {
    if (_selectedFilter == 'all') return _transactions;
    return _transactions.where((tx) => tx.category.name == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Transactions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Transactions')),
              const PopupMenuItem(value: 'subscription', child: Text('Subscriptions')),
              const PopupMenuItem(value: 'bonus', child: Text('Bonuses')),
              const PopupMenuItem(value: 'gift', child: Text('Gifts')),
              const PopupMenuItem(value: 'points', child: Text('Points')),
              const PopupMenuItem(value: 'refund', child: Text('Refunds')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTransactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your financial transactions will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(transaction.status).withOpacity(0.1),
              child: Text(
                transaction.transactionIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              transaction.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusChip(transaction.status),
                    const SizedBox(width: 8),
                    _buildCategoryChip(transaction.category),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getAmountColor(transaction),
                    fontSize: 16,
                  ),
                ),
                if (transaction.transactionId != null)
                  Text(
                    'ID: ${transaction.transactionId!.substring(0, 8)}...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            onTap: () => _showTransactionDetails(transaction),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(TransactionStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case TransactionStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TransactionStatus.processing:
        color = Colors.blue;
        text = 'Processing';
        break;
      case TransactionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
      case TransactionStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
      case TransactionStatus.refunded:
        color = Colors.purple;
        text = 'Refunded';
        break;
      case TransactionStatus.partiallyRefunded:
        color = Colors.purple;
        text = 'Partially Refunded';
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

  Widget _buildCategoryChip(TransactionCategory category) {
    Color color;
    String text;
    
    switch (category) {
      case TransactionCategory.subscription:
        color = Colors.blue;
        text = 'Subscription';
        break;
      case TransactionCategory.bonus:
        color = Colors.green;
        text = 'Bonus';
        break;
      case TransactionCategory.gift:
        color = Colors.pink;
        text = 'Gift';
        break;
      case TransactionCategory.points:
        color = Colors.orange;
        text = 'Points';
        break;
      case TransactionCategory.refund:
        color = Colors.purple;
        text = 'Refund';
        break;
      case TransactionCategory.adjustment:
        color = Colors.grey;
        text = 'Adjustment';
        break;
      case TransactionCategory.other:
        color = Colors.grey;
        text = 'Other';
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

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.processing:
        return Colors.blue;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
      case TransactionStatus.refunded:
        return Colors.purple;
      case TransactionStatus.partiallyRefunded:
        return Colors.purple;
    }
  }

  Color _getAmountColor(FinancialTransaction transaction) {
    if (transaction.isSuccessful) {
      return Colors.green;
    } else if (transaction.isFailed) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  void _showTransactionDetails(FinancialTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Description', transaction.description),
              _buildDetailRow('Amount', transaction.formattedAmount),
              _buildDetailRow('Status', transaction.status.name.toUpperCase()),
              _buildDetailRow('Category', transaction.category.name.toUpperCase()),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy • HH:mm').format(transaction.createdAt)),
              if (transaction.completedAt != null)
                _buildDetailRow('Completed', DateFormat('MMM dd, yyyy • HH:mm').format(transaction.completedAt!)),
              if (transaction.transactionId != null)
                _buildDetailRow('Transaction ID', transaction.transactionId!),
              if (transaction.paymentGateway != null)
                _buildDetailRow('Payment Gateway', transaction.paymentGateway!),
              if (transaction.failureReason != null)
                _buildDetailRow('Failure Reason', transaction.failureReason!),
              if (transaction.refundedAmount != null)
                _buildDetailRow('Refunded Amount', '\$${transaction.refundedAmount!.toStringAsFixed(2)}'),
              if (transaction.receiptUrl != null)
                _buildDetailRow('Receipt', 'View Receipt', isLink: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (transaction.isSuccessful && !transaction.isRefunded)
            ElevatedButton(
              onPressed: () => _showRefundDialog(transaction),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Refund', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
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
          Expanded(
            child: isLink
                ? GestureDetector(
                    onTap: () {
                      // Open receipt URL
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening receipt...')),
                      );
                    },
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(FinancialTransaction transaction) {
    Navigator.pop(context); // Close details dialog
    
    showDialog(
      context: context,
      builder: (context) => RefundDialog(
        transaction: transaction,
        onRefunded: () {
          Navigator.pop(context);
          _loadTransactions();
        },
      ),
    );
  }
}

class RefundDialog extends StatefulWidget {
  final FinancialTransaction transaction;
  final VoidCallback onRefunded;

  const RefundDialog({
    super.key,
    required this.transaction,
    required this.onRefunded,
  });

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.transaction.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refund Transaction'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transaction: ${widget.transaction.description}'),
            Text('Original Amount: ${widget.transaction.formattedAmount}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Refund Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter refund amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > widget.transaction.amount) {
                  return 'Refund amount cannot exceed original amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _processRefund,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Process Refund', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _processRefund() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      await PaymentService.refundTransaction(
        transactionId: widget.transaction.id,
        refundAmount: amount,
        reason: 'Manual refund',
      );

      widget.onRefunded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refund processed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing refund: $e'),
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
