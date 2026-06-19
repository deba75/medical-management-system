// Stub for non-web platforms
// This file is imported on mobile platforms where dart:html is not available

/// Stub implementation - does nothing on mobile (mobile uses WebView)
void openPaymentUrl(String url) {
  // This should never be called on mobile - mobile uses WebView instead
  throw UnsupportedError('openPaymentUrl is only available on web platform');
}

/// Legacy stub - kept for compatibility
void submitPaymentForm(Map<String, String> formData, String actionUrl) {
  throw UnsupportedError('submitPaymentForm is only available on web platform');
}
