import 'package:flutter/material.dart';
import '../user/feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock User Data (Replace with data fetched from API: GET /api/user/{id})
  Map<String, String> _userData = {
    'name': 'Alex Johnson',
    'email': 'alex.johnson@app.com',
    'phone': '555-123-4567',
    'licensePlate': 'ABC 123',
  };

  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = _userData['name']!;
    _phoneController.text = _userData['phone']!;
    _plateController.text = _userData['licensePlate']!;
  }

  void _saveProfile() async {
    // **TODO: API Call: PUT /api/user/{id}**
    setState(() {
      _isEditing = false;
      _userData['name'] = _nameController.text;
      _userData['phone'] = _phoneController.text;
      _userData['licensePlate'] = _plateController.text;
    });

    // Simulate API save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  void _logout() {
    // **TODO: Clear local authentication token and navigate to LoginScreen**
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Usually navigate to a dedicated LogoutScreen or directly to LoginScreen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('You have been logged out.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // User Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _buildEditableField(
                      'Name',
                      _nameController,
                      editable: _isEditing,
                    ),
                    _buildInfoRow(
                      'Email',
                      _userData['email']!,
                      isEditable: false,
                    ),
                    _buildEditableField(
                      'Phone',
                      _phoneController,
                      keyboardType: TextInputType.phone,
                      editable: _isEditing,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Vehicle Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _buildEditableField(
                      'License Plate',
                      _plateController,
                      editable: _isEditing,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Action Items
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Reservation History'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // **TODO: Navigate to HistoryScreen**
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigating to Reservation History...'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.purple),
              title: const Text('Submit Feedback'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // **Navigate to FeedbackScreen**
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
            const Divider(),

            const SizedBox(height: 40),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    required bool editable,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: editable
          ? TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            )
          : _buildInfoRow(label, controller.text, isEditable: true),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
