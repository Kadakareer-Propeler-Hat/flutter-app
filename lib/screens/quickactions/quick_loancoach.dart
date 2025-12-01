import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class QuickLoanCoach extends StatefulWidget {
  final String userId;
  const QuickLoanCoach({super.key, required this.userId});

  @override
  State<QuickLoanCoach> createState() => _QuickLoanCoachState();
}

class _QuickLoanCoachState extends State<QuickLoanCoach> {
  double monthlyIncome = 0;
  double monthlyExpenses = 0;
  double disposable = 0;
  double debtToIncome = 0;

  String aiFinancialAnalysis = "";
  List<Map<String, String>> aiStrategies = [];

  bool loading = true;

  Future<void> loadLoanData() async {
    final ref = FirebaseFirestore.instance
        .collection("loans")
        .doc(widget.userId)
        .collection("loans");

    final snap = await ref.get();

    double totalDebt = 0;

    for (var doc in snap.docs) {
      final data = doc.data();
      if (data["activeLoad"] == true) {
        totalDebt += (data["total"] ?? 0).toDouble();
      }
    }

    monthlyIncome = 25000;
    monthlyExpenses = 18500;
    disposable = monthlyIncome - monthlyExpenses;

    debtToIncome = (totalDebt / monthlyIncome) * 100;

    await generateAIResults(
      income: monthlyIncome,
      expenses: monthlyExpenses,
      disposable: disposable,
      dti: debtToIncome,
    );

    setState(() => loading = false);
  }

  Future<void> generateAIResults({
    required double income,
    required double expenses,
    required double disposable,
    required double dti,
  }) async {
    const apiKey = "AIzaSyB5NqtrPK-A9gjZZ-WCPF4hGYrsOkeWIH8";

    final prompt = """
You are a financial advisor AI. 
Analyze the user's financial situation:

Income: ₱$income  
Expenses: ₱$expenses  
Disposable: ₱$disposable  
Debt-to-income ratio: ${dti.toStringAsFixed(1)}%

IMPORTANT — return valid JSON ONLY, no markdown.

{
 "analysis": "3 short sentences of financial analysis.",
 "strategies": [
    { "title": "Strategy 1", "description": "Explain the strategy clearly.", "impact": "Short impact sentence." },
    { "title": "Strategy 2", "description": "Explain the strategy clearly.", "impact": "Short impact sentence." },
    { "title": "Strategy 3", "description": "Explain the strategy clearly.", "impact": "Short impact sentence." }
 ]
}
""";

    final payload = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);

      String raw = result["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "{}";
      final cleaned = raw.replaceAll("```json", "").replaceAll("```", "").trim();

      final decoded = jsonDecode(cleaned);

      aiFinancialAnalysis = decoded["analysis"] ?? "No analysis.";

      if (decoded["strategies"] is List) {
        aiStrategies =
        List<Map<String, String>>.from(decoded["strategies"].map((e) => Map<String, String>.from(e)));
      }
    } catch (e) {
      aiFinancialAnalysis = "Unable to load AI suggestions.";
      aiStrategies = [];
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadLoanData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              const Text("Back to Home", style: TextStyle(fontSize: 16)),
            ]),
            const SizedBox(height: 20),

            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFFFC55C),
                child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text("Loan Coach",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const Center(
              child: Text(
                "Expert guidance for smarter financial decisions",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 25),

            _financialOverview(),
            const SizedBox(height: 20),

            _analysisBox(),
            const SizedBox(height: 25),

            const Text("AI Financial Strategies",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Column(
              children: List.generate(aiStrategies.length, (i) {
                final s = aiStrategies[i];
                return _strategyCard(
                  index: i,
                  title: s["title"]!,
                  desc: s["description"]!,
                  impact: s["impact"]!,
                );
              }),
            )
          ]),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI COMPONENTS
  // --------------------------------------------------------------------------

  Widget _financialOverview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,                     // WHITE background (your request)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Financial Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  title: "Monthly\nIncome",
                  value: "₱${monthlyIncome.toStringAsFixed(0)}",
                  borderColor: Colors.green,
                  bgColor: const Color(0xFFE8F5E9),   // LIGHT GREEN BOX
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoBox(
                  title: "Monthly\nExpenses",
                  value: "₱${monthlyExpenses.toStringAsFixed(0)}",
                  borderColor: Colors.red,
                  bgColor: const Color(0xFFE8F5E9),   // LIGHT GREEN BOX
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoBox(
                  title: "Disposable",
                  value: "₱${disposable.toStringAsFixed(0)}",
                  borderColor: Colors.blue,
                  bgColor: const Color(0xFFE8F5E9),   // LIGHT GREEN BOX
                  icon: Icons.savings,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text("Debt-to-Income Ratio", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 6),

          Text(
            "${debtToIncome.toStringAsFixed(1)}%",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: debtToIncome / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }



  Widget _analysisBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EB),
        border: Border.all(color: Colors.orange.shade300, width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Financial Analysis",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          "• $aiFinancialAnalysis".replaceAll(". ", ".\n• "),
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
      ]),
    );
  }

  Widget _strategyCard({
    required int index,
    required String title,
    required String desc,
    required String impact,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20, top: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Text(desc, style: const TextStyle(fontSize: 15, height: 1.4)),
              const SizedBox(height: 12),

              Container(
                padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text("Impact: $impact",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),

        /// ORANGE NUMBER BADGE
        Positioned(
          top: -6,
          left: -6,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.orange,
            child: Text(
              "${index + 1}",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }


  Widget _infoBox({
    required String title,
    required String value,
    required Color borderColor,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,                               // LIGHT GREEN BOX
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 22),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: borderColor,
            ),
          ),
        ],
      ),
    );
  }
}
