import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../payment/confirmation_receipt_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> reservationDetails;

  const PaymentScreen({super.key, required this.reservationDetails});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _cardNumberController = TextEditingController(
    text: '4111222233334444',
  );
  final TextEditingController _expiryController = TextEditingController(
    text: '12/26',
  );
  final TextEditingController _cvvController = TextEditingController(
    text: '123',
  );
  final TextEditingController _cardHolderNameController = TextEditingController(
    text: 'John Doe',
  );

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  String _getApiUrl() {
    // Check if running on web first
    if (kIsWeb) {
      print('Running on Web - Using localhost API');
      return 'http://localhost:3000/reservation/create';
    }
    
    // For mobile platforms
    try {
      if (Platform.isAndroid) {
        print('Running on Android - Using 10.0.2.2 API');
        return 'http://10.0.2.2:3000/reservation/create';
      } else if (Platform.isIOS) {
        print('Running on iOS - Using localhost API');
        return 'http://localhost:3000/reservation/create';
      }
    } catch (e) {
      print('Platform detection failed, using default URL: $e');
    }
    
    // Default fallback
    print('Using default localhost API');
    return 'http://localhost:3000/reservation/create';
  }

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('=== PAYMENT PROCESSING STARTED ===');
        print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
        print('Reservation details: ${widget.reservationDetails}');

        final url = Uri.parse(_getApiUrl());
        print('API URL: $url');

        final requestBody = {
          'user_id': widget.reservationDetails['userId'],
          'slot_id': widget.reservationDetails['slotId'],
          'start_time': widget.reservationDetails['startTime'],
          'end_time': widget.reservationDetails['endTime'],
          'amount': widget.reservationDetails['fee'],
        };
        print('Request body: $requestBody');

        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Connection timeout - Server not responding after 30 seconds');
              },
            );

        print('Response status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');

        if (!mounted) return;

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('✓ Reservation created successfully!');
          print('Reservation ID: ${responseData['reservation_id']}');
          print('Payment ID: ${responseData['payment_id']}');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ConfirmationReceiptScreen(
                reservationData: {
                  ...widget.reservationDetails,
                  'reservation_id': responseData['reservation_id'],
                  'payment_id': responseData['payment_id'],
                  'transactionId': 'TXN${responseData['payment_id']}',
                  'timeProcessed': DateTime.now().toString(),
                },
              ),
            ),
          );
        } else {
          String errorMsg = 'Failed to create reservation (Status: ${response.statusCode})';
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded.containsKey('error')) {
              errorMsg = decoded['error'].toString();
            }
          } catch (_) {
            errorMsg = 'Server error: ${response.body}';
          }

          print('✗ Error response: $errorMsg');
          if (!mounted) return;
          
          _showErrorSnackBar(errorMsg);
        }
      } on TimeoutException catch (e) {
        print('✗ Timeout Exception: $e');
        if (!mounted) return;
        _showErrorSnackBar(
          'Connection timed out!\n\n'
          'Please check:\n'
          '• Server is running (node server.js)\n'
          '• Server is accessible on port 3000'
        );
      } on SocketException catch (e) {
        print('✗ Socket Exception: $e');
        if (!mounted) return;
        _showErrorSnackBar(
          'Cannot connect to server!\n\n'
          'Troubleshooting steps:\n'
          '1. Ensure server is running: node server.js\n'
          '2. Check server console for errors\n'
          '3. Verify port 3000 is not blocked\n'
          '4. For Web: Check CORS settings'
        );
      } on FormatException catch (e) {
        print('✗ Format Exception: $e');
        if (!mounted) return;
        _showErrorSnackBar('Invalid server response format');
      } on http.ClientException catch (e) {
        print('✗ ClientException: $e');
        if (!mounted) return;
        _showErrorSnackBar(
          'Network error!\n\n'
          'Common causes:\n'
          '• Server is not running\n'
          '• Incorrect server URL\n'
          '• CORS issues (for web)\n'
          '• Firewall blocking connection\n\n'
          'Current URL: ${_getApiUrl()}'
        );
      } catch (e) {
        print('✗ Unexpected Exception: $e');
        print('Exception type: ${e.runtimeType}');
        if (!mounted) return;
        _showErrorSnackBar(
          'Unexpected error occurred!\n\n'
          'Error: ${e.toString()}\n'
          'Type: ${e.runtimeType}'
        );
      } finally {
        print('=== PAYMENT PROCESSING ENDED ===\n');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fee = widget.reservationDetails['fee'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
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

            // Fee Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Amount Due',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${fee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Payment Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credit Card Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Card Number
                          TextFormField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Card Number',
                              prefixIcon: const Icon(Icons.credit_card_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                            ),
                            maxLength: 16,
                            validator: (v) => (v?.length ?? 0) < 16
                                ? 'Enter a 16-digit card number'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Expiry and CVV
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.datetime,
                                  decoration: InputDecoration(
                                    labelText: 'MM/YY',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                  ),
                                  maxLength: 5,
                                  validator: (v) =>
                                      (v?.length ?? 0) < 5 ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                  ),
                                  maxLength: 3,
                                  obscureText: true,
                                  validator: (v) =>
                                      (v?.length ?? 0) < 3 ? '3 digits' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Card Holder Name
                          TextFormField(
                            controller: _cardHolderNameController,
                            decoration: InputDecoration(
                              labelText: 'Card Holder Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                            ),
                            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Pay Button
            _isLoading
                ? const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Processing payment...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _processPayment,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(
                        'Pay \$${fee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}