# Bonuses App

A comprehensive Flutter application for managing employee bonuses and rewards based on sales targets. This app enables multi-company management with role-based access, allowing store managers (admins) to set daily sales targets, track performance, and reward employees who exceed their goals.

## Features

### For Employees:
- 📊 **Sales Targets**: View assigned daily sales targets with real-time progress tracking
- ✅ **Sales Submission**: Submit actual sales amounts and track completion status
- 🎯 **Team Collaboration**: Join targets as team member or request team changes
- 💰 **Points System**: Earn points automatically when exceeding sales targets
- 🎁 **Bonus Redemption**: Browse and redeem available bonuses from catalog
- 📈 **Performance Analytics**: View weekly performance charts and trends
- 💬 **Messaging**: Send and receive messages with admins and team members
- 📅 **Calendar Integration**: View target history and select specific dates
- 🔔 **Real-time Updates**: Get instant notifications for target assignments and approvals
- 🎨 **Customizable UI**: Personalize header shortcuts and bottom navigation

### For Admins (Store Managers):
- 🎯 **Target Management**: Create daily sales targets with workplace and employee assignments
- 👥 **Team Coordination**: Manage collaborative targets with multiple team members
- ✅ **Approval System**: Review and approve employee sales submissions and team requests
- 📊 **Performance Dashboard**: Track sales performance with interactive charts and statistics
- 🏢 **Multi-Company Support**: Manage multiple companies and workplaces from one account
- 🎁 **Bonus Catalog**: Import and manage bonus offerings for employees
- 💰 **Points Administration**: Award, adjust, or withdraw points with full audit trail
- 🔄 **Automatic Recalculation**: Points automatically adjust when targets are modified
- 💬 **Messaging System**: Communicate with employees directly within the app
- 📈 **Advanced Analytics**: View top performers, weekly trends, and detailed reports
- ⚙️ **Customization**: Configure dashboard layout, navigation, and header shortcuts

## How It Works

1. **🏢 Company Setup**: Create companies and workplaces with unique identifiers
2. **🎯 Target Assignment**: Admins set daily sales targets for specific workplaces and employees
3. **👥 Team Collaboration**: Employees can join targets as team members (with admin approval for submitted targets)
4. **📝 Sales Submission**: Employees submit their actual sales amounts for approval
5. **✅ Approval Workflow**: Admins review and approve submissions or team change requests
6. **💰 Points Calculation**: Points are automatically awarded when sales exceed targets (10%+ threshold)
7. **🔄 Automatic Adjustments**: Points are recalculated if targets are modified or team members are added/removed
8. **🎁 Bonus Redemption**: Employees redeem earned points for bonuses from the catalog
9. **📊 Analytics**: Track performance with charts, trends, and detailed transaction history
10. **💾 Data Persistence**: All data is stored locally with automatic migrations and integrity checks

## Demo Accounts

These match `StorageService.initializeSampleData()` and the login screen Demo Accounts box.
When `SUPABASE_URL` / `SUPABASE_ANON_KEY` are set, login uses Supabase Auth with these same emails and passwords. Payments stay mock while `DEMO_MODE` is true.

### Login-screen accounts
- **Admin Store**: `admin@store.com` / `password123` — Store Manager
- **Admin Utilif**: `admin@utilif.com` / `utilif123` — Utilif Administrator
- **Employee**: `john.doe@example.com` / `password123` — John Doe
- **Super Admin**: `superadmin@platform.com` / `password123` — Platform Administrator

### Additional seeded employees
- `jane.smith@example.com` / `password123` — Jane Smith
- `mike.johnson@example.com` / `password123` — Mike Johnson
- `Karl@Utilif.is` / `password123` — Karl Kristjánsson
- `kallikrist@test.is` / `demo123` — Kalli Krist (TestCompany1)

## Points Calculation

### Earning Points
- Points are awarded when daily sales targets are exceeded by **10% or more**
- Formula: `(percentage_above_target / 10) * 10`
- Examples:
  - 20% above target → 20 points
  - 30% above target → 30 points
  - 50% above target → 50 points

### Team Points Distribution
- For collaborative targets, all team members receive equal points
- Points are calculated based on the total team sales vs. target
- Admin team participation points: 5 points per target joined

### Points Adjustments
- **Automatic Recalculation**: When admin modifies target amount, all member points are recalculated
- **Member Removal**: Points are automatically withdrawn if member is removed from approved target
- **Member Addition**: Points are awarded when member is added to approved target
- **Audit Trail**: All adjustments are logged in transaction history with detailed descriptions

## Sample Bonuses

The app includes pre-configured bonuses:
- **Free Coffee** - 50 points
- **Extra Break** - 100 points
- **Gift Card** - 200 points
- **Day Off** - 500 points

## Getting Started

### Environment Variables Setup

**⚠️ IMPORTANT:** This app requires Supabase credentials to be configured via environment variables.

1. **Copy the example environment file:**
   ```bash
   cp env.example .env
   ```

2. **Edit `.env` and add your Supabase credentials:**
   ```bash
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_actual_anon_key_here
   ```
   Get your credentials from: Supabase Dashboard → Settings → API

3. **Run the app:**
   ```bash
   # Option 1: Use the helper script (recommended)
   ./scripts/run_with_env.sh
   
   # Option 2: Manual with --dart-define flags
   flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy
   ```

For detailed setup instructions, see [SETUP_ENVIRONMENT_VARIABLES.md](SETUP_ENVIRONMENT_VARIABLES.md).

1. **Prerequisites**:
   - Flutter SDK (3.6.0 or higher)
   - Dart SDK
   - Android Studio / VS Code with Flutter extensions

2. **Installation**:
   ```bash
   git clone <repository-url>
   cd Bonuses
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Sign in** with a [Demo Account](#demo-accounts) (`admin@store.com`, `admin@utilif.com`, `john.doe@example.com`, or `superadmin@platform.com`). Those emails are seeded by `initializeSampleData()` and shown on the login screen.

## Project Structure

```
lib/
├── models/                    # Domain models (user, company, targets, points, bonuses, payments, subscriptions, …)
├── screens/                   # Role dashboards (employee, admin, super-admin) plus onboarding, messaging, imports, payments
├── widgets/                   # Splash, calendar, profile header, target card/dialog
├── services/                  # Local storage/auth, Supabase dual-write, validation, notifications, passwords, rate limit
├── providers/                 # AppProvider state
├── utils/                     # Error handling
└── main.dart                  # Supabase/Stripe init, MaterialApp, role routing
```

Auth for the running app is local (`AuthService` + `StorageService`). Persistence is SharedPreferences with a best-effort Supabase dual-write. Payment UI lives under `screens/`; Stripe service sources are local/mock. There is no Firebase.

## Technologies Used

- **Flutter 3.6+**: Cross-platform mobile framework (iOS, Android, macOS, Web)
- **Provider**: State management for reactive UI updates
- **SharedPreferences**: Local data persistence with JSON serialization
- **Material Design 3**: Modern UI components and design language
- **Intl**: Date and number formatting with localization support
- **FL Chart**: Interactive charts for performance analytics
- **UUID**: Unique identifier generation for entities

## Features Implemented

### Core Functionality
✅ **Authentication**: Role-based access control (Admin/Employee)  
✅ **Multi-Company Support**: Manage multiple companies and workplaces  
✅ **Onboarding Flow**: Setup wizard for new companies  
✅ **Branded Splash Screen**: Dynamic company name display on startup  

### Target Management
✅ **Sales Targets**: Daily targets with workplace/employee assignment  
✅ **Team Collaboration**: Multi-member targets with approval workflow  
✅ **Calendar Integration**: Date-based target viewing and persistence  
✅ **Workplace Validation**: One target per workplace per date  
✅ **Target Profiles**: Detailed view with charts, team info, and history  

### Points System
✅ **Automatic Calculation**: Points awarded when targets exceeded by 10%+  
✅ **Team Distribution**: Equal points split for collaborative targets  
✅ **Auto-Recalculation**: Points adjust when targets are modified  
✅ **Points Withdrawal**: Automatic when members removed from targets  
✅ **Audit Trail**: Complete transaction history with detailed descriptions  
✅ **Company ID Guards**: Data integrity validation and recovery  

### Approval System
✅ **Sales Submissions**: Review and approve employee sales reports  
✅ **Team Requests**: Approve/reject team member additions  
✅ **Bulk Approvals**: "Approve All" for multiple pending requests  
✅ **Request Deduplication**: Prevent duplicate approval requests  

### Messaging & Communication
✅ **Direct Messaging**: Employee-to-employee and admin communication  
✅ **Unread Indicators**: Real-time message status tracking  
✅ **Conversation View**: Organized by participants  

### Analytics & Reporting
✅ **Performance Charts**: Weekly trends with FL Chart integration  
✅ **Top Performers**: Leaderboard of highest earners  
✅ **Target History**: 2-year performance tracking in target profiles  
✅ **Points History**: Detailed transaction log with filtering  

### User Experience
✅ **Customizable Navigation**: Configure header shortcuts and bottom bar  
✅ **Expandable Sections**: Collapsible UI sections for cleaner layouts  
✅ **Empty State Styling**: Beautiful placeholders for no-data states  
✅ **Debounce Protection**: Prevent accidental duplicate actions  
✅ **Responsive Design**: Optimized for mobile, tablet, and desktop  

### Admin Tools
✅ **Bonus Management**: Import bonuses from CSV  
✅ **Points Administration**: Manually award/adjust/withdraw points  
✅ **Employee Management**: Add/edit/deactivate users  
✅ **Company Settings**: Manage workplaces and points rules  
✅ **Floating Action Buttons**: Quick access to common actions  

### Data Management
✅ **Local Persistence**: SharedPreferences with JSON serialization  
✅ **Data Migrations**: Automatic schema updates and fixes  
✅ **Company ID Validation**: Integrity checks with recovery  
✅ **Transaction History**: Complete audit trail for all point changes  

### Testing & Quality
✅ **Unit Tests**: 178+ tests covering core functionality  
✅ **Integration Tests**: End-to-end user flow testing  
✅ **CI/CD**: GitHub Actions for automated testing  
✅ **Error Handling**: Comprehensive validation and user feedback  

## Future Enhancements

### High Priority
- 🔔 **Push Notifications**: Real-time alerts for messages, targets, and point gifts
- 📊 **Advanced Analytics**: Custom date ranges, export reports, team comparisons
- 📁 **File Sharing**: Attach files to messages
- 📋 **Target Templates**: Reusable sales goal templates
- 🎯 **Improved Target Management**: Better UI for adding/removing team members

### Technical Improvements
- ⚡ **Performance**: Lazy loading, caching, pagination for large datasets
- 📡 **Offline Support**: Sync capability when connection restored
- 💾 **Data Export/Import**: Backup and restore company data
- 🔐 **Enhanced Security**: Biometric authentication, password policies

### UI/UX Enhancements
- ♿ **Accessibility**: Screen reader support, keyboard navigation
- 🎨 **Theming**: Custom dashboard layouts, color schemes
- 🌍 **Localization**: Multi-language support
- 📱 **Mobile Optimization**: Native iOS/Android specific features

### Integration
- 🔗 **External Sales Systems**: API integration with POS systems
- 📧 **Email Notifications**: Automated reports and reminders
- 📅 **Calendar Sync**: Export targets to external calendars

## Testing

The app includes comprehensive test coverage:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/app_provider_points_test.dart
```

### Test Categories
- **Unit Tests**: Core business logic and state management
- **Widget Tests**: UI components and user interactions
- **Integration Tests**: End-to-end user flows
- **Provider Tests**: State management and data flow

### CI/CD
- GitHub Actions workflow runs all tests on every push
- Automated testing ensures code quality and prevents regressions

## Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository** on GitHub
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** with clear, documented code
4. **Add tests** for new functionality
5. **Run tests**: `flutter test` to ensure everything passes
6. **Commit your changes**: `git commit -m 'Add amazing feature'`
7. **Push to your branch**: `git push origin feature/amazing-feature`
8. **Open a Pull Request** with a clear description

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write meaningful commit messages
- Add comments for complex logic
- Update README for new features
- Ensure all tests pass before submitting PR

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests:
- 🐛 **Bug Reports**: Open an issue on GitHub
- 💡 **Feature Requests**: Create an issue with the "enhancement" label
- 📧 **Contact**: Reach out to the development team

## Acknowledgments

Built with ❤️ using Flutter and modern mobile development best practices.