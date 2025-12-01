import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HorizonAI extends StatefulWidget {
  const HorizonAI({Key? key}) : super(key: key);

  @override
  State<HorizonAI> createState() => _HorizonAIState();
}

class _HorizonAIState extends State<HorizonAI> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _botTyping = false;

  final String _apiKey = "AIzaSyB5NqtrPK-A9gjZZ-WCPF4hGYrsOkeWIH8";

  @override
  void initState() {
    super.initState();
  }

  /// Auto-scroll to latest message
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// -----------------------------
  /// FETCH USER CONTEXT FROM FIREBASE
  /// -----------------------------
  Future<String> _getUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "";

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    final tier = data["tier"] ?? "Unknown Tier";
    final credit = data["credit_line"] ?? "Not Specified";
    final balance = data["balance"] ?? "Not Available";

    return """
User Financial Profile:
- Tier Level: $tier
- Total Credit Line: $credit
- Account Balance: $balance

Use this information to answer questions accurately and personally.
If the user asks for their tier, credit limit, credit history, or benefits, respond using this context.
""";
  }

  /// -----------------------------
  /// SEND MESSAGE TO GEMINI
  /// -----------------------------
  Future<void> _sendMessage(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Save user message
    await FirebaseFirestore.instance
        .collection("horizon_ai_chats")
        .doc(user.uid)
        .collection("messages")
        .add({
      "sender": "user",
      "text": text,
      "timestamp": Timestamp.now(),
    });

    setState(() => _botTyping = true);
    _scrollToBottom();

    // Fetch user data for context
    final systemContext = await _getUserContext();

    // Gemini Request
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                "You are Horizon AI, a financial assistant inside the Horizon Lending app.\n"
                    "This is the user's account context:\n\n"
                    "$systemContext\n\n"
                    "User asked: $text\n\n"
                    "Respond clearly and helpfully."
              }
            ]
          }
        ]
      }),
    );

    String botReply = "I'm having trouble responding right now.";

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      botReply =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? botReply;
    }

    // Save bot reply
    await FirebaseFirestore.instance
        .collection("horizon_ai_chats")
        .doc(user.uid)
        .collection("messages")
        .add({
      "sender": "bot",
      "text": botReply,
      "timestamp": Timestamp.now(),
    });

    setState(() => _botTyping = false);
    _scrollToBottom();
  }

  /// -----------------------------
  /// UI STARTS HERE
  /// -----------------------------
  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF7B001E);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F7),
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 0,
        title: const Text("Horizon AI", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("horizon_ai_chats")
                  .doc(user.uid)
                  .collection("messages")
                  .orderBy("timestamp")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: maroon),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length + (_botTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_botTyping && index == messages.length) {
                      return _buildTypingBubble();
                    }

                    final msg = messages[index];
                    final isUser = msg["sender"] == "user";

                    return Align(
                      alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? maroon : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(.07),
                                blurRadius: 6)
                          ],
                        ),
                        child: Text(
                          msg["text"],
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Ask something...",
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _sendMessage(value.trim());
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: maroon,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        _sendMessage(text);
                        _controller.clear();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// BOT TYPING BUBBLE
  Widget _buildTypingBubble() {
    const maroon = Color(0xFF7B001E);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SpinKitThreeBounce(
          color: maroon,
          size: 18,
        ),
      ),
    );
  }
}
