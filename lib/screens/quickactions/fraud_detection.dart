import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class FraudDetectionScreen extends StatelessWidget {
  const FraudDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Back to Home",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // ICON
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFFFF2CE),
              child: Icon(Iconsax.shield_tick, color: Colors.orange.shade600, size: 32),
            ),

            const SizedBox(height: 15),

            const Text(
              "Fraud Detection",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C143A),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Advanced protection for your financial security",
              style: TextStyle(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            // 🔵 SECURITY STATUS BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFE8F6EE),
                border: Border.all(color: const Color(0xFF48C37D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.shield, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "All systems secure",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1C143A)),
                          ),
                          Text(
                            "No suspicious activity detected",
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text("Security Score",
                      style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 6),

                  // SCORE BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("85/100",
                          style: TextStyle(
                              color: Color(0xFF1C143A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ⚪ SECURITY FEATURES TITLE
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Security Features",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C143A),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 🔐 2FA BOX
            buildFeatureItem(
              icon: Iconsax.lock,
              title: "2-Factor Authentication",
              subtitle: "Active",
              statusColor: Colors.green,
              statusLabel: "Enabled",
            ),

            const SizedBox(height: 10),

            // 🔔 Alerts Box
            buildFeatureItem(
              icon: Iconsax.notification,
              title: "Transaction Alerts",
              subtitle: "Active",
              statusColor: Colors.green,
              statusLabel: "Enabled",
            ),

            const SizedBox(height: 10),

            // 👁 Device Recognition
            buildFeatureItem(
              icon: Iconsax.eye,
              title: "Device Recognition",
              subtitle: "Not enabled",
              statusColor: Colors.grey.shade300,
              statusLabel: "Enable",
              statusTextColor: Colors.black54,
            ),

            const SizedBox(height: 20),

            // SECURITY ALERTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Security Alerts",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C143A),
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "2 New",
                    style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                )
              ],
            ),

            const SizedBox(height: 15),

            // 🔵 ALERT 1
            buildAlertCard(
              color: const Color(0xFFE4EDFF),
              icon: Iconsax.eye,
              title: "New Device Login Detected",
              time: "2 hours ago",
              description:
              "A login from a new device was detected on\nNov 24, 2024",
            ),

            const SizedBox(height: 12),

            // 🟡 ALERT 2
            buildAlertCard(
              color: const Color(0xFFFFF6DD),
              icon: Iconsax.warning_2,
              title: "Unusual Transaction Pattern",
              time: "1 day ago",
              description:
              "We noticed 3 payment attempts in quick\nsuccession",
              accentColor: Colors.orange,
            ),

            const SizedBox(height: 25),

            // HISTORY BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  "View All Security History",
                  style: TextStyle(
                    color: Color(0xFF1C143A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FEATURE ITEM BUILDER
  // ------------------------------------------------------------
  Widget buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color statusColor,
    required String statusLabel,
    Color? statusTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF1C143A)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1C143A))),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  color: statusTextColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ALERT CARD BUILDER
  // ------------------------------------------------------------
  Widget buildAlertCard({
    required Color color,
    required IconData icon,
    required String title,
    required String time,
    required String description,
    Color accentColor = Colors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1C143A),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            description,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),

          const SizedBox(height: 15),

          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "Review Activity",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }
}
