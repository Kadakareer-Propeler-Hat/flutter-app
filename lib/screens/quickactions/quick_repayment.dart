// lib/screens/quickactions/quick_repayment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:horizonai/components/custom_mainappbar.dart';

class QuickRepaymentScreen extends StatefulWidget {
  const QuickRepaymentScreen({super.key});

  @override
  State<QuickRepaymentScreen> createState() => _QuickRepaymentScreenState();
}

class _QuickRepaymentScreenState extends State<QuickRepaymentScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> activeLoans = [];
  Map<String, dynamic>? selectedLoan;
  bool loading = true;
  String aiRecommendation = "Generating recommendation...";
  List<Map<String, String>> chatMessages = []; // {"sender": "user"/"ai", "text": "message"}
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchActiveLoans();
  }

  Future<void> fetchActiveLoans() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final loansSnapshot = await _firestore
        .collection('loans')
        .where('userId', isEqualTo: user.uid)
        .where('activeLoad', isEqualTo: true)
        .get();

    if (loansSnapshot.docs.isNotEmpty) {
      activeLoans =
          loansSnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
      selectedLoan = activeLoans.first;
      await generateAIRecommendation();
    }

    setState(() {
      loading = false;
    });
  }

  // ----- Gemini AI API call for AI Recommendation -----
  Future<void> generateAIRecommendation() async {
    if (selectedLoan == null) return;

    const apiKey = "YOUR_API_KEY";

    final total = (selectedLoan!['computed']['total'] as num).toDouble();
    final remaining =
        (selectedLoan!['computed']['remaining'] as num?)?.toDouble() ?? total;
    final paidSoFar = total - remaining;

    final promptText = """
You are a financial assistant. A user has a loan with the following details:
- Principal: ₱${selectedLoan!['computed']['principal']}
- Interest: ₱${selectedLoan!['computed']['interest']}
- Total: ₱$total
- Rate: ${selectedLoan!['computed']['rate'] * 100}%
- Installments: ${selectedLoan!['installmentMonths']} months
- Plan: ${selectedLoan!['planType']}
- Product: ${selectedLoan!['productBrand']} ${selectedLoan!['productModel']}
- Down Payment: ₱${selectedLoan!['downPayment']}
- Amount Paid So Far: ₱$paidSoFar

Provide a concise recommendation on how this user can minimize interest or repay faster.
""";

    final payload = {
      "contents": [
        {
          "parts": [
            {"text": promptText}
          ]
        }
      ]
    };

    final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);
      String recommendation = "";

      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        recommendation =
            data['candidates'][0]['content']['parts'][0]['text'] ?? "";
      }

      setState(() {
        aiRecommendation = recommendation.isEmpty
            ? "No recommendation generated."
            : recommendation;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        aiRecommendation = "Failed to generate recommendation.";
      });
    }
  }

  // ----- Gemini AI Chat API call -----
  Future<void> sendChatToAI(String userMessage) async {
    if (selectedLoan == null) return;

    setState(() {
      chatMessages.add({"sender": "user", "text": userMessage});
    });

    const apiKey = "YOUR_API_KEY";

    final total = (selectedLoan!['computed']['total'] as num).toDouble();
    final remaining =
        (selectedLoan!['computed']['remaining'] as num?)?.toDouble() ?? total;
    final paidSoFar = total - remaining;

    final promptText = """
You are a financial assistant. A user has a loan with the following details:
- Principal: ₱${selectedLoan!['computed']['principal']}
- Interest: ₱${selectedLoan!['computed']['interest']}
- Total: ₱$total
- Rate: ${selectedLoan!['computed']['rate'] * 100}%
- Installments: ${selectedLoan!['installmentMonths']} months
- Plan: ${selectedLoan!['planType']}
- Product: ${selectedLoan!['productBrand']} ${selectedLoan!['productModel']}
- Down Payment: ₱${selectedLoan!['downPayment']}
- Amount Paid So Far: ₱$paidSoFar

User asked: "$userMessage"
Provide a concise and helpful answer.
""";

    final payload = {
      "contents": [
        {
          "parts": [
            {"text": promptText}
          ]
        }
      ]
    };

    final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);
      String aiText = "";

      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        aiText = data['candidates'][0]['content']['parts'][0]['text'] ?? "";
      }

      setState(() {
        chatMessages.add({"sender": "ai", "text": aiText});
      });
    } catch (e) {
      setState(() {
        chatMessages.add({"sender": "ai", "text": "Failed to get AI response."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = (selectedLoan!['computed']['total'] as num).toDouble();
    final remaining =
        (selectedLoan!['computed']['remaining'] as num?)?.toDouble() ?? total;
    final paid = total - remaining;

    return Scaffold(
        appBar: const CustomMainAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Circular Analytics Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              "Smart Repayment Path",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Your personalized journey to financial freedom",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            if (activeLoans.length > 1)
              DropdownButton<Map<String, dynamic>>(
                value: selectedLoan,
                items: activeLoans
                    .map((loan) => DropdownMenuItem(
                  value: loan,
                  child: Text(
                      "${loan['productBrand']} ${loan['productModel']}"),
                ))
                    .toList(),
                onChanged: (loan) async {
                  setState(() {
                    selectedLoan = loan;
                    aiRecommendation = "Generating recommendation...";
                  });
                  await generateAIRecommendation();
                },
              ),

            const SizedBox(height: 16),

            // Current Balance Card
            Card(
              color: Colors.redAccent.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Balance",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₱${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Repayment Progress",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (paid / total).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.3),
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₱${paid.toStringAsFixed(2)} paid • ₱${remaining.toStringAsFixed(2)} remaining",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI Projected Timeline Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI Projected Timeline",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        // Milestone 1
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 50,
                                  color: Colors.redAccent.withOpacity(0.5),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Next Payment Due\nDec 15, 2025 - ₱${(total / 12).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        // Milestone 2
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 50,
                                  color: Colors.orangeAccent.withOpacity(0.5),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: const Text(
                                "Projected Milestone\n50% Paid - Jan 2026",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        // Milestone 3
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: const Text(
                                "Full Repayment\nExpected: Jun 2026",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI Recommendation Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.yellowAccent)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI Recommendation",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    aiRecommendation == "Generating recommendation..."
                        ? const Center(child: CircularProgressIndicator())
                        : Text(
                      aiRecommendation,
                      softWrap: true,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Navigate to payment scheduling screen
                      },
                        child: const Text(
                          "Schedule Payment",
                          style: TextStyle(color: Colors.white),
                        )

                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------------- Ask AI About Your Repayment Chat ----------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ask AI About Your Repayment",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // Quick questions
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickQuestionPill(
                        text: "How can I pay early?",
                        onTap: sendChatToAI,
                      ),
                      _QuickQuestionPill(
                        text: "What's my interest rate?",
                        onTap: sendChatToAI,
                      ),
                      _QuickQuestionPill(
                        text: "Can I adjust my payment date?",
                        onTap: sendChatToAI,
                      ),
                      _QuickQuestionPill(
                        text: "Show me payment options",
                        onTap: sendChatToAI,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Chat messages display
                  if (chatMessages.isNotEmpty)
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = chatMessages[index];
                          final isUser = msg["sender"] == "user";
                          return Align(
                            alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.redAccent.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(msg["text"]!),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Input field
                  TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: "Ask about your repayment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final text = _chatController.text.trim();
                          if (text.isNotEmpty) {
                            _chatController.clear();
                            sendChatToAI(text);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Question Pill Widget
class _QuickQuestionPill extends StatefulWidget {
  final String text;
  final Function(String) onTap;
  const _QuickQuestionPill({required this.text, required this.onTap, super.key});

  @override
  State<_QuickQuestionPill> createState() => _QuickQuestionPillState();
}

class _QuickQuestionPillState extends State<_QuickQuestionPill> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return _visible
        ? GestureDetector(
      onTap: () {
        setState(() {
          _visible = false;
        });
        widget.onTap(widget.text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade100,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          widget.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    )
        : const SizedBox.shrink();
  }
}
