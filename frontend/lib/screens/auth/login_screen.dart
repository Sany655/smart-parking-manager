import 'package:flutter/material.dart';
import '../parking-attendant/attendant_dashboard_screen.dart';
import '../home/view_slots_screen.dart'; // Import the next screen
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/registration_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(text: 'admin@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: 'asdfasdf');
  bool _isLoading = false;

  void _login() async {
    // final url = Uri.parse('http://10.0.2.2:3000/auth/login');
    final url = Uri.parse('http://localhost:3000/auth/login');
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // On success: Navigate to ViewSlotsScreen
      if (_emailController.text.isNotEmpty &&
          _passwordController.text.length >= 6) {
        if (!mounted) return; // Safety check

        try {
          final httpResponse = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text,
              'password': _passwordController.text,
            }),
          );

          if (httpResponse.statusCode == 200) {
            if(httpResponse.body.isNotEmpty) {
              final decoded = jsonDecode(httpResponse.body);
              print('Login Successful: $decoded');
              print(decoded['user']['email']);
              
              // Save user data to SharedPreferences
              await SessionService.saveUserData(decoded['user']);
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => decoded['user']['email'] == 'admin@gmail.com' ? AdminDashboardScreen() : decoded['user']['email'] == 'attendant@gmail.com' ? AttendantDashboardScreen() : ViewSlotsScreen()),
              );
            }
          } else {
            if (!mounted) return;
            String errorMsg = 'Login Failed! Check credentials.';
            try {
              final decoded = jsonDecode(httpResponse.body);
              if (decoded is Map && decoded.containsKey('error')) {
                errorMsg = decoded['error'].toString();
              }
            } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
          setState(() {
            _isLoading = false;
          });
        } catch (e) {
          throw Exception('Failed to load parking slots: $e');
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Failed! Check credentials.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking App Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 1. Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (e.g., test@app.com)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (min 6 chars)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 3. Login Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                const SizedBox(height: 16),

                // 4. Registration Link (Dummy)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RegistrationScreen()),
                    );
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
