// paypal_payment.dart
// A configuration & helper class similar to firebase_options.dart,
// but for PayPal REST API (Sandbox mode).

import 'dart:convert';
import 'package:http/http.dart' as http;

class PayPalConfig {
  // ------------------------------
  // SANDBOX CREDENTIALS (EDIT THIS)
  // ------------------------------
  static const String clientId =
      "AfI7sy8Fu-SrXM1PyZR_QSSyGdLpzAbSu5iR7zSAJ7pXSXBlGTP_N4c1QunE_CG3rrCvMcbLKmMNgPfG"; // Paste here
  static const String secretKey =
      "EDe4D1w2QKvl-AVKT4Xh2Wf248uYX3s3pkPbvv06fjLFO_dv3MSYDKrkSVTgKXttCGy8MyVnRFNvRCJT"; // Paste here

  // ------------------------------
  // ENDPOINTS
  // ------------------------------
  static const String sandboxAuthUrl =
      "https://api-m.sandbox.paypal.com/v1/oauth2/token";

  static const String sandboxOrderUrl =
      "https://api-m.sandbox.paypal.com/v2/checkout/orders";

  // -------------------------------------------------
  // GET ACCESS TOKEN (Required before any PayPal APIs)
  // -------------------------------------------------
  static Future<String?> generateAccessToken() async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode("$clientId:$secretKey"))}';

    final response = await http.post(
      Uri.parse(sandboxAuthUrl),
      headers: {
        "Authorization": basicAuth,
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: {"grant_type": "client_credentials"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["access_token"];
    } else {
      print("PayPal Auth Error: ${response.body}");
      return null;
    }
  }

  // -------------------------------------------------
  // CREATE PAYPAL ORDER (amount + description)
  // -------------------------------------------------
  static Future<Map<String, dynamic>?> createOrder({
    required double amount,
    required String description,
  }) async {
    final String? accessToken = await generateAccessToken();

    if (accessToken == null) return null;

    final response = await http.post(
      Uri.parse(sandboxOrderUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken"
      },
      body: jsonEncode({
        "intent": "CAPTURE",
        "purchase_units": [
          {
            "amount": {
              "currency_code": "USD",
              "value": amount.toStringAsFixed(2)
            },
            "description": description
          }
        ],
        "application_context": {
          "return_url": "https://yourapp.com/paypal-success",
          "cancel_url": "https://yourapp.com/paypal-cancel"
        }
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("PayPal createOrder Error: ${response.body}");
      return null;
    }
  }

  // -------------------------------------------------
  // CAPTURE ORDER (after user approves)
  // -------------------------------------------------
  static Future<Map<String, dynamic>?> captureOrder(
      String orderId) async {
    final String? accessToken = await generateAccessToken();

    if (accessToken == null) return null;

    final response = await http.post(
      Uri.parse("$sandboxOrderUrl/$orderId/capture"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken"
      },
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("PayPal captureOrder Error: ${response.body}");
      return null;
    }
  }
}
