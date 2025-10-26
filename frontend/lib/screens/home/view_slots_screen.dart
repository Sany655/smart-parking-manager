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
        return data
            .map(
              (slot) => ParkingSlot(
                id: slot['slot_id'].toString(),
                name: slot['location'],
                is_available: slot['is_available'] as int,
                //   ratePerHour: (slot['ratePerHour'] as num).toDouble(),
                ratePerHour: 12.0, // Placeholder rate
              ),
            )
            .toList();
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
        actions: [
          ElevatedButton(
            onPressed: () {
              // Navigate back to LoginScreen
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _slotsFuture = _fetchParkingSlots(); // Re-fetch data
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ParkingSlot>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading slots: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No parking slots found.'));
          } else {
            // Data loaded successfully
            final slots = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                return Card(
                  color: slot.is_available == 1
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Icon(
                      slot.is_available == 1
                          ? Icons.local_parking
                          : Icons.not_interested,
                      color: slot.is_available == 1 ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      slot.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Rate: \$${slot.ratePerHour.toStringAsFixed(2)}/hr',
                    ),
                    trailing: slot.is_available == 1
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReserveSlotScreen(selectedSlot: slot),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text(
                              'Reserve',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : const Text(
                            'Occupied',
                            style: TextStyle(color: Colors.red),
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
