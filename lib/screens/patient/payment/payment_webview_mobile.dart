import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class PaymentWebViewMobile extends StatefulWidget {
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
  State<PaymentWebViewMobile> createState() => _PaymentWebViewMobileState();
}

class _PaymentWebViewMobileState extends State<PaymentWebViewMobile> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
            setState(() => _isLoading = false);
            _checkPaymentStatus(url);
          },
          onProgress: (int progress) {
            setState(() => _progress = progress / 100);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigating to: ${request.url}');
            _checkPaymentStatus(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      );

    // Load the SSLCommerz payment gateway URL directly
    debugPrint('Loading payment URL: ${widget.paymentUrl}');
    _controller.loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    final lowerUrl = url.toLowerCase();
    
    debugPrint('Checking payment status for URL: $url');
    
    // Check for success URL patterns
    if (lowerUrl.contains('tran_type=success') ||
        lowerUrl.contains('status=valid') ||
        (lowerUrl.contains('validationserverapi') && lowerUrl.contains('success'))) {
      debugPrint('Payment SUCCESS detected!');
      widget.onSuccess();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
    // Check for failure URL patterns
    else if (lowerUrl.contains('tran_type=failure') ||
             lowerUrl.contains('status=failed') ||
             (lowerUrl.contains('validationserverapi') && lowerUrl.contains('fail'))) {
      debugPrint('Payment FAILED detected!');
      widget.onFailure();
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
    // Check for cancel URL patterns
    else if (lowerUrl.contains('tran_type=cancel') ||
             lowerUrl.contains('cancelled')) {
      debugPrint('Payment CANCELLED detected!');
      widget.onCancel();
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel this payment? '
          'Your appointment will not be confirmed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
              Navigator.of(this.context).pop(false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
