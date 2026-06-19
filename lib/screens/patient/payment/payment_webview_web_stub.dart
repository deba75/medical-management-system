import 'package:flutter/material.dart';

// Stub implementation for web - WebView is not available on web
// This file is imported when running on web platform

class PaymentWebViewMobile extends StatelessWidget {
  final String paymentUrl;
  final String transactionId;
  final Map<String, String>? formData;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  final VoidCallback onCancel;

  const PaymentWebViewMobile({
    super.key,
    required this.paymentUrl,
    required this.transactionId,
    this.formData,
    required this.onSuccess,
    required this.onFailure,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // This should never be shown on web
    // The parent widget should handle web platform differently
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'WebView is not available on web platform',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Please use the payment link that opens in a new tab',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
