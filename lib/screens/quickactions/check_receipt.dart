import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CheckReceiptScreen extends StatefulWidget {
  const CheckReceiptScreen({super.key});

  @override
  State<CheckReceiptScreen> createState() => _CheckReceiptScreenState();
}

class _CheckReceiptScreenState extends State<CheckReceiptScreen>
    with SingleTickerProviderStateMixin {
  File? _imageFile;
  String _extractedText = "";
  String _analysis = "";
  bool _loading = false;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => _imageFile = File(file.path));
      await _runOCR();
    }
  }

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

    setState(() => _extractedText = buffer.toString());

    await _callGemini(_extractedText);
  }

  Future<void> _callGemini(String text) async {
    const apiKey = "AIzaSyB5NqtrPK-A9gjZZ-WCPF4hGYrsOkeWIH8";

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this receipt text. Determine if authentic, summarize key details, and provide HorizonAI's final verdict (concise):\n$text"
            }
          ]
        }
      ]
    };

    final res = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final output = data["candidates"][0]["content"]["parts"][0]["text"];
      setState(() => _analysis = output);
    } else {
      setState(() => _analysis = "Error calling Gemini: ${res.body}");
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Check Receipt", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildCard(
              child: Column(
                children: [
                  const Text(
                    "Receipt Scanner",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, height: 220, fit: BoxFit.cover),
                  )
                      : Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: const Center(
                      child: Text("No image selected",
                          style: TextStyle(color: Colors.black45)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Capture Receipt"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_extractedText.isNotEmpty)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Extracted Text",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(_extractedText, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            if (_loading)
              const Center(child: CircularProgressIndicator()),

            if (_analysis.isNotEmpty)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("HorizonAI Conclusion",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(_analysis, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }
}