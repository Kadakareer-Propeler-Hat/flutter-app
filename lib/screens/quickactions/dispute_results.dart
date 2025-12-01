import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisputeReviewPage extends StatelessWidget {
  final String disputeId;

  const DisputeReviewPage({
    super.key,
    required this.disputeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Open a Dispute",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("disputes")
            .doc(disputeId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------- PROGRESS INDICATOR --------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildStepCircle(Icons.check_circle, "Details", false),
                    buildDivider(),
                    buildStepCircle(Icons.access_time, "Evidence", false),
                    buildDivider(),
                    buildStepCircle(Icons.info_outline, "Review", true),
                  ],
                ),

                const SizedBox(height: 35),

                const Text(
                  "Review Your Dispute",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 25),

                // -------------------- DISPUTE DETAILS --------------------
                buildSection(
                  title: "Dispute Details",
                  children: [
                    buildRowItem(
                        "Reason for Dispute:", data["reason"] ?? "N/A"),
                    buildRowItem(
                        "Transaction ID:", data["transactionId"] ?? "N/A"),
                    buildRowItem(
                        "Incident Date:", data["incidentDate"] ?? "N/A"),
                  ],
                ),

                const SizedBox(height: 20),

                // -------------------- DESCRIPTION --------------------
                buildSection(
                  title: "Description",
                  children: [
                    Text(
                      data["description"] ?? "",
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // -------------------- EVIDENCE --------------------
                buildSection(
                  title: "Evidence",
                  children: [
                    if (data["evidenceImages"] != null &&
                        data["evidenceImages"].isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: (data["evidenceImages"] as List)
                            .map<Widget>(
                              (url) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            .toList(),
                      )
                    else
                      const Text("No evidence uploaded."),
                    const SizedBox(height: 10),
                    if (data["evidenceNotes"] != null)
                      Text(
                        data["evidenceNotes"],
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // -------------------- DESIRED OUTCOME --------------------
                buildSection(
                  title: "Desired Outcome",
                  children: [
                    Text(
                      data["desiredOutcome"] ?? "N/A",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // -------------------- BUTTONS --------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Back",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                      ),
                      onPressed: () => _submitDispute(context),
                      child: const Text("Submit"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================ UI COMPONENTS ============================

  Widget buildStepCircle(IconData icon, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: active ? Colors.red : Colors.grey.shade300,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget buildDivider() {
    return Container(
      height: 2,
      width: 60,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 5),
    );
  }

  Widget buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget buildRowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ============================ SUBMIT ACTION ============================

  Future<void> _submitDispute(BuildContext context) async {
    // Update Firestore status
    await FirebaseFirestore.instance
        .collection("disputes")
        .doc(disputeId)
        .update({
      "status": "submitted",
      "submittedAt": Timestamp.now(),
      "step": 3,
    });

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Dispute Submitted"),
        content: const Text(
          "Your dispute has been successfully submitted for review.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .popUntil((route) => route.isFirst); // Go back to Dashboard
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
