import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horizonai/components/custom_mainappbar.dart';

class CreditLinePage extends StatefulWidget {
  const CreditLinePage({Key? key}) : super(key: key);

  @override
  State<CreditLinePage> createState() => _CreditLinePageState();
}

class _CreditLinePageState extends State<CreditLinePage> {
  bool _isSubmitting = false;

  // Editable credit line
  final TextEditingController _creditLineController =
  TextEditingController(text: "15000");

  Future<void> _requestIncrease() async {
    final TextEditingController amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Request Credit Increase"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Requested Amount",
            hintText: "Enter amount (e.g. 2000)",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Submit"),
            onPressed: () async {
              final amount = amountController.text.trim();
              if (amount.isEmpty) return;

              Navigator.pop(context);
              await _saveRequest(amount);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveRequest(String amount) async {
    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("credit_requests").add({
      "uid": user.uid,
      "requestedAmount": amount,
      "timestamp": Timestamp.now(),
      "status": "Pending",
    });

    setState(() => _isSubmitting = false);

    // After saving → Show approval waiting overlay
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreditApprovalWaitingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE4A32A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomMainAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            CircleAvatar(
              radius: 40,
              backgroundColor: accent.withOpacity(.25),
              child:
              const Icon(Icons.credit_card, size: 40, color: accent),
            ),

            const SizedBox(height: 10),

            const Text(
              "Credit Line Engine",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Smart credit solutions tailored to you",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: accent.withOpacity(.85),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Available Credit",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    "Based on your financial profile and history",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Credit Line",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 8),

                        // Editable TextField
                        TextField(
                          controller: _creditLineController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixText: "₱ ",
                            prefixStyle: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  Center(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        final amount = _creditLineController.text.trim();
                        if (amount.isEmpty) return;

                        // Save request ONCE using typed credit line
                        await _saveRequest(amount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: accent,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text("Request Credit Increase",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _buildFeatureCard(
              icon: Icons.payment,
              title: "Flexible Payment Options",
              description:
              "Choose from multiple payment plans tailored to your budget.",
            ),

            const SizedBox(height: 18),

            _buildFeatureCard(
              icon: Icons.attach_money,
              title: "Zero Hidden Fees",
              description:
              "No surprise charges. All payment terms are crystal clear.",
            ),

            const SizedBox(height: 18),

            _buildFeatureCard(
              icon: Icons.lock,
              title: "Safe Transactions",
              description:
              "Every payment is encrypted and secured by our system.",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style:
                  const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ APPROVAL WAITING SCREEN ------------------

class CreditApprovalWaitingScreen extends StatefulWidget {
  const CreditApprovalWaitingScreen({super.key});

  @override
  State<CreditApprovalWaitingScreen> createState() =>
      _CreditApprovalWaitingScreenState();
}

class _CreditApprovalWaitingScreenState
    extends State<CreditApprovalWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(.65),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/logo/happy.PNG", width: 250, height: 250,),
              const SizedBox(height: 25),
              const Text(
                "wait your request approval...",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
