import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomOutstandingCard extends StatelessWidget {
  const CustomOutstandingCard({super.key});

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

          const Text(
            "₱8,450",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C143A),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              // NEXT DUE
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(LucideIcons.calendar),
                      SizedBox(height: 6),
                      Text("Next Due",
                          style:
                          TextStyle(fontSize: 13, color: Colors.black54)),
                      SizedBox(height: 4),
                      Text("Dec 15",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      Text("₱1,200",
                          style: TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // PAID
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(LucideIcons.target),
                      SizedBox(height: 6),
                      Text("Paid",
                          style:
                          TextStyle(fontSize: 13, color: Colors.black54)),
                      SizedBox(height: 4),
                      Text("65%",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      Text("₱13,550",
                          style: TextStyle(fontSize: 13, color: Colors.black54)),
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
            onPressed: () {},
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
  }
}
