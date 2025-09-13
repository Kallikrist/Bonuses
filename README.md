# Bonuses App

A Flutter application for managing employee bonuses based on sales targets. This app allows store managers (admins) to set daily sales targets and employees to earn points when targets are exceeded.

## Features

### For Employees:
- View assigned daily sales targets and progress
- Submit actual sales amounts for assigned targets
- Track earned points from exceeding sales targets
- Browse and redeem available bonuses
- View points transaction history
- See redeemed bonuses

### For Admins (Store Managers):
- Set daily sales targets (company-wide or assign to specific employees)
- Assign targets to individual employees
- View sales performance and statistics
- Track employee submissions and target completion
- Manage available bonuses
- View comprehensive reports
- Monitor points awarded to employees

## How It Works

1. **Sales Targets**: Admins set daily sales targets and can assign them to specific employees or keep them company-wide
2. **Employee Submission**: Employees submit their actual sales amounts for assigned targets
3. **Points System**: When sales exceed the target by 10% or more, employees earn points automatically
4. **Bonus Redemption**: Employees can redeem points for various bonuses
5. **Real-time Tracking**: All data is stored locally and updates in real-time

## Demo Accounts

The app comes with pre-configured demo accounts:

### Admin Account:
- **Email**: admin@store.com
- **Password**: password123
- **Role**: Store Manager (Admin)

### Employee Accounts:
- **Email**: john@store.com
- **Password**: password123
- **Role**: Employee

- **Email**: jane@store.com
- **Password**: password123
- **Role**: Employee

## Points Calculation

- Points are awarded when daily sales targets are exceeded by 10% or more
- Points are calculated as: `(percentage_above_target / 10) * 10`
- For example: 20% above target = 20 points, 30% above target = 30 points

## Sample Bonuses

The app includes pre-configured bonuses:
- **Free Coffee** - 50 points
- **Extra Break** - 100 points
- **Gift Card** - 200 points
- **Day Off** - 500 points

## Getting Started

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

## Project Structure

```
lib/
├── models/           # Data models
│   ├── user.dart
│   ├── sales_target.dart
│   ├── points_transaction.dart
│   └── bonus.dart
├── screens/          # UI screens
│   ├── login_screen.dart
│   ├── employee_dashboard.dart
│   └── admin_dashboard.dart
├── services/         # Business logic
│   ├── storage_service.dart
│   └── auth_service.dart
├── providers/        # State management
│   └── app_provider.dart
└── main.dart         # App entry point
```

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **SharedPreferences**: Local data storage
- **Material Design 3**: UI components
- **Intl**: Date formatting

## Features Implemented

✅ User authentication with role-based access  
✅ Sales target management with employee assignment  
✅ Employee sales submission system  
✅ Points calculation system  
✅ Bonus management and redemption  
✅ Real-time data persistence  
✅ Employee dashboard with points tracking  
✅ Admin dashboard with comprehensive management  
✅ Individual employee target tracking  
✅ Submission status monitoring  
✅ Responsive UI with Material Design 3  

## Future Enhancements

- Push notifications for new targets and bonuses
- Team-based competitions
- Advanced analytics and reporting
- Integration with external sales systems
- Multi-store support
- Employee performance rankings

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.