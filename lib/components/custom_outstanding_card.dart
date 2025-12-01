import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../screens/view_repayment_plan.dart';

class CustomOutstandingCard extends StatelessWidget {
  const CustomOutstandingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final loanQuery = FirebaseFirestore.instance
        .collectionGroup("loans")
        .where("userId", isEqualTo: uid)
        .where("activeLoad", isEqualTo: true);




    return StreamBuilder<QuerySnapshot>(
      stream: loanQuery.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loadingCard();
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyCard();
        }

        // ===== AGGREGATE ALL LOANS =====
        double totalRemaining = 0;
        double totalLoanAmount = 0;
        double totalNextDueAmount = 0;
        DateTime? nearestDueDate;

        for (var doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          final remaining = (data["remaining"] ?? 0).toDouble();
          final total = (data["total"] ?? 0).toDouble();
          final nextDueAmount = (data["nextDueAmount"] ?? 0).toDouble();

          totalRemaining += remaining;
          totalLoanAmount += total;
          totalNextDueAmount += nextDueAmount;

          // Handle dates safely
          final rawDate = data["nextDueDate"];
          DateTime? parsed;

          if (rawDate is Timestamp) parsed = rawDate.toDate();
          if (rawDate is DateTime) parsed = rawDate;

          if (parsed != null) {
            if (nearestDueDate == null || parsed.isBefore(nearestDueDate!)) {
              nearestDueDate = parsed;
            }
          }
        }

        // computed values
        final totalPaid = totalLoanAmount - totalRemaining;
        final paidPercent = totalLoanAmount == 0
            ? 0
            : (totalPaid / totalLoanAmount) * 100;

        final nextDueString = nearestDueDate == null
            ? "--"
            : "${_month(nearestDueDate!.month)} ${nearestDueDate!.day}";

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    "Outstanding Balance",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  Spacer(),
                  Icon(LucideIcons.creditCard, color: Colors.red),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                "₱${totalRemaining.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C143A),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.calendar),
                          const SizedBox(height: 6),
                          const Text("Next Due",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(
                            nextDueString,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "₱${totalNextDueAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.target),
                          const SizedBox(height: 6),
                          const Text("Paid",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(
                            "${paidPercent.toStringAsFixed(0)}%",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "₱${totalPaid.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE96C63),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewRepaymentPlanScreen(),
                    ),
                  );
                },
                child: const Text(
                  "View Repayment Plan",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Handle EMPTY
  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          "No active loans found.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Handle LOADING
  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // Format next due date safely
  String _formatDate(dynamic date) {
    if (date == null) return "--";

    if (date is Timestamp) {
      final d = date.toDate();
      return "${_month(d.month)} ${d.day}";
    }

    if (date is DateTime) {
      return "${_month(date.month)} ${date.day}";
    }

    return date.toString();
  }

  String _month(int m) {
    const list = [
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return list[m];
  }
}
