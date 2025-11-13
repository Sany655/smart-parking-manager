import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManagePaymentScreen extends StatefulWidget {
  const ManagePaymentScreen({super.key});

  @override
  State<ManagePaymentScreen> createState() => _ManagePaymentScreenState();
}

class _ManagePaymentScreenState extends State<ManagePaymentScreen> {
  late Future<List<dynamic>> _paymentsFuture;
  String _selectedStatus = 'all'; // Filter option

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _fetchPayments();
  }

  // Fetch all payments from API
  Future<List<dynamic>> _fetchPayments() async {
    final url = Uri.parse('http://localhost:3000/payment/all');
    try {
      final httpResponse = await http.get(url);

      if (httpResponse.statusCode == 200) {
        final List<dynamic> data = List.from(jsonDecode(httpResponse.body));
        return data;
      } else {
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }

  // Update payment status
  Future<void> _updatePaymentStatus(int paymentId, String newStatus) async {
    final url = Uri.parse('http://localhost:3000/payment/update/$paymentId');
    try {
      final httpResponse = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'payment_status': newStatus}),
      );

      if (httpResponse.statusCode == 200) {
        setState(() {
          _paymentsFuture = _fetchPayments();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment status updated successfully!')),
          );
        }
      } else {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment: $e')),
        );
      }
    }
  }

  // Delete payment
  Future<void> _deletePayment(int paymentId) async {
    final url = Uri.parse('http://localhost:3000/payment/delete/$paymentId');
    try {
      final httpResponse = await http.delete(url);

      if (httpResponse.statusCode == 200) {
        setState(() {
          _paymentsFuture = _fetchPayments();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully!')),
          );
        }
      } else {
        throw Exception('Failed to delete payment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting payment: $e')),
        );
      }
    }
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmDialog(int paymentId, double amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Payment'),
          content: Text('Are you sure you want to delete this payment of \$${amount.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePayment(paymentId);
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

  // Build status chip
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'failed':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Filter payments based on selected status
  List<dynamic> _getFilteredPayments(List<dynamic> payments) {
    if (_selectedStatus == 'all') {
      return payments;
    }
    return payments.where((p) => p['payment_status'].toString().toLowerCase() == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _paymentsFuture = _fetchPayments();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('completed', 'Completed'),
                  _buildFilterChip('pending', 'Pending'),
                  _buildFilterChip('failed', 'Failed'),
                ],
              ),
            ),
          ),
          // Payments list
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _paymentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading payments: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No payments available.'));
                } else {
                  final payments = _getFilteredPayments(snapshot.data!);
                  if (payments.isEmpty) {
                    return Center(
                      child: Text('No ${_selectedStatus} payments found.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final paymentId = payment['payment_id'] ?? 0;
                      final amountRaw = payment['amount'];
                      final amount = amountRaw != null ? double.tryParse(amountRaw.toString()) ?? 0.0 : 0.0;
                      final status = payment['payment_status'] ?? 'unknown';
                      final paymentTime = payment['payment_time'] ?? 'Unknown';
                      final userName = payment['username'] ?? 'Unknown User';
                      final reservationId = payment['reservation_id'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with amount and status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${(amount).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Payment ID: $paymentId',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              const Divider(),
                              // Payment details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'User: $userName',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Reservation: $reservationId',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Time: $paymentTime',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Action buttons
                              Row(
                                children: [
                                  if (status.toLowerCase() != 'completed')
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _updatePaymentStatus(paymentId, 'completed');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Mark Complete'),
                                      ),
                                    ),
                                  if (status.toLowerCase() != 'completed')
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showDeleteConfirmDialog(paymentId, amount);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
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
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = value;
          });
        },
        selectedColor: Colors.blue.shade200,
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}
