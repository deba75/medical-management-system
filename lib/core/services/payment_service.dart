import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:flutter_sslcommerz/model/SSLCCustomerInfoInitializer.dart';
import 'package:uuid/uuid.dart';
import '../../models/appointment_model.dart';

class PaymentService {
  // SSLCommerz Sandbox Credentials
  static const String storeId = 'debat697c5633b340f';
  static const String storePassword = 'debat697c5633b340f@ssl';
  static const bool isSandbox = true;
  
  // SSLCommerz API URLs (for web fallback)
  static String get baseUrl => isSandbox 
      ? 'https://sandbox.sslcommerz.com' 
      : 'https://securepay.sslcommerz.com';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the SSLCommerz session init URL (for web)
  String get sessionApiUrl => '$baseUrl/gwprocess/v4/api.php';

  /// Check if native SDK payment is supported (Android/iOS only)
  static bool get isNativePaymentSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Process payment using native SSLCommerz SDK (Android/iOS)
  Future<PaymentResult> processNativePayment({
    required BuildContext context,
    required double amount,
    required String patientName,
    required String patientEmail,
    required String patientPhone,
    required String doctorName,
    required String appointmentDate,
  }) async {
    try {
      // Ensure minimum amount (SSLCommerz requires minimum 10 BDT)
      final paymentAmount = amount < 10 ? 10.0 : amount;
      
      // Generate unique transaction ID
      final transactionId =
          'TM${DateTime.now().millisecondsSinceEpoch}${const Uuid().v4().substring(0, 8)}';

      debugPrint('=== SSLCommerz Native SDK ===');
      debugPrint('Store ID: $storeId');
      debugPrint('Amount: $paymentAmount BDT');
      debugPrint('Transaction ID: $transactionId');
      debugPrint('Sandbox Mode: $isSandbox');

      // Initialize SSLCommerz
      Sslcommerz sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          currency: SSLCurrencyType.BDT,
          product_category: "Healthcare",
          sdkType: isSandbox ? SSLCSdkType.TESTBOX : SSLCSdkType.LIVE,
          store_id: storeId,
          store_passwd: storePassword,
          total_amount: paymentAmount,
          tran_id: transactionId,
          multi_card_name: "visa,master,bkash,nagad,rocket",
        ),
      );

      // Add customer information
      sslcommerz.addCustomerInfoInitializer(
        customerInfoInitializer: SSLCCustomerInfoInitializer(
          customerName: patientName,
          customerEmail: patientEmail.isNotEmpty
              ? patientEmail
              : 'patient@mediconnect.com',
          customerAddress1: 'Bangladesh',
          customerCity: 'Dhaka',
          customerPostCode: '1000',
          customerCountry: 'Bangladesh',
          customerPhone: patientPhone,
          customerState: 'Dhaka',
        ),
      );

      // Process payment
      SSLCTransactionInfoModel result = await sslcommerz.payNow();

      // Handle payment result
      if (result.status?.toLowerCase() == 'valid' ||
          result.status?.toLowerCase() == 'validated') {
        return PaymentResult(
          success: true,
          transactionId: result.tranId ?? transactionId,
          message: 'Payment successful!',
          status: result.status,
        );
      } else if (result.status?.toLowerCase() == 'failed') {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Payment failed. Please try again.',
          status: result.status,
        );
      } else if (result.status?.toLowerCase() == 'closed') {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Payment cancelled by user.',
          status: result.status,
        );
      } else {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: result.status ?? 'Payment could not be processed.',
          status: result.status,
        );
      }
    } catch (e) {
      debugPrint('SSLCommerz Payment Error: $e');
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Payment error: ${e.toString()}',
        status: 'error',
      );
    }
  }

  /// Initialize payment by calling SSLCommerz API (Web fallback)
  /// Returns the GatewayPageURL for redirect
  Future<PaymentResult> initializePayment({
    required String patientName,
    required String patientEmail,
    required String patientPhone,
    required String doctorName,
    required double amount,
    required String transactionId,
  }) async {
    try {
      // Prepare request body
      final body = {
        'store_id': storeId,
        'store_passwd': storePassword,
        'total_amount': amount.toStringAsFixed(2),
        'currency': 'BDT',
        'tran_id': transactionId,
        'success_url': 'https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php?tran_type=success',
        'fail_url': 'https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php?tran_type=failure',
        'cancel_url': 'https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php?tran_type=cancel',
        'cus_name': patientName,
        'cus_email': patientEmail,
        'cus_phone': patientPhone,
        'cus_add1': 'Dhaka',
        'cus_city': 'Dhaka',
        'cus_country': 'Bangladesh',
        'shipping_method': 'NO',
        'product_name': 'Consultation with Dr. $doctorName',
        'product_category': 'Healthcare',
        'product_profile': 'general',
      };

      debugPrint('Initializing SSLCommerz payment...');
      debugPrint('Transaction ID: $transactionId');
      debugPrint('Amount: $amount BDT');

      // Call SSLCommerz API
      final response = await http.post(
        Uri.parse(sessionApiUrl),
        body: body,
      );

      debugPrint('SSLCommerz Response Status: ${response.statusCode}');
      debugPrint('SSLCommerz Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'SUCCESS') {
          final gatewayUrl = data['GatewayPageURL'] as String?;
          final sessionKey = data['sessionkey'] as String?;
          
          if (gatewayUrl != null && gatewayUrl.isNotEmpty) {
            debugPrint('Payment gateway URL: $gatewayUrl');
            return PaymentResult(
              success: true,
              message: 'Payment initialized successfully',
              gatewayUrl: gatewayUrl,
              sessionKey: sessionKey,
              transactionId: transactionId,
            );
          } else {
            return PaymentResult(
              success: false,
              message: 'No gateway URL received from SSLCommerz',
            );
          }
        } else {
          final failedReason = data['failedreason'] ?? 'Unknown error';
          debugPrint('SSLCommerz failed: $failedReason');
          return PaymentResult(
            success: false,
            message: 'Payment initialization failed: $failedReason',
          );
        }
      } else {
        return PaymentResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Payment initialization error: $e');
      return PaymentResult(
        success: false,
        message: 'Payment error: ${e.toString()}',
      );
    }
  }

  /// Update appointment payment status in Firestore
  Future<void> updatePaymentStatus({
    required String appointmentId,
    required PaymentStatus status,
    String? transactionId,
    DateTime? paymentDate,
  }) async {
    final updateData = <String, dynamic>{
      'paymentStatus': status.name,
    };

    if (transactionId != null) {
      updateData['transactionId'] = transactionId;
    }

    if (paymentDate != null) {
      updateData['paymentDate'] = paymentDate.toIso8601String();
    }

    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .update(updateData);
  }

  /// Generate a unique transaction ID
  String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'TM${timestamp}${const Uuid().v4().substring(0, 8)}';
  }
  
  /// Validate transaction (for IPN callback - optional)
  Future<bool> validateTransaction(String transactionId) async {
    // In production, you would validate the transaction with SSLCommerz API
    // For now, we just return true
    return true;
  }
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String message;
  final String? gatewayUrl;
  final String? sessionKey;
  final String? transactionId;
  final String? bankTransactionId;
  final String? cardType;
  final double? amount;
  final Map<String, String>? formData;
  final String? status;

  PaymentResult({
    required this.success,
    required this.message,
    this.gatewayUrl,
    this.sessionKey,
    this.transactionId,
    this.bankTransactionId,
    this.cardType,
    this.amount,
    this.formData,
    this.status,
  });
}
