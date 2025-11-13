import 'package:flutter/material.dart';
import 'slot_management_screen.dart';
import 'manage_feedback_screen.dart';
import 'manage_payment_screen.dart';
import '../parking-attendant/manage_checkinout_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome to Admin Panel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // Slot Management Card
            _buildDashboardCard(
              context: context,
              title: 'Manage Parking Slots',
              description: 'Create, view, and delete parking slots',
              icon: Icons.local_parking,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SlotManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Feedback Management Card
            _buildDashboardCard(
              context: context,
              title: 'Manage Feedback',
              description: 'View and manage user feedback',
              icon: Icons.feedback,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ManageFeedbackScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Payment Management Card
            _buildDashboardCard(
              context: context,
              title: 'Manage Payments',
              description: 'View and manage payment transactions',
              icon: Icons.payment,
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ManagePaymentScreen(),
                  ),
                );
              },
            ),
            // const SizedBox(height: 16),
            // Check-In/Check-Out Management Card
            // _buildDashboardCard(
            //   context: context,
            //   title: 'Manage Check-In/Out',
            //   description: 'Manage vehicle check-in and check-out',
            //   icon: Icons.car_rental,
            //   color: Colors.teal,
            //   onTap: () {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => const ,
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 36,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
