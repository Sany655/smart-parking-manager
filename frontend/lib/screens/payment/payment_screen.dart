import 'package:flutter/material.dart';
import '../payment/confirmation_receipt_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// NOTE: Placeholder for the next screen in the flow
// class ConfirmationReceiptScreen extends StatelessWidget {
//   final Map<String, dynamic> reservationData;
//   const ConfirmationReceiptScreen({super.key, required this.reservationData});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Receipt')),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.check_circle_outline,
//                 color: Colors.green,
//                 size: 80,
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Payment Successful!',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 'Your booking for ${reservationData['slotName']} is confirmed.',
//                 style: const TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: () {
//                   // Navigate back to the home screen (ViewSlotsScreen) or a Dashboard
//                   Navigator.of(context).popUntil((route) => route.isFirst);
//                 },
//                 child: const Text('Go to Home'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> reservationDetails;

  // Example of details received from ReserveSlotScreen
  // {'slotName': 'Level A, Slot 1', 'fee': 15.00}
  const PaymentScreen({super.key, required this.reservationDetails});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Controllers (Simplified for simulation)
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

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Make reservation API call
        final url = Uri.parse('http://localhost:3000/reservation/create');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.reservationDetails['userId'],
            'slot_id': widget.reservationDetails['slotId'],
            'start_time': widget.reservationDetails['startTime'],
            'end_time': widget.reservationDetails['endTime'],
            'amount': widget.reservationDetails['fee'],
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          // Navigate to ConfirmationReceiptScreen
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
          String errorMsg = 'Failed to create reservation';
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded.containsKey('error')) {
              errorMsg = decoded['error'].toString();
            }
          } catch (_) {}
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }  @override
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
            // 1. Fee Summary Card
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

            // 2. Payment Form
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

            // 3. Pay Button
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
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
