import 'package:flutter/material.dart';
import 'package:parking_manager/screens/home/view_slots_screen.dart';
// Note: You would use a package like 'qr_flutter' for a real QR code.
// For now, we'll use an icon as a placeholder.

class ConfirmationReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> reservationData;

  // Data expected: {'slotName', 'fee', 'transactionId', 'timeProcessed', 'startTime', 'endTime'}
  const ConfirmationReceiptScreen({super.key, required this.reservationData});

  @override
  Widget build(BuildContext context) {
    final double fee = reservationData['fee'] ?? 0.0;

    String formatTime(String? time) {
      if (time == null) return 'N/A';
      try {
        final dt = DateTime.parse(time);
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} on ${dt.month}/${dt.day}';
      } catch (e) {
        return time.substring(0, 16);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation Receipt'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Success Header
            Container(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reservation Confirmed!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your parking is reserved',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Booking Details Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      'Total Fee Paid:',
                      '\$${fee.toStringAsFixed(2)}',
                      context,
                      isPrimary: true,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      'Check-in Time:',
                      formatTime(reservationData['startTime']),
                      context,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Check-out Time:',
                      formatTime(reservationData['endTime']),
                      context,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),


            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ViewSlotsScreen()),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text(
                'Back to Slots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
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

  Widget _buildDetailRow(String label, String value, BuildContext context, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
            color: isPrimary ? const Color(0xFF1565C0) : const Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }
}
