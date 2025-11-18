import 'package:flutter/material.dart';
import '../../model/parking_slot.dart';
import '../payment/payment_screen.dart';
import '../../services/session_service.dart';

/// Clean, single implementation of the reserve slot screen.
class ReserveSlotScreen extends StatefulWidget {
  final ParkingSlot selectedSlot;

  const ReserveSlotScreen({super.key, required this.selectedSlot});

  @override
  _ReserveSlotScreenState createState() => _ReserveSlotScreenState();
}

class _ReserveSlotScreenState extends State<ReserveSlotScreen> {
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTime = _roundTime(DateTime.now());
    _endTime = _startTime.add(const Duration(hours: 2));
  }

  DateTime _roundTime(DateTime dt) {
    return dt.subtract(Duration(minutes: dt.minute % 5)).add(const Duration(minutes: 5));
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final DateTime initialDate = isStart ? _startTime : _endTime;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

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
        if (_endTime.isBefore(_startTime.add(const Duration(minutes: 30)))) {
          _endTime = _startTime.add(const Duration(minutes: 30));
        }
      } else {
        if (newDateTime.isAfter(_startTime)) {
          _endTime = newDateTime;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time.')));
        }
      }
    });
  }

          double _calculateDurationInHours() {
            final duration = _endTime.difference(_startTime);
            final hours = duration.inMinutes / 60.0;
            return hours.ceilToDouble();
          }

          double _calculateTotalFee(double hours) {
            return hours * widget.selectedSlot.ratePerHour;
          }

          void _confirmReservation() async {
            if (_endTime.isBefore(_startTime)) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid duration.')));
              return;
            }

            setState(() {
              _isLoading = true;
            });

            try {
              final userId = await SessionService.getUserId();
              if (userId == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in. Please login again.'), backgroundColor: Colors.red));
                setState(() {
                  _isLoading = false;
                });
                return;
              }

              final hours = _calculateDurationInHours();
              final amount = _calculateTotalFee(hours);

              if (!mounted) return;

              Navigator.of(context).push(MaterialPageRoute(builder: (context) => PaymentScreen(reservationDetails: {
                    'userId': userId,
                    'slotId': int.parse(widget.selectedSlot.id),
                    'slotName': widget.selectedSlot.name,
                    'fee': amount,
                    'startTime': _startTime.toIso8601String(),
                    'endTime': _endTime.toIso8601String(),
                    'duration': hours,
                  })));
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
              appBar: AppBar(
                title: const Text('Reserve Parking Slot'),
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Slot Information Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_parking, color: Color(0xFF1E88E5), size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Slot',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.selectedSlot.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rate: \$${widget.selectedSlot.ratePerHour.toStringAsFixed(2)}/hr',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Duration Selection
                    Text(
                      'Select Parking Duration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Check-in Time
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.login, color: Color(0xFF1E88E5)),
                        title: const Text('Check-in Time'),
                        subtitle: Text('${_startTime.toString().substring(0, 16)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => _selectTime(context, true),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Check-out Time
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Color(0xFF1E88E5)),
                        title: const Text('Check-out Time'),
                        subtitle: Text('${_endTime.toString().substring(0, 16)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => _selectTime(context, false),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Reservation Summary
                    Text(
                      'Reservation Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3F2FD), width: 2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryRow('Duration (Charged):', '${hours.toStringAsFixed(1)} hours'),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Rate per Hour:', '\$${widget.selectedSlot.ratePerHour.toStringAsFixed(2)}'),
                          const Divider(thickness: 2, height: 20),
                          _buildSummaryRow(
                            'Estimated Total Fee:',
                            '\$${totalFee.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5))))
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _confirmReservation,
                              icon: const Icon(Icons.payment),
                              label: const Text(
                                'Proceed to Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
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
                      color: isTotal ? Theme.of(context).colorScheme.secondary : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }
        }
