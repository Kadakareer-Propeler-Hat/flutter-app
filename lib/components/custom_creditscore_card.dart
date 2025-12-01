import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomCreditScoreCard extends StatefulWidget {
  final String userId;

  const CustomCreditScoreCard({super.key, required this.userId});

  @override
  State<CustomCreditScoreCard> createState() => _CustomCreditScoreCardState();
}

class _CustomCreditScoreCardState extends State<CustomCreditScoreCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _progressAnim;

  int creditScore = 0;
  int scoreIncrease = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _computeCreditScore();
  }

  /// 🔥 Compute credit score based on all loans user has taken
  Future<void> _computeCreditScore() async {
    final loans = await FirebaseFirestore.instance
        .collection("loans")
        .where("userId", isEqualTo: widget.userId)
        .get();

    int loanCount = loans.docs.length;
    double totalPrincipal = 0;

    for (var doc in loans.docs) {
      totalPrincipal += (doc.data()["principal"] ?? 0);
    }

    // 🔥 CREDIT SCORE FORMULA
    int baseScore = 600;
    int score = baseScore;

    score += loanCount * 5;                     // +5 per loan
    score += (totalPrincipal / 10000).round() * 2; // +2 per ₱10,000

    score = score.clamp(300, 850);

    final previousScore = creditScore;

    setState(() {
      creditScore = score;
      scoreIncrease = score - previousScore;
    });

    _progressAnim = Tween<double>(
      begin: 0,
      end: (creditScore / 850).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF781B34),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text("Credit Score",
              style: TextStyle(color: Colors.white70, fontSize: 14)),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$creditScore",
                style: const TextStyle(
                    fontSize: 42,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              if (scoreIncrease > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "+$scoreIncrease",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                )
            ],
          ),

          const SizedBox(height: 6),

          Text(
            creditScore >= 750
                ? "Excellent"
                : creditScore >= 700
                ? "Good Standing"
                : creditScore >= 650
                ? "Fair"
                : "Needs Improvement",
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),

          const SizedBox(height: 12),

          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return LinearProgressIndicator(
                value: _progressAnim.value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              );
            },
          ),

          const SizedBox(height: 6),
          const Text(
            "Excellent: 750+",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
