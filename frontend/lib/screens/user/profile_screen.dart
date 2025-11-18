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
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit_outlined),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E88E5), width: 3),
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      color: Color(0xFF1E88E5),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData['name']!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData['email']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // User Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 12),
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
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
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car_outlined, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 12),
                        Text(
                          'Vehicle Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildEditableField(
                      'License Plate',
                      _plateController,
                      editable: _isEditing,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Action Items
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, color: Color(0xFF1E88E5), size: 20),
              ),
              title: const Text('Reservation History', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigating to Reservation History...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.feedback_outlined, color: Color(0xFF1E88E5), size: 20),
              ),
              title: const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                minimumSize: const Size(double.infinity, 54),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
