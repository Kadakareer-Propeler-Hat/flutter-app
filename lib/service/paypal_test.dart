// lib/services/paypal_test.dart
// This file tests your PayPal sandbox connection and prints results in terminal.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PayPalTestConfig {
  // --------------------------------
  // INSERT YOUR PAYPAL SANDBOX KEYS
  // --------------------------------
  static const String clientId = "AfI7sy8Fu-SrXM1PyZR_QSSyGdLpzAbSu5iR7zSAJ7pXSXBlGTP_N4c1QunE_CG3rrCvMcbLKmMNgPfG";
  static const String secretKey = "EDe4D1w2QKvl-AVKT4Xh2Wf248uYX3s3pkPbvv06fjLFO_dv3MSYDKrkSVTgKXttCGy8MyVnRFNvRCJT";

  static const String authUrl =
      "https://api-m.sandbox.paypal.com/v1/oauth2/token";
  static const String orderUrl =
      "https://api-m.sandbox.paypal.com/v2/checkout/orders";

  // -------------------------------
  // GET ACCESS TOKEN
  // -------------------------------
  static Future<String?> _generateAccessToken() async {
    final auth = 'Basic ${base64Encode(utf8.encode('$clientId:$secretKey'))}';

    final response = await http.post(
      Uri.parse(authUrl),
      headers: {
        "Authorization": auth,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {"grant_type": "client_credentials"},
    );

    print("📡 PayPal Auth Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["access_token"];
    } else {
      print("❌ Failed to generate access token.");
      return null;
    }
  }

  // -------------------------------
  // CREATE SANDBOX ORDER
  // -------------------------------
  static Future<Map<String, dynamic>?> createTestOrder() async {
    print("\n===============================");
    print("🔵 Step 1: Getting PayPal Access Token...");
    print("===============================\n");

    final accessToken = await _generateAccessToken();

    if (accessToken == null) {
      print("❌ ERROR: Cannot create test order without token.");
      return null;
    }

    print("\n===============================");
    print("🟣 Step 2: Creating PayPal Order (SANDBOX)");
    print("===============================\n");

    final response = await http.post(
      Uri.parse(orderUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "intent": "CAPTURE",
        "purchase_units": [
          {
            "amount": {"currency_code": "USD", "value": "10.00"},
            "description": "Test Purchase — Flutter Sandbox"
          }
        ]
      }),
    );

    print("📡 PayPal Order Response: ${response.body}");

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to create sandbox order.");
      return null;
    }
  }
}

void main() async {
  print("\n=============================================");
  print("🚀 PAYPAL SANDBOX TEST STARTED");
  print("=============================================\n");

  final result = await PayPalTestConfig.createTestOrder();

  if (result != null) {
    print("\n=============================================");
    print("✅ SANDBOX ORDER CREATED SUCCESSFULLY!");
    print("=============================================\n");

    print("🧾 ORDER ID: ${result["id"]}\n");

    // Extract approval link
    final approveLink = result["links"]
        ?.firstWhere((l) => l["rel"] == "approve", orElse: () => null)?["href"];

    print("🔗 APPROVE LINK (open in browser):\n$approveLink\n");
  }

  print("\n=============================================");
  print("🏁 TEST COMPLETE");
  print("=============================================\n");
}
