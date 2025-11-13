import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../reservation/reserve_slot_screen.dart';
import '../../model/parking_slot.dart';
import 'dart:convert';
import '../auth/login_screen.dart'; // Import the previous screen
// import '../reservation/reserve_slot_screen.dart'; // Import the next screen

class SlotManagementScreen extends StatefulWidget {
  const SlotManagementScreen({super.key});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
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

  // **API Call: POST /slot/create**
  Future<void> _createSlot(String slotNumber, String location, bool isAvailable) async {
    final url = Uri.parse('http://localhost:3000/slot/create');
    try {
      final httpResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'slot_number': slotNumber,
          'location': location,
          'is_available': isAvailable ? 1 : 0,
        }),
      );

      if (httpResponse.statusCode == 200) {
        // Refresh the slots list
        setState(() {
          _slotsFuture = _fetchParkingSlots();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parking slot created successfully!')),
          );
        }
      } else {
        throw Exception('Failed to create parking slot');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating slot: $e')),
        );
      }
    }
  }

  // **API Call: DELETE /slot/delete**
  Future<void> _deleteSlot(String slotId) async {
    final url = Uri.parse('http://localhost:3000/slot/delete/$slotId');
    try {
      final httpResponse = await http.delete(url);

      if (httpResponse.statusCode == 200) {
        // Refresh the slots list
        setState(() {
          _slotsFuture = _fetchParkingSlots();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parking slot deleted successfully!')),
          );
        }
      } else {
        throw Exception('Failed to delete parking slot');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting slot: $e')),
        );
      }
    }
  }

  // Show confirm delete dialog
  void _showDeleteConfirmDialog(String slotId, String slotName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Parking Slot'),
          content: Text('Are you sure you want to delete slot "$slotName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSlot(slotId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Show create slot dialog
  void _showCreateSlotDialog() {
    final slotNumberController = TextEditingController();
    final locationController = TextEditingController();
    bool isAvailable = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Parking Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: slotNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Slot Number',
                        hintText: 'e.g., A1, B5, C10',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g., Ground Floor, Building A',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Available'),
                      value: isAvailable,
                      onChanged: (value) {
                        setDialogState(() {
                          isAvailable = value ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (slotNumberController.text.isEmpty ||
                        locationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                        ),
                      );
                      return;
                    }
                    _createSlot(
                      slotNumberController.text,
                      locationController.text,
                      isAvailable,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Parking Slots'),
        actions: [
          ElevatedButton(
            onPressed: () {
              _showCreateSlotDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Slot'),
          ),
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
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      slot.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Rate: \$${slot.ratePerHour.toStringAsFixed(2)}/hr',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmDialog(slot.id, slot.name);
                      },
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
