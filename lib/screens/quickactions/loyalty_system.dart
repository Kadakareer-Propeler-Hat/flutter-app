import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoyaltySystemScreen extends StatefulWidget {
  @override
  State<LoyaltySystemScreen> createState() => _LoyaltySystemPageState();
}

class _LoyaltySystemPageState extends State<LoyaltySystemScreen> {
  int totalPoints = 0;
  String loyaltyTier = "Bronze";
  int nextTierGap = 0;

  @override
  void initState() {
    super.initState();
    loadLoyaltyPoints();
  }

  /// 🔥 SAVE TO FIREBASE (ONLY IF CHANGED)
  Future<void> updateUserLoyaltyStatus(
      String userId, String tier, int points) async {
    final userRef =
    FirebaseFirestore.instance.collection("users").doc(userId);

    final snapshot = await userRef.get();

    final oldTier = snapshot.data()?["loyaltyTier"];
    final oldPoints = snapshot.data()?["loyaltyPoints"];

    // Only update Firestore if something changed
    if (oldTier != tier || oldPoints != points) {
      await userRef.set({
        "loyaltyTier": tier,
        "loyaltyPoints": points,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// 🧮 LOAD POINTS + COMPUTE TIER
  Future<void> loadLoyaltyPoints() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    final loansSnapshot = await FirebaseFirestore.instance
        .collection("loans")
        .where("userId", isEqualTo: userId)
        .get();

    int points = 0;

    for (var doc in loansSnapshot.docs) {
      final data = doc.data();

      bool isActive = data["activeLoad"] ?? false;

      if (isActive) {
        points += 200; // Active loan bonus
        final num principal = data["principal"] ?? 0;
        points += ((principal / 10000).round()) * 50; // Bonus
      }
    }

    final tier = computeTier(points);
    final gap = computeNextTierGap(points);

    // 🔥 Save to Firebase
    await updateUserLoyaltyStatus(userId, tier, points);

    setState(() {
      totalPoints = points;
      loyaltyTier = tier;
      nextTierGap = gap;
    });
  }

  /// 🏆 Tier Rules
  String computeTier(int points) {
    if (points >= 5000) return "Platinum";
    if (points >= 2500) return "Gold";
    if (points >= 1000) return "Silver";
    return "Bronze";
  }

  int computeNextTierGap(int points) {
    if (points >= 5000) return 0;
    if (points >= 2500) return 5000 - points;
    if (points >= 1000) return 2500 - points;
    return 1000 - points;
  }

  Color tierColor(String t) {
    switch (t) {
      case "Gold":
        return const Color(0xFFFFC642);
      case "Silver":
        return Colors.grey.shade400;
      case "Platinum":
        return Colors.blueGrey.shade200;
      default:
        return Colors.amber.shade100;
    }
  }

  /// UI BUILD ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Loyalty System"),
        leading: BackButton(),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            /// ⭐ GOLD MEDAL ICON
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.shade300,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

            SizedBox(height: 12),

            Text(
              "Loyalty System",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 5),

            Text(
              "Earn rewards for being a responsible borrower",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 25),

            /// 🔥 HEADER CARD (POINTS + TIER + PROGRESS)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tierColor(loyaltyTier),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.stars, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "$loyaltyTier Member",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "You've earned $totalPoints points!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  LinearProgressIndicator(
                    value: (loyaltyTier == "Platinum")
                        ? 1
                        : 1 -
                        (nextTierGap /
                            (loyaltyTier == "Gold"
                                ? 2500
                                : loyaltyTier == "Silver"
                                ? 1500
                                : 1000)),
                    backgroundColor: Colors.white38,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    (loyaltyTier == "Platinum")
                        ? "You reached the highest tier!"
                        : "$nextTierGap points to next tier",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            /// 🟫 Bronze Tier
            buildTierCard("Bronze", 0, 999, [
              "5% interest rate discount",
              "Monthly financial tips",
              "Standard customer support",
            ]),

            /// 🥈 Silver Tier
            buildTierCard("Silver", 1000, 2499, [
              "10% interest rate discount",
              "Priority customer support",
              "Waived processing fees",
              "Quarterly financial coaching",
            ]),

            /// 🥇 Gold Tier
            buildTierCard("Gold", 2500, 4999, [
              "15% interest rate discount",
              "Premium support (24/7)",
              "Free payment rescheduling",
              "Monthly financial coaching",
              "Exclusive loan offers",
            ], highlight: loyaltyTier == "Gold"),

            /// 🏆 Platinum Tier
            buildTierCard("Platinum", 5000, 999999, [
              "20% interest rate discount",
              "Dedicated account manager",
              "Unlimited payment flexibility",
              "VIP financial coaching",
              "First access to new products",
              "Special rewards & cashback",
            ]),
          ],
        ),
      ),
    );
  }

  Widget buildTierCard(String title, int min, int max, List<String> perks,
      {bool highlight = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
            color: highlight ? Color(0xFFFAB005) : Colors.grey.shade300,
            width: highlight ? 3 : 1),
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.emoji_events,
                    color: highlight ? Color(0xFFFAB005) : Colors.grey),
                SizedBox(width: 8),
                Text(title,
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              if (highlight)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(0xFFFAB005),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                  Text("Current Tier", style: TextStyle(color: Colors.white)),
                )
            ],
          ),
          SizedBox(height: 10),
          Text("$min-$max points",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          SizedBox(height: 10),
          ...perks.map((p) => Row(
            children: [
              Icon(Icons.check, color: Colors.green, size: 18),
              SizedBox(width: 5),
              Expanded(child: Text(p)),
            ],
          )),
        ],
      ),
    );
  }
}
