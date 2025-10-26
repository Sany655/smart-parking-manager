import 'package:flutter/material.dart';
import '../payment/confirmation_receipt_screen.dart';

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

      // **TODO: API Call: POST /api/payment/process**
      // In a real app, this integrates with a payment gateway (Stripe, PayPal, etc.)
      // Payload would include: reservation ID, amount, payment token (from gateway)
      await Future.delayed(
        const Duration(seconds: 3),
      ); // Simulate payment processing delay

      setState(() {
        _isLoading = false;
      });

      // On success: Navigate to ConfirmationReceiptScreen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConfirmationReceiptScreen(
            reservationData: {
              ...widget.reservationDetails,
              'transactionId': 'TXN123456789',
              'timeProcessed': DateTime.now().toString(),
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fee = widget.reservationDetails['fee'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Fee Summary Card
            Card(
              color: Colors.blue.shade100,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount Due:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '\$${fee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Payment Form
            const Text(
              'Credit Card Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Card Number
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
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
                          decoration: const InputDecoration(
                            labelText: 'MM/YY',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 5,
                          validator: (v) =>
                              (v?.length ?? 0) < 5 ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 3,
                          obscureText: true,
                          validator: (v) =>
                              (v?.length ?? 0) < 3 ? '3 digits required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card Holder Name
                  TextFormField(
                    controller: _cardHolderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Card Holder Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // 3. Pay Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: Text(
                      'Pay \$${fee.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
