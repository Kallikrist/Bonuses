import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendar_widget.dart';
import '../models/sales_target.dart';
import '../models/company.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final List<ActionButton> actionButtons;
  final VoidCallback? onProfileTap;
  final List<SalesTarget>? salesTargets;
  final List<Company>? userCompanies;
  final String? currentCompanyId;
  final Function(String companyId)? onCompanyChanged;
  final Function(DateTime selectedDate)? onDateSelected;
  final DateTime? selectedDate;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    this.profileImageUrl,
    required this.actionButtons,
    this.onProfileTap,
    this.salesTargets,
    this.userCompanies,
    this.currentCompanyId,
    this.onCompanyChanged,
    this.onDateSelected,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Profile Picture and Greeting
          _buildProfileSection(context),

          // Company Switcher (if user has multiple companies)
          if (userCompanies != null && userCompanies!.length > 1)
            _buildCompanySwitcher(context),

          const SizedBox(height: 16),

          // Action Buttons Grid
          _buildActionButtonsGrid(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Row(
      children: [
        // Profile Picture
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting and User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTimeBasedGreeting(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                userEmail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsGrid(BuildContext context) {
    return Row(
      children: actionButtons
          .map(
            (button) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildActionButton(context, button),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, ActionButton button) {
    return GestureDetector(
      onTap: () => _handleButtonTap(context, button),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: button.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                button.icon,
                color: button.color,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              button.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleButtonTap(BuildContext context, ActionButton button) {
    // Check if this is a calendar button (first button with calendar icon)
    if (button.icon == Icons.calendar_today ||
        button.label.toLowerCase().contains('calendar')) {
      _showCalendarDialog(context);
    } else {
      // Call the original onTap for other buttons
      button.onTap();
    }
  }

  void _showCalendarDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CalendarPage(
          title: 'Calendar',
          selectedDate: selectedDate ?? DateTime.now(),
          salesTargets: salesTargets,
          onDateSelected: (selectedDate) {
            // Call the callback to update the dashboard's selected date
            onDateSelected?.call(selectedDate);

            // Show confirmation message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Selected date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompanySwitcher(BuildContext context) {
    if (userCompanies == null ||
        userCompanies!.isEmpty ||
        onCompanyChanged == null) {
      return const SizedBox.shrink();
    }

    final currentCompany = userCompanies!.firstWhere(
      (c) => c.id == currentCompanyId,
      orElse: () => userCompanies!.first,
    );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentCompanyId ?? userCompanies!.first.id,
              isDense: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              icon: const Icon(Icons.arrow_drop_down,
                  size: 18, color: Colors.blue),
              items: userCompanies!.map((company) {
                return DropdownMenuItem<String>(
                  value: company.id,
                  child: Text(company.name),
                );
              }).toList(),
              onChanged: (String? newCompanyId) {
                if (newCompanyId != null && newCompanyId != currentCompanyId) {
                  onCompanyChanged!(newCompanyId);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}

class ActionButton {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
