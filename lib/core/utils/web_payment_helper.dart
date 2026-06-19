// Web-specific payment helper
// This file is only imported on web platform
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

@JS('window.open')
external void _windowOpen(String url, String target);

/// Open SSLCommerz payment URL in a new browser tab
void openPaymentUrl(String url) {
  _windowOpen(url, '_blank');
}

/// Legacy function - kept for compatibility
void submitPaymentForm(Map<String, String> formData, String actionUrl) {
  // Just open the URL directly since we now get the proper GatewayPageURL
  openPaymentUrl(actionUrl);
}
