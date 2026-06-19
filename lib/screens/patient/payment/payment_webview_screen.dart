import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for WebView (mobile only)
import 'payment_webview_mobile.dart' if (dart.library.html) 'payment_webview_web_stub.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String transactionId;
  final Map<String, String>? formData;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  final VoidCallback onCancel;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.transactionId,
    this.formData,
    required this.onSuccess,
    required this.onFailure,
    required this.onCancel,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  @override
  void initState() {
    super.initState();
    // On web, this screen should not be used - redirect back
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please use the web payment dialog instead'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // On web, show a simple message and go back
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(
          child: Text('Web payment is handled differently. Redirecting...'),
        ),
      );
    }

    // On mobile, use the actual WebView implementation
    return PaymentWebViewMobile(
      paymentUrl: widget.paymentUrl,
      transactionId: widget.transactionId,
      formData: widget.formData,
      onSuccess: widget.onSuccess,
      onFailure: widget.onFailure,
      onCancel: widget.onCancel,
    );
  }
}
