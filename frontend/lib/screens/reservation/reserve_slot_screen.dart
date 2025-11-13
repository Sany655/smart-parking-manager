import 'dart:convert';

import 'package:flutter/material.dart';
import '../../model/parking_slot.dart';
// Assume ParkingSlot model is accessible
// import '../home/view_slots_screen.dart'; // or wherever it is defined
import '../payment/payment_screen.dart'; // Import the next screen
import 'package:http/http.dart' as http;
import '../../services/session_service.dart';

class ReserveSlotScreen extends StatefulWidget {
  final ParkingSlot selectedSlot;

  ReserveSlotScreen({required this.selectedSlot});

  @override
  _ReserveSlotScreenState createState() => _ReserveSlotScreenState();
}

class _ReserveSlotScreenState extends State<ReserveSlotScreen> {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(
    Duration(hours: 2),
  ); // Default to 2 hours
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure start time is a clean time (e.g., rounded up to the nearest 5 minutes)
    _startTime = _roundTime(DateTime.now());
    _endTime = _startTime.add(Duration(hours: 2));
  }

  // Helper to round time for cleaner selection
  DateTime _roundTime(DateTime dt) {
    return dt
        .subtract(Duration(minutes: dt.minute % 5))
        .add(Duration(minutes: 5));
  }

  // --- Time Picker Logic ---

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final DateTime initialDate = isStart ? _startTime : _endTime;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(
        Duration(hours: 1),
      ), // Cannot book in the past
      lastDate: DateTime.now().add(
        Duration(days: 7),
      ), // Max 1 week advance booking
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            _startTime = newDateTime;
            // Ensure end time is at least 30 minutes after start time
            if (_endTime.isBefore(_startTime.add(Duration(minutes: 30)))) {
              _endTime = _startTime.add(Duration(minutes: 30));
            }
          } else {
            // Ensure end time is after start time
            if (newDateTime.isAfter(_startTime)) {
              _endTime = newDateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('End time must be after start time.')),
              );
            }
          }
        });
      }
    }
  }

  // --- Calculation Logic ---

  double _calculateDurationInHours() {
    final duration = _endTime.difference(_startTime);
    // Convert duration to hours, rounding up to the nearest hour for charging
    // Many parking systems charge per hour or part thereof.
    final hours = duration.inMinutes / 60.0;
    return hours.ceilToDouble();
  }

  double _calculateTotalFee(double hours) {
    return hours * widget.selectedSlot.ratePerHour;
  }

  // --- Reservation Logic ---

  void _confirmReservation() async {
    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid duration.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user_id from saved session
      final userId = await SessionService.getUserId();
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final hours = _calculateDurationInHours();
      final amount = _calculateTotalFee(hours);

      if (!mounted) return;

      // Navigate to PaymentScreen with reservation details
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            reservationDetails: {
              'userId': userId,
              'slotId': int.parse(widget.selectedSlot.id),
              'slotName': widget.selectedSlot.name,
              'fee': amount,
              'startTime': _startTime.toIso8601String(),
              'endTime': _endTime.toIso8601String(),
              'duration': hours,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hours = _calculateDurationInHours();
    final totalFee = _calculateTotalFee(hours);

    return Scaffold(
      appBar: AppBar(title: Text('Reserve Parking Slot')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Selected Slot Card
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: Icon(Icons.local_parking, color: Colors.blue),
                title: Text(
                  'Selected Slot: ${widget.selectedSlot.name}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Rate: \$${widget.selectedSlot.ratePerHour.toStringAsFixed(2)} per hour',
                ),
              ),
            ),
            SizedBox(height: 24),

            // 2. Time Selection
            Text(
              'Select Parking Duration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            // Start Time Picker
            ListTile(
              leading: Icon(Icons.login),
              title: Text('Check-in Time'),
              subtitle: Text('${_startTime.toString().substring(0, 16)}'),
              trailing: Icon(Icons.edit),
              onTap: () => _selectTime(context, true),
            ),
            Divider(),

            // End Time Picker
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Check-out Time'),
              subtitle: Text('${_endTime.toString().substring(0, 16)}'),
              trailing: Icon(Icons.edit),
              onTap: () => _selectTime(context, false),
            ),

            SizedBox(height: 32),

            // 3. Cost Summary
            Text(
              'Reservation Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            _buildSummaryRow(
              'Duration (Charged):',
              '${hours.toStringAsFixed(1)} hours',
            ),
            _buildSummaryRow(
              'Rate per Hour:',
              '\$${widget.selectedSlot.ratePerHour.toStringAsFixed(2)}',
            ),
            Divider(thickness: 2),
            _buildSummaryRow(
              'Estimated Total Fee:',
              '\$${totalFee.toStringAsFixed(2)}',
              isTotal: true,
            ),

            SizedBox(height: 48),

            // 4. Confirm Button
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _confirmReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.infinity, 55),
                    ),
                    child: Text(
                      'Proceed to Payment',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
