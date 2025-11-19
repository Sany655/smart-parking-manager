import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../reservation/reserve_slot_screen.dart';
import '../../model/parking_slot.dart';
import 'dart:convert';
import '../auth/login_screen.dart'; // Import the previous screen
// import '../reservation/reserve_slot_screen.dart'; // Import the next screen

class ViewSlotsScreen extends StatefulWidget {
  const ViewSlotsScreen({super.key});

  @override
  State<ViewSlotsScreen> createState() => _ViewSlotsScreenState();
}

class _ViewSlotsScreenState extends State<ViewSlotsScreen> {
  late Future<List<ParkingSlot>> _slotsFuture;

  @override
  void initState() {
    super.initState();
    _slotsFuture = _fetchParkingSlots();
  }

  // **SIMULATED API Call: GET /api/parking/slots**
  Future<List<ParkingSlot>> _fetchParkingSlots() async {
    // final url = Uri.parse('http://10.0.2.2:3000/');
    final url = Uri.parse('http://localhost:3000/');
    try {
      final httpResponse = await http.get(url);

      if (httpResponse.statusCode == 200) {
        final List<dynamic> data = List.from(jsonDecode(httpResponse.body));
        return data.map((slot) {
          final dynamic rawPrice = slot['price'];
          double parsedPrice = 12.0;
          if (rawPrice is num) {
            parsedPrice = rawPrice.toDouble();
          } else if (rawPrice is String) {
            parsedPrice = double.tryParse(rawPrice) ?? 12.0;
          }

          return ParkingSlot(
            id: slot['slot_id'].toString(),
            name: slot['location'],
            is_available: slot['is_available'] as int,
            ratePerHour: parsedPrice,
          );
        }).toList();
      } else {
        throw Exception('Failed to load parking slots');
      }
    } catch (e) {
      throw Exception('Failed to load parking slots: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Parking Slots'),
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
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _slotsFuture = _fetchParkingSlots();
              });
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ParkingSlot>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Color(0xFFE74C3C)),
                  const SizedBox(height: 16),
                  Text('Error loading slots: ${snapshot.error}'),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No parking slots found.', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          } else {
            final slots = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final available = slot.is_available == 1;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: available ? Colors.white : const Color(0xFFF5F5F5),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: available ? const Color(0xFFE3F2FD) : const Color(0xFFEEEEEE),
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: available ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          available ? Icons.local_parking : Icons.not_interested,
                          color: available ? const Color(0xFF4CAF50) : const Color(0xFFE74C3C),
                          size: 28,
                        ),
                      ),
                      title: Text(
                        slot.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Rate: \$${slot.ratePerHour.toStringAsFixed(2)}/hr',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      trailing: available
                          ? SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ReserveSlotScreen(selectedSlot: slot),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Reserve',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE74C3C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Occupied',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// NOTE: Placeholder for the next screen to satisfy the import and navigation.
// class ReserveSlotScreen extends StatelessWidget {
//   final ParkingSlot selectedSlot;
//   const ReserveSlotScreen({super.key, required this.selectedSlot});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Reserve Slot')),
//       body: Center(
//         child: Text(
//           'Details for ${selectedSlot.name} (Rate: \$${selectedSlot.ratePerHour}/hr)',
//         ),
//       ),
//     );
//   }
// }
