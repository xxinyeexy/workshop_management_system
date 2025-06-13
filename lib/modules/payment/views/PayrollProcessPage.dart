import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/payment/services/stripe_service.dart';

class PayrollProcessPage extends StatefulWidget {
  final int amount;
  final String currency;

  const PayrollProcessPage({
    super.key,
    required this.amount,
    required this.currency,
  });

  @override
  State<PayrollProcessPage> createState() => _PayrollProcessPageState();
}

class _PayrollProcessPageState extends State<PayrollProcessPage> {
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  Future<void> _startPayment() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    bool success = await StripeService.instance.makePayment(
      amount: widget.amount,
      currency: widget.currency,
    );

    setState(() {
      _isProcessing = false;
      _statusMessage = success
          ? "✅ Payment successful!"
          : "❌ Payment failed or canceled.";
    });

    if (success) {
      // You could navigate back or forward to a confirmation page
      // Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payroll Payment")),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : Text(
                _statusMessage ?? "Ready to process payment.",
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
