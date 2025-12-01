// lib/screens/dispute_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dispute_evidence.dart';

class DisputeDetailsPage extends StatefulWidget {
  const DisputeDetailsPage({super.key});

  @override
  State<DisputeDetailsPage> createState() => _DisputeDetailsPageState();
}

class _DisputeDetailsPageState extends State<DisputeDetailsPage> {
  String? selectedReason;
  String? selectedOutcome;
  final TextEditingController orderIdController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int descriptionLength = 0;
  bool saving = false;

  // Reason definitions with icons
  final List<_Reason> reasons = [
    _Reason("Item not Received", Icons.local_shipping_outlined),
    _Reason("Item damaged", Icons.report_gmailerrorred_outlined),
    _Reason("Item not as described", Icons.crop_free_outlined),
    _Reason("Service not as described", Icons.question_answer_outlined),
    _Reason("Billing or Payment Issue", Icons.receipt_long_outlined),
  ];

  final List<String> outcomes = [
    "Full Refund",
    "Partial Refund",
    "Replacement / Exchange",
    "Credit Score",
  ];

  @override
  void dispose() {
    orderIdController.dispose();
    dateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      dateController.text = DateFormat('MM/dd/yyyy').format(picked);
    }
  }

  Future<void> _onProceed() async {
    // Validation
    if (selectedReason == null) {
      _showSnack("Please choose a reason for dispute.");
      return;
    }
    if (orderIdController.text.trim().isEmpty) {
      _showSnack("Please enter Transaction / Order ID.");
      return;
    }
    if (dateController.text.trim().isEmpty) {
      _showSnack("Please choose Date of the Incident.");
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      _showSnack("Please describe what happened.");
      return;
    }
    if (selectedOutcome == null) {
      _showSnack("Please choose desired outcome.");
      return;
    }

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      // Prepare dispute data
      final disputeData = {
        "userId": user.uid,
        "reason": selectedReason,
        "orderId": orderIdController.text.trim(),
        "incidentDate": dateController.text.trim(),
        "description": descriptionController.text.trim(),
        "desiredOutcome": selectedOutcome,
        "status": "draft", // will move forward in flow
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection("disputes")
          .add(disputeData);

      // After saving, navigate to Evidence screen and pass disputeId
      if (!mounted) return;
      _showSnack("Dispute saved. Continue to add evidence.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DisputeEvidenceScreen(
            disputeId: docRef.id,
            disputeData: {
              "orderId": disputeData["orderId"],
              "reason": disputeData["reason"],
              "incidentDate": disputeData["incidentDate"],
              "desiredOutcome": disputeData["desiredOutcome"],
            },
          ),
        ),
      );
    } catch (e) {
      _showSnack("Failed to save dispute: $e");
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color(0xFF1C143A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title
            const SizedBox(height: 6),
            const Center(
              child: Text(
                "Open a Dispute",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C143A),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stepItem("Details", true),
                _stepDivider(),
                _stepItem("Evidence", false),
                _stepDivider(),
                _stepItem("Review", false),
              ],
            ),

            const SizedBox(height: 26),

            // Reason title
            const Text(
              "Reason for Dispute",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C143A),
              ),
            ),
            const SizedBox(height: 12),

            // reasons in two-column layout
            LayoutBuilder(builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: reasons.map((r) {
                  final bool isSelected = selectedReason == r.label;
                  return SizedBox(
                    width: width,
                    child: GestureDetector(
                      onTap: () => setState(() => selectedReason = r.label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                          isSelected ? const Color(0xFFFFEEF1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B1538)
                                : Colors.grey.shade300,
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF8B1538)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                r.icon,
                                size: 20,
                                color: isSelected ? Colors.white : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF8B1538)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 20),

            // Order ID + Date in row
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Transaction / Order ID",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1C143A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: orderIdController,
                        decoration: InputDecoration(
                          hintText: "e.g RAX-21239",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date of the Incident",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1C143A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          hintText: "mm/dd/yyyy",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          suffixIcon: const Icon(Icons.calendar_month),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            const Text(
              "What happened?",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1C143A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 6,
              maxLength: 1000,
              onChanged: (val) => setState(() => descriptionLength = val.length),
              decoration: InputDecoration(
                hintText: "Be specific. Clear details help us resolve your case faster.",
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$descriptionLength / 1000",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),

            const SizedBox(height: 20),

            // Desired outcome
            const Text(
              "Desired Outcome",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF1C143A),
              ),
            ),
            const SizedBox(height: 6),
            Column(
              children: outcomes.map((o) {
                return RadioListTile<String>(
                  title: Text(o),
                  value: o,
                  groupValue: selectedOutcome,
                  activeColor: const Color(0xFF8B1538),
                  onChanged: (val) => setState(() => selectedOutcome = val),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade400),
            const SizedBox(height: 12),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancel & Return",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving ? null : _onProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD85050),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                      : const Text(
                    "Proceed",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _stepItem(String label, bool active) {
    return Column(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? const Color(0xFFD85050) : Colors.grey.shade400,
          size: 32,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFFD85050) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _stepDivider() {
    return Container(
      width: 50,
      height: 2,
      color: Colors.grey.shade300,
    );
  }
}

class _Reason {
  final String label;
  final IconData icon;
  _Reason(this.label, this.icon);
}
