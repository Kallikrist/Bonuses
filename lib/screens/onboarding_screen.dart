import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userPassword = '';
  String _companyName = '';
  String _companyAddress = '';
  String _employeeCount = '';
  final List<String> _selectedFeatures = [];

  final List<String> _employeeCountOptions = [
    '1-10',
    '11-30',
    '31-50',
    '51-100',
    '101-200',
    '201-500',
    '501-1000',
    '1000+',
  ];

  final Map<String, IconData> _featureOptions = {
    'Sales Targets': Icons.track_changes,
    'Points & Rewards': Icons.stars,
    'Bonus Management': Icons.card_giftcard,
    'Employee Management': Icons.people,
    'Workplace Management': Icons.store,
    'Performance Analytics': Icons.analytics,
  };

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Create admin user first (before company)
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final companyId = 'company_${DateTime.now().millisecondsSinceEpoch}';

    final user = User(
      id: userId,
      name: _userName,
      email: _userEmail,
      phoneNumber: _userPhone,
      role: UserRole.admin,
      createdAt: DateTime.now(),
      companyIds: [companyId],
      companyNames: [_companyName],
      primaryCompanyId: companyId,
      companyRoles: {companyId: 'admin'},
      companyPoints: {companyId: 0},
    );

    // Create company with the admin user ID
    final company = Company(
      id: companyId,
      name: _companyName,
      address: _companyAddress,
      contactEmail: _userEmail,
      contactPhone: _userPhone,
      adminUserId: userId,
      createdAt: DateTime.now(),
      employeeCount: _employeeCount,
    );

    // CLEAR ALL EXISTING DATA FIRST to ensure fresh start
    await StorageService.clearAllData();

    // Mark onboarding as complete (before adding data)
    await appProvider.setOnboardingComplete();

    // Add company and user ONLY (no sample data)
    await appProvider.addCompany(company);
    await appProvider.addUser(user);

    // Save the user's password
    await StorageService.savePassword(userId, _userPassword);

    // Set this user as current user directly
    await StorageService.setCurrentUser(user);

    // Initialize the app (will skip sample data since onboarding is complete)
    await appProvider.initialize();

    if (!mounted) return;

    // Navigate to root and let AppWrapper handle routing to admin dashboard
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            if (_currentPage > 0)
              LinearProgressIndicator(
                value: (_currentPage) / 4,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildUserInfoPage(),
                  _buildCompanyInfoPage(),
                  _buildEmployeeCountPage(),
                  _buildFeaturesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Icon
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 80,
                  color: Colors.blue[700],
                ),
                Positioned(
                  top: 40,
                  right: 40,
                  child: Icon(
                    Icons.stars,
                    size: 40,
                    color: Colors.orange[400],
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 50,
                  child: Icon(
                    Icons.people,
                    size: 35,
                    color: Colors.green[400],
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 30,
                  child: Icon(
                    Icons.store,
                    size: 30,
                    color: Colors.purple[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Welcome to Bonuses',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Create your company app and start rewarding your team within seconds',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentPage > 0)
            IconButton(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back),
            ),
          const SizedBox(height: 20),
          const Text(
            'Let\'s get to know you',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            onChanged: (value) => setState(() => _userName = value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'your.email@company.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => setState(() => _userEmail = value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Phone',
              hintText: '+1 (555) 000-0000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) => setState(() => _userPhone = value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            onChanged: (value) => setState(() => _userPassword = value),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _userName.isNotEmpty &&
                      _userEmail.isNotEmpty &&
                      _userPassword.isNotEmpty
                  ? _nextPage
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Next Step',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _previousPage,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(height: 20),
          Text(
            '$_userName, what\'s your company name?',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            decoration: InputDecoration(
              labelText: 'Company Name',
              hintText: 'Enter company name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.business),
            ),
            onChanged: (value) => setState(() => _companyName = value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Company Address (Optional)',
              hintText: 'Enter company address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            onChanged: (value) => setState(() => _companyAddress = value),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _companyName.isNotEmpty ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Next Step',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmployeeCountPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _previousPage,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(height: 20),
          const Text(
            'Great!\nHow many employees do you have?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: _employeeCountOptions.length,
              itemBuilder: (context, index) {
                final option = _employeeCountOptions[index];
                final isSelected = _employeeCount == option;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _employeeCount = option;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _employeeCount.isNotEmpty ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Next Step',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _previousPage,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(height: 20),
          const Text(
            'Let\'s add features to your app',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your selection will help us customize the platform according to your needs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: _featureOptions.length,
              itemBuilder: (context, index) {
                final feature = _featureOptions.keys.elementAt(index);
                final icon = _featureOptions[feature]!;
                final isSelected = _selectedFeatures.contains(feature);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFeatures.remove(feature);
                        } else {
                          _selectedFeatures.add(feature);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color:
                                  isSelected ? Colors.blue[700] : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue[700],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Complete Setup',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
