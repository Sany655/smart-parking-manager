import 'package:flutter/material.dart';
// Note: You would use a package like 'qr_flutter' for a real QR code.
// For now, we'll use an icon as a placeholder.

class ConfirmationReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> reservationData;

  // Data expected: {'slotName', 'fee', 'transactionId', 'timeProcessed', 'startTime', 'endTime'}
  const ConfirmationReceiptScreen({super.key, required this.reservationData});

  @override
  Widget build(BuildContext context) {
    final double fee = reservationData['fee'] ?? 0.0;
    final String bookingId = reservationData['transactionId'] ?? 'N/A';

    // Convert time strings to readable format if they exist
    // (Assuming you pass DateTime objects or clear format strings from previous screens)
    String formatTime(String? time) {
      if (time == null) return 'N/A';
      try {
        final dt = DateTime.parse(time);
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} on ${dt.month}/${dt.day}';
      } catch (e) {
        return time.substring(0, 16); // Fallback to partial string
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation Receipt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Success Header
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Reservation Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Booking Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Booking ID:', bookingId),
                    const Divider(),
                    _buildDetailRow(
                      'Parking Slot:',
                      reservationData['slotName'] ?? 'N/A',
                      isPrimary: true,
                    ),
                    _buildDetailRow(
                      'Total Fee Paid:',
                      '\$${fee.toStringAsFixed(2)}',
                      isPrimary: true,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Check-in Time:',
                      formatTime(reservationData['startTime']),
                    ),
                    _buildDetailRow(
                      'Check-out Time:',
                      formatTime(reservationData['endTime']),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 3. QR Code (Placeholder)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Scan this QR code at the entry gate:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 100,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookingId,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 4. Action Button
            ElevatedButton(
              onPressed: () {
                // Pop all routes until the home screen (ViewSlotsScreen or a dedicated dashboard)
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Optionally navigate specifically to the Track Status screen if it's not the first route
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Go to Home/Dashboard',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              color: isPrimary ? Colors.black : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
