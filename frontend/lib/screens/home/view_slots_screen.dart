import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../reservation/reserve_slot_screen.dart';
import '../../model/parking_slot.dart';
import 'dart:convert';
import '../auth/login_screen.dart';
import '../../services/platform_base_api_service.dart';

class ViewSlotsScreen extends StatefulWidget {
  const ViewSlotsScreen({super.key});

  @override
  State<ViewSlotsScreen> createState() => _ViewSlotsScreenState();
}

class _ViewSlotsScreenState extends State<ViewSlotsScreen> {
  late Future<List<ParkingSlot>> _slotsFuture;
  List<String> _vehicleTypes = ['All'];
  String _selectedVehicleType = 'All';
  final List<String> _availabilityOptions = ['All', 'Available', 'Occupied'];
  String _selectedAvailability = 'All';

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    _slotsFuture = _fetchParkingSlots();
    // After fetching slots, derive unique vehicle types from supportedVehicleTypes
    _slotsFuture.then((slots) {
      final Set<String> types = {};
      for (final slot in slots) {
        for (final t in slot.supportedVehicleTypes) {
          types.add(t);
        }
      }
      setState(() {
        _vehicleTypes = ['All', ...types.toList()];
        if (!_vehicleTypes.contains(_selectedVehicleType)) {
          _selectedVehicleType = 'All';
        }
      });
    }).catchError((_) {
      // keep defaults on error
    });
  }

  // **SIMULATED API Call: GET /api/parking/slots**
  Future<List<ParkingSlot>> _fetchParkingSlots() async {
    // final url = Uri.parse('http://10.0.2.2:3000/');
    final url = Uri.parse('${BaseApiService.baseUrl}');
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

          // Determine supported vehicle types if backend provides them.
          dynamic vt = slot['vehicle_types'] ?? slot['supported_vehicle_types'] ?? slot['supportedVehicleTypes'] ?? slot['vehicle_type'];
          List<String> supported = [];
          if (vt == null) {
            supported = ['Car', 'Motorbike', 'Truck'];
          } else if (vt is List) {
            supported = vt.map((e) => e.toString()).toList();
          } else if (vt is String) {
            supported = vt.toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }
          if (supported.isEmpty) supported = ['Car', 'Motorbike', 'Truck'];

          return ParkingSlot(
            id: slot['slot_id'].toString(),
            name: slot['location'],
            is_available: slot['is_available'] as int,
            ratePerHour: parsedPrice,
            supportedVehicleTypes: supported,
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
                _loadSlots();
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
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedVehicleType,
                        isExpanded: true,
                        items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedVehicleType = v;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 28, color: Colors.grey.shade200),
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAvailability,
                      items: _availabilityOptions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedAvailability = v;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<ParkingSlot>>(
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
                }

                // Apply filters
                final slots = snapshot.data!;
                final filtered = slots.where((slot) {
                  if (_selectedVehicleType != 'All' && !slot.supportedVehicleTypes.contains(_selectedVehicleType)) return false;
                  if (_selectedAvailability == 'Available' && slot.is_available != 1) return false;
                  if (_selectedAvailability == 'Occupied' && slot.is_available == 1) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('No slots match the selected filters.', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final slot = filtered[index];
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rate: \$${slot.ratePerHour.toStringAsFixed(2)}/hr',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Supports: ${slot.supportedVehicleTypes.join(', ')}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: available
                              ? SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Ask the user which vehicle type they want to reserve for
                                      String? chosen = slot.supportedVehicleTypes.isNotEmpty ? slot.supportedVehicleTypes[0] : null;
                                      final result = await showModalBottomSheet<String>(
                                        context: context,
                                        builder: (context) {
                                          String localSelected = chosen ?? 'Car';
                                          return StatefulBuilder(builder: (context, setModalState) {
                                            return Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Select Vehicle Type', style: Theme.of(context).textTheme.titleMedium),
                                                  const SizedBox(height: 12),
                                                  DropdownButton<String>(
                                                    value: localSelected,
                                                    isExpanded: true,
                                                    items: slot.supportedVehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                                    onChanged: (v) {
                                                      if (v == null) return;
                                                      setModalState(() {
                                                        localSelected = v;
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.of(context).pop(localSelected),
                                                        child: const Text('Continue'),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            );
                                          });
                                        },
                                      );

                                      if (result != null && mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ReserveSlotScreen(selectedSlot: slot, vehicleType: result),
                                          ),
                                        );
                                      }
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
              },
            ),
          ),
        ],
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
