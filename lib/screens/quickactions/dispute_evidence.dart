import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ❗ REMOVED Firebase Storage
// import 'package:firebase_storage/firebase_storage.dart';

// ⭐ ADDED SUPABASE
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dispute_results.dart';

class DisputeEvidenceScreen extends StatefulWidget {
  final String disputeId;
  final Map<String, dynamic> disputeData;

  const DisputeEvidenceScreen({
    super.key,
    required this.disputeId,
    required this.disputeData,
  });

  @override
  State<DisputeEvidenceScreen> createState() => _DisputeEvidenceScreenState();
}

class _DisputeEvidenceScreenState extends State<DisputeEvidenceScreen> {
  List<File> courierImages = [];
  List<File> sellerImages = [];

  List<String> courierUrls = [];
  List<String> sellerUrls = [];

  final ImagePicker picker = ImagePicker();
  bool loading = false;

  // ------------------------------------------------------------
  // IMAGE PICKERS
  // ------------------------------------------------------------
  Future<void> pickCourierImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => courierImages.add(File(file.path)));
  }

  Future<void> pickSellerImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => sellerImages.add(File(file.path)));
  }

  // ------------------------------------------------------------
  // ⭐ SUPABASE UPLOAD FUNCTION
  // ------------------------------------------------------------
  Future<List<String>> uploadImagesToSupabase(
      List<File> files,
      String folder,
      ) async {
    final supabase = Supabase.instance.client;

    List<String> urls = [];

    for (var img in files) {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${img.path.split('/').last}";

      final storagePath = "disputes/${widget.disputeId}/$folder/$fileName";

      try {
        // 1️⃣ Upload file to Supabase
        await supabase.storage.from("evidences").upload(
          storagePath,
          img,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

        // 2️⃣ Get public URL
        final String publicUrl =
        supabase.storage.from("your-bucket-name").getPublicUrl(storagePath);

        urls.add(publicUrl);
      } catch (e) {
        debugPrint("Upload failed: $e");
      }
    }

    return urls;
  }

  // ------------------------------------------------------------
  // SAVE TO FIRESTORE (Same as before)
  // ------------------------------------------------------------
  Future<void> saveEvidence() async {
    setState(() => loading = true);

    // ⭐ upload to supabase instead of firebase storage
    if (courierImages.isNotEmpty) {
      courierUrls = await uploadImagesToSupabase(courierImages, "courier");
    }

    if (sellerImages.isNotEmpty) {
      sellerUrls = await uploadImagesToSupabase(sellerImages, "seller");
    }

    // Save URLs in Firestore the same way
    await FirebaseFirestore.instance
        .collection("disputes")
        .doc(widget.disputeId)
        .update({
      "courierEvidence": courierUrls,
      "sellerEvidence": sellerUrls,
      "step": 2,
      "updatedAt": Timestamp.now(),
    });

    setState(() => loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DisputeReviewPage(disputeId: widget.disputeId),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Steps UI ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildStepCircle(Icons.check_circle, "Details", true),
                buildDivider(),
                buildStepCircle(Icons.access_time, "Evidence", true),
                buildDivider(),
                buildStepCircle(Icons.info_outline, "Review", false),
              ],
            ),

            const SizedBox(height: 40),

            const Text(
              "Documentation",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C143A)),
            ),

            const SizedBox(height: 25),

            // -------------------- Courier Upload --------------------
            const Text(
              "Courier Tracking Screenshot",
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C143A)),
            ),
            const SizedBox(height: 6),
            const Text(
              "A screenshot showing the delivery status.",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),

            buildUploadBox(onTap: pickCourierImage),

            if (courierImages.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: courierImages
                    .map(
                      (img) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      img,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .toList(),
              ),

            const SizedBox(height: 35),

            // -------------------- Seller Upload --------------------
            const Text(
              "Correspondence with Seller",
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C143A)),
            ),
            const SizedBox(height: 6),
            const Text(
              "Screenshots of messages or emails.",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),

            buildUploadBox(onTap: pickSellerImage),

            if (sellerImages.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: sellerImages
                    .map(
                      (img) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      img,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .toList(),
              ),

            const SizedBox(height: 50),

            const Divider(),
            const SizedBox(height: 10),

            // -------------------- Buttons --------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text("Back"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: saveEvidence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text("Proceed",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Reusable UI widgets
  // ------------------------------------------------------------
  Widget buildUploadBox({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_upload_outlined,
                size: 55, color: Colors.black26),
            SizedBox(height: 8),
            Text("Upload Screenshot",
                style: TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }

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
    );
  }
}
