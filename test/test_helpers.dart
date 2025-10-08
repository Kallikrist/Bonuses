import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sets up mock for shared_preferences
/// Call this at the beginning of test files that use StorageService
void setupSharedPreferencesMock() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
}
