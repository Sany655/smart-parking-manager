// Usage Examples for SessionService

// 1. Save user data after login
import 'services/session_service.dart';

// In login_screen.dart - after successful login API response:
final decoded = jsonDecode(httpResponse.body);
await SessionService.saveUserData(decoded['user']);

// 2. Retrieve user ID (e.g., in reservation screen)
final userId = await SessionService.getUserId();

// 3. Retrieve other user information
final email = await SessionService.getEmail();
final username = await SessionService.getUsername();
final vehicleNumber = await SessionService.getVehicleNumber();

// 4. Get entire user object
final userData = await SessionService.getUserData();

// 5. Check if user is logged in
final loggedIn = await SessionService.isLoggedIn();

// 6. Update a specific field
await SessionService.updateUserField('vehicle_number', 'ABC-1234');

// 7. Clear all user data on logout
await SessionService.clearUserData();

// Example use in screens:
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await SessionService.getEmail();
    setState(() {
      userEmail = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Logged in as: $userEmail'),
      ),
    );
  }
}
