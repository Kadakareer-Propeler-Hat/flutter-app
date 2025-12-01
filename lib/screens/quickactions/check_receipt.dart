import 'dart:convert';
import 'dart:io';
import 'package:horizonai/components/custom_mainappbar.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CheckReceiptScreen extends StatefulWidget {
  const CheckReceiptScreen({super.key});

  @override
  State<CheckReceiptScreen> createState() => _CheckReceiptScreenState();
}

class _CheckReceiptScreenState extends State<CheckReceiptScreen> {
  File? _imageFile;
  String _extractedText = "";
  bool _loading = false;

  // Extracted fields
  String storeName = "";
  String dateIssued = "";
  String totalAmount = "";
  String verdict = "";

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  // ----------------------------------------------------------
  // PICK IMAGE
  // ----------------------------------------------------------
  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => _imageFile = File(file.path));
      await _runOCR();
    }
  }

  // ----------------------------------------------------------
  // OCR PROCESSING
  // ----------------------------------------------------------
  Future<void> _runOCR() async {
    if (_imageFile == null) return;

    setState(() => _loading = true);

    final inputImage = InputImage.fromFile(_imageFile!);
    final recognized = await _textRecognizer.processImage(inputImage);

    final buffer = StringBuffer();
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        buffer.writeln(line.text);
      }
    }

    _extractedText = buffer.toString();

    await _callGemini(_extractedText);
  }

  // ----------------------------------------------------------
  // GEMINI API CALL
  // ----------------------------------------------------------
  Future<void> _callGemini(String text) async {
    const apiKey = "YOUR_API_KEY";

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text": """
Extract the following details from the provided receipt text:

- Store Name
- Date
- Total Amount
- Final Verdict (Genuine or Not)

Respond with PURE JSON ONLY. No explanation, no markdown.

Receipt Text:
$text
"""
            }
          ]
        }
      ],
      "generationConfig": {"temperature": 0.2, "maxOutputTokens": 200}
    };

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        setState(() => verdict = "Gemini Error: ${res.body}");
        return;
      }

      final data = jsonDecode(res.body);

      final jsonString = data["candidates"][0]["content"]["parts"][0]["text"];

      final extracted = jsonDecode(jsonString);

      setState(() {
        storeName = extracted["Store Name"] ?? "Not found";
        dateIssued = extracted["Date"] ?? "Unknown";
        totalAmount = extracted["Total Amount"] ?? "Unknown";
        verdict = extracted["Final Verdict"] ?? "Undetermined";
      });
    } catch (e) {
      setState(() => verdict = "Error: $e");
    }

    setState(() => _loading = false);
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: const CustomMainAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: "Receipt Scanner",
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _imageFile!,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.grey.shade200,
                    ),
                    child: const Center(
                      child: Text("No image selected",
                          style: TextStyle(color: Colors.black45)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: _buttonStyle(),
                    child: const Text("Capture Receipt",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_loading && verdict.isNotEmpty) ...[
              const SizedBox(height: 10),
              _paymentCard(
                icon: Icons.storefront,
                title: "Store Information",
                line1: "Store Name: $storeName",
                line2: "Date: $dateIssued",
              ),
              const SizedBox(height: 15),
              _paymentCard(
                icon: Icons.receipt_long,
                title: "Billing Summary",
                line1: "Total Amount: $totalAmount",
                line2: "Extracted from AI analysis",
              ),
              const SizedBox(height: 15),
              _paymentCard(
                icon: Icons.verified,
                title: "Receipt Status",
                line1: "Verdict: $verdict",
                line2: verdict.toLowerCase().contains("genuine")
                    ? "This appears to be a legitimate receipt."
                    : "This receipt may not be authentic.",
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // CUSTOM CARD
  // ----------------------------------------------------------
  Widget _paymentCard({
    required IconData icon,
    required String title,
    required String line1,
    required String line2,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.black,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(line1, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(line2,
                    style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SECTION CARD
  // ----------------------------------------------------------
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // BUTTON STYLE
  // ----------------------------------------------------------
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
