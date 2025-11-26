import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/login_screen.dart';
import '../../services/platform_base_api_service.dart';

class ManageCheckInOutScreen extends StatefulWidget {
  const ManageCheckInOutScreen({super.key});

  @override
  State<ManageCheckInOutScreen> createState() => _ManageCheckInOutScreenState();
}

class _ManageCheckInOutScreenState extends State<ManageCheckInOutScreen> {
  late Future<List<dynamic>> _checkInOutFuture;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _checkInOutFuture = _fetchCheckInOut();
  }

  Future<List<dynamic>> _fetchCheckInOut() async {
    final url = Uri.parse('${BaseApiService.baseUrl}checkinout/all');
    try {
      final httpResponse = await http.get(url);
      if (httpResponse.statusCode == 200) {
        final List<dynamic> data = List.from(jsonDecode(httpResponse.body));
        return data;
      } else {
        throw Exception('Failed to load records');
      }
    } catch (e) {
      throw Exception('Failed to load records: $e');
    }
  }

  Future<void> _createCheckIn(int reservationId) async {
    final url = Uri.parse('${BaseApiService.baseUrl}checkinout/create');
    try {
      final httpResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reservation_id': reservationId}),
      );

      if (httpResponse.statusCode == 200) {
        setState(() {
          _checkInOutFuture = _fetchCheckInOut();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check-in record created successfully!')),
          );
        }
      } else {
        throw Exception('Failed to create check-in record');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _checkIn(int checkId) async {
    final url = Uri.parse('${BaseApiService.baseUrl}checkinout/checkin/$checkId');
    try {
      final httpResponse = await http.put(url, headers: {'Content-Type': 'application/json'});

      if (httpResponse.statusCode == 200) {
        setState(() {
          _checkInOutFuture = _fetchCheckInOut();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle checked in successfully!')),
          );
        }
      } else {
        throw Exception('Failed to check in');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _checkOut(int checkId) async {
    final url = Uri.parse('${BaseApiService.baseUrl}checkinout/checkout/$checkId');
    try {
      final httpResponse = await http.put(url, headers: {'Content-Type': 'application/json'});

      if (httpResponse.statusCode == 200) {
        setState(() {
          _checkInOutFuture = _fetchCheckInOut();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle checked out successfully!')),
          );
        }
      } else {
        throw Exception('Failed to check out');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteRecord(int checkId) async {
    final url = Uri.parse('${BaseApiService.baseUrl}checkinout/delete/$checkId');
    try {
      final httpResponse = await http.delete(url);

      if (httpResponse.statusCode == 200) {
        setState(() {
          _checkInOutFuture = _fetchCheckInOut();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted successfully!')),
          );
        }
      } else {
        throw Exception('Failed to delete record');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDeleteConfirmDialog(int checkId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Record'),
          content: Text('Are you sure you want to delete the record for $userName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteRecord(checkId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'Not yet';
    try {
      final dt = DateTime.parse(time);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.month}/${dt.day}';
    } catch (e) {
      return time;
    }
  }

  Widget _buildStatusIndicator(String? checkInTime, String? checkOutTime) {
    if (checkOutTime != null && checkOutTime.isNotEmpty) {
      return _buildStatusBadge('Checked Out', Colors.green);
    } else if (checkInTime != null && checkInTime.isNotEmpty) {
      return _buildStatusBadge('Checked In', Colors.orange);
    } else {
      return _buildStatusBadge('Pending', Colors.blue);
    }
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  List<dynamic> _getFilteredRecords(List<dynamic> records) {
    if (_selectedFilter == 'pending') {
      return records.where((r) => (r['check_in_time'] == null || r['check_in_time'].toString().isEmpty)).toList();
    } else if (_selectedFilter == 'checked_in') {
      return records.where((r) {
        final checkIn = r['check_in_time'];
        final checkOut = r['check_out_time'];
        return checkIn != null && checkIn.toString().isNotEmpty && (checkOut == null || checkOut.toString().isEmpty);
      }).toList();
    } else if (_selectedFilter == 'checked_out') {
      return records.where((r) => (r['check_out_time'] != null && r['check_out_time'].toString().isNotEmpty)).toList();
    }
    return records;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In / Check-Out Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _checkInOutFuture = _fetchCheckInOut())),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('pending', 'Pending'),
                  _buildFilterChip('checked_in', 'Checked In'),
                  _buildFilterChip('checked_out', 'Checked Out'),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _checkInOutFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No records available'));
                } else {
                  final records = _getFilteredRecords(snapshot.data!);
                  if (records.isEmpty) {
                    return Center(child: Text('No $_selectedFilter records'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final checkId = record['check_id'] ?? 0;
                      final checkInTime = record['check_in_time'];
                      final checkOutTime = record['check_out_time'];
                      final userName = record['username'] ?? 'Unknown';
                      final vehicleType = record['vehicle_type'] ?? 'N/A';
                      final slotNumber = record['slot_number'] ?? 'N/A';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$userName — $vehicleType', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                  _buildStatusIndicator(checkInTime, checkOutTime),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Check-In:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(_formatTime(checkInTime), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Check-Out:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(_formatTime(checkOutTime), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Slot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(slotNumber, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (checkInTime == null || checkInTime.toString().isEmpty)
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _checkIn(checkId),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                        child: const Text('Check-In'),
                                      ),
                                    ),
                                  if (checkInTime != null &&
                                      checkInTime.toString().isNotEmpty &&
                                      (checkOutTime == null || checkOutTime.toString().isEmpty))
                                    const SizedBox(width: 8),
                                  if (checkInTime != null &&
                                      checkInTime.toString().isNotEmpty &&
                                      (checkOutTime == null || checkOutTime.toString().isEmpty))
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _checkOut(checkId),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        child: const Text('Check-Out'),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showDeleteConfirmDialog(checkId, userName),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedFilter = value),
        selectedColor: Colors.blue.shade200,
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}
