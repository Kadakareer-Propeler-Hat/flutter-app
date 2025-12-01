import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:horizonai/screens/quickactions/loan_screen.dart';
import 'package:horizonai/screens/quickactions/quick_repayment.dart';
import 'package:horizonai/screens/quickactions/quick_loancoach.dart';
import 'package:horizonai/screens/quickactions/payment_navigator.dart';
import 'package:horizonai/screens/quickactions/despute_resolver.dart';
import 'package:horizonai/screens/quickactions/credit_line.dart';
import 'package:horizonai/screens/quickactions/rewards.dart';
import 'package:horizonai/screens/quickactions/fraud_detection.dart';

// ⭐ Add your loyalty system screen import here
import 'package:horizonai/screens/quickactions/loyalty_system.dart';

class CustomQuickActions extends StatelessWidget {
  const CustomQuickActions({super.key});

  final List<Map<String, dynamic>> quickActions = const [
    {"icon": LucideIcons.trendingUp, "label": "Smart\nRepayment", "SmartRepayment": true},
    {"icon": LucideIcons.graduationCap, "label": "Loan\nCoach", "loanCoach": true},

    {"icon": LucideIcons.navigation, "label": "Payment\nNavigator", "payNav": true},

    // ⭐ Loyalty System added
    {"icon": LucideIcons.medal, "label": "Loyalty\nSystem", "loyalty": true},

    {"icon": LucideIcons.scale, "label": "Dispute\nResolver", "DisputeResolver": true},
    {"icon": LucideIcons.creditCard, "label": "Credit\nLine", "Creditline": true},
    {"icon": LucideIcons.shieldAlert, "label": "Fraud\nDetection", "FraudDetection": true},
    {"icon": LucideIcons.gift, "label": "Rewards", "Rewards": true},

    {"icon": LucideIcons.smartphone, "label": "Loan\nCenter", "loanScreen": true},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quickActions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () {
                  // Smart repayment
                  if (quickActions[i]["SmartRepayment"] == true) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickRepaymentScreen()));
                  }

                  // Loan Coach
                  if (quickActions[i]["loanCoach"] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuickLoanCoach(
                          userId: "CoTrseAM8yR3HA74DJqX21YF33S2",
                        ),
                      ),
                    );
                  }

                  // Payment Navigator
                  if (quickActions[i]["payNav"] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentNavigator()),
                    );
                  }

                  // ⭐ Loyalty System navigation
                  if (quickActions[i]["loyalty"] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoyaltySystemScreen()),
                    );
                  }

                  if (quickActions[i]["DisputeResolver"] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DisputeResolverScreen()),
                    );
                  }

                  if (quickActions[i]["Creditline"] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreditLinePage()),
                    );
                  }

                  if (quickActions[i]["Rewards"] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RewardsPage()),
                    );
                  }

                  if (quickActions[i]["FraudDetection"] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FraudDetectionScreen()),
                    );
                  }

                  // Loan Center
                  if (quickActions[i]["loanScreen"] == true) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanScreen()));
                  }
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.redAccent.withOpacity(0.25),
                      child: Icon(quickActions[i]["icon"], color: Colors.redAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quickActions[i]["label"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
