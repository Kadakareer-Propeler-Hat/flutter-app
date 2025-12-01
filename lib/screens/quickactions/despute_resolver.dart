import 'package:flutter/material.dart';
import 'dispute_details.dart'; // ✅ IMPORTANT: Import your details screen here

class DisputeResolverScreen extends StatelessWidget {
  const DisputeResolverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // BACK BUTTON
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.black54),
                    SizedBox(width: 6),
                    Text(
                      "Back to Home",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TOP ICON
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFB43A33),
                  child: const Icon(
                    Icons.balance_outlined,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // TITLE
              const Center(
                child: Text(
                  "Dispute Resolver",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              const Center(
                child: Text(
                  "Fair and transparent resolution for your concerns",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 25),

              // SUBMIT NEW DISPUTE BUTTON — UPDATED
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DisputeDetailsPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Submit New Dispute",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB43A33),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Your Disputes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // CARD 1
              _buildDisputeCard(
                id: "DSP-2024-001",
                receiptNumber: "RCP-885432",
                amount: "₱1,500",
                submittedDate: "Nov 20, 2024",
                status: "Under Review",
                resolvedDate: null,
                statusColor: Colors.orange,
                cardColor: Colors.yellow.shade50,
                borderColor: Colors.yellow.shade300,
              ),

              const SizedBox(height: 16),

              // CARD 2
              _buildDisputeCard(
                id: "DSP-2024-002",
                receiptNumber: "RCP-882910",
                amount: "₱850",
                submittedDate: "Nov 10, 2024",
                resolvedDate: "Nov 15, 2024",
                status: "Resolved",
                statusColor: Colors.green,
                cardColor: Colors.green.shade50,
                borderColor: Colors.green.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== DISPUTE CARD WIDGET ======================

  Widget _buildDisputeCard({
    required String id,
    required String receiptNumber,
    required String amount,
    required String submittedDate,
    required String status,
    required Color statusColor,
    required Color cardColor,
    required Color borderColor,
    String? resolvedDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dispute ID",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == "Under Review"
                          ? Icons.timelapse
                          : Icons.check_circle,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ID Text
          Text(
            id,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),

          const SizedBox(height: 14),

          _buildInfoRow(Icons.receipt_long, "Receipt Number:", receiptNumber),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.payments, "Amount:", amount),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.calendar_today, "Submitted:", submittedDate),

          if (resolvedDate != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.check_circle_outline, "Resolved:", resolvedDate),
          ],

          const SizedBox(height: 18),

          if (status == "Under Review")
            _buildProgressTracker(statusColor),
        ],
      ),
    );
  }

  // Info Row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.black87)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Progress Tracker
  Widget _buildProgressTracker(Color activeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progress Tracker",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _progressStep(Icons.check_circle, "Submitted", activeColor, true),
            _progressLine(activeColor),
            _progressStep(Icons.timelapse, "Under Review", activeColor, true),
            _progressLine(Colors.grey),
            _progressStep(Icons.circle_outlined, "Resolution", Colors.grey, false),
          ],
        ),
      ],
    );
  }

  Widget _progressStep(
      IconData icon, String label, Color color, bool active) {
    return Column(
      children: [
        Icon(icon, color: active ? color : Colors.grey, size: 26),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _progressLine(Color color) {
    return Expanded(
      child: Container(
        height: 2,
        color: color.withOpacity(0.4),
      ),
    );
  }
}
