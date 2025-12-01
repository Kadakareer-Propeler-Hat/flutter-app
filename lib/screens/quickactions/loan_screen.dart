// lib/screens/loan_screen.dart
import 'dart:math';
import 'package:horizonai/components/custom_mainappbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  static const routeName = '/loan';

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.84);
  int _currentIndex = 0;
  bool activeLoad = false;

  String _calculateTier(int points) {
    if (points >= 5000) return "Platinum";
    if (points >= 2500) return "Gold";
    if (points >= 1000) return "Silver";
    return "Bronze";
  }

  String _userTier = "Bronze";
  int _userPoints = 0;
  bool _loadingTier = true;



  // Installment options (months)
  final List<int> _plans = [3, 6, 12, 24];
  int _selectedPlan = 12;

  // Downpayment controller
  final TextEditingController _downPaymentCtrl = TextEditingController(text: '0');

  // Animation for Apply Button
  late AnimationController _animController;

  // Sample product catalog: 20 phone models (brand, model, price, description)
  final List<Map<String, dynamic>> _products = [
    {"brand": "Samsung", "model": "Galaxy S24 Ultra", "price": 79999, "desc": "Flagship 200MP camera, bright AMOLED, 5000mAh.", "image": "assets/products/s24plus.jpg"},
    {"brand": "Samsung", "model": "Galaxy S24+", "price": 59999, "desc": "Excellent camera & battery for power users.", "image": "assets/products/s24plus.jpg"},
    {"brand": "Samsung", "model": "Galaxy A55", "price": 21999, "desc": "Great midrange value with AMOLED display.", "image": "assets/products/a55.png"},
    {"brand": "Apple", "model": "iPhone 15 Pro Max", "price": 99999, "desc": "Top-tier performance and pro camera system.", "image": "assets/products/iphone15promax.png"},
    {"brand": "Apple", "model": "iPhone 15", "price": 64999, "desc": "Balanced flagship experience.", "image": "assets/products/iphone15.jpg"},
    {"brand": "Apple", "model": "iPhone SE (2024)", "price": 21999, "desc": "Compact, fast, and budget-friendly.", "image": "assets/products/iphonese2024.jpg"},
    {"brand": "Xiaomi", "model": "12T Pro", "price": 34999, "desc": "High specs for the price, 200MP camera.", "image": "assets/products/xiaomi12tpro.png"},
    {"brand": "Xiaomi", "model": "Redmi Note 13 Pro", "price": 17999, "desc": "Value leader with solid battery life.", "image": "assets/products/redminote13pro.png"},
    {"brand": "OPPO", "model": "Find X6 Pro", "price": 79999, "desc": "Sleek design and powerful camera tuning.", "image": "assets/products/findx6pro.jpg"},
    {"brand": "OPPO", "model": "Reno 12", "price": 23999, "desc": "Stylish and selfie-focused device.", "image": "assets/products/reno12.png"},
    {"brand": "Vivo", "model": "X100 Pro", "price": 66999, "desc": "Impressive imaging with Zeiss optics.", "image": "assets/products/vivo100pro.png"},
    {"brand": "Vivo", "model": "Y200", "price": 14999, "desc": "Budget phone with clean software.", "image": "assets/products/vivoy200.png"},
    {"brand": "Realme", "model": "GT 6", "price": 29999, "desc": "Performance-oriented with fast charging.", "image": "assets/products/realmegt6.jpg"},
    {"brand": "Realme", "model": "C55", "price": 7999, "desc": "Ultra budget with bright display.", "image": "assets/products/realmec55.jpg"},
    {"brand": "Google", "model": "Pixel 8 Pro", "price": 66999, "desc": "Pure Android experience, excellent camera AI.", "image": "assets/products/pixel8pro.jpg"},
    {"brand": "Google", "model": "Pixel 8a", "price": 25999, "desc": "Excellent value Pixel with clean UI.", "image": "assets/products/pixel8a.jpg"},
    {"brand": "OnePlus", "model": "11 Pro", "price": 39999, "desc": "Smooth UI, flagship speed and charging.", "image": "assets/products/oneplus11pro.png"},
    {"brand": "OnePlus", "model": "Nord CE", "price": 12999, "desc": "Balanced midrange performer.", "image": "assets/products/oneplusnordce.png"},
    {"brand": "Sony", "model": "Xperia 1 V", "price": 84999, "desc": "Cinema-grade display and camera tools.", "image": "assets/products/xperia1v.jpg"},
    {"brand": "Motorola", "model": "Edge 40", "price": 24999, "desc": "Clean software and long battery life.", "image": "assets/products/edge40.png"},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _pageController.addListener(_pageListener);
    _getUserTier();

  }

  void _pageListener() {
    final page = _pageController.page ?? 0.0;
    setState(() {
      _currentIndex = page.round();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    _animController.dispose();
    _downPaymentCtrl.dispose();
    super.dispose();
  }

  // interest rate by months (simple illustrative rates)
  double _interestRateForMonths(int months) {
    if (months <= 3) return 0.03;
    if (months <= 6) return 0.05;
    if (months <= 12) return 0.09;
    return 0.14; // 24 months
  }

  // compute installment price carefully (integer arithmetic base)
  Map<String, dynamic> _computeInstallment(double price, double downPayment, int months) {
    final principal = max(0, (price - downPayment));

    double baseRate = _interestRateForMonths(months);

    // Apply Tier Benefit Discount
    double discount = 0.0;
    if (_userTier == "Silver") discount = 0.02;
    if (_userTier == "Gold") discount = 0.04;
    if (_userTier == "Platinum") discount = 0.06;

    double finalRate = baseRate - discount;
    if (finalRate < 0) finalRate = 0;

    final interest = principal * finalRate;
    final total = principal + interest;
    final installmentEach = (total / months).ceilToDouble();

    return {
      "principal": principal,
      "interest": interest,
      "total": total,
      "perMonth": installmentEach,
      "rate": finalRate,
      "originalRate": baseRate,
      "discountApplied": discount,
    };
  }


  Future<void> _getUserTier() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get(); // <-- FIXED ❗ read root document

    setState(() {
      _userTier = doc.data()?["loyaltyTier"] ?? "Bronze";
      _userPoints = (doc.data()?["loyaltyPoints"] ?? 0).toInt();
      _loadingTier = false;
    });
  }



  Future<void> _applyLoan(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be signed in to apply.")),
      );
      return;
    }

    // Parse downpayment
    final dpRaw = double.tryParse(_downPaymentCtrl.text.replaceAll(",", "").trim()) ?? 0.0;
    final months = _selectedPlan;
    final price = (product['price'] as num).toDouble();

    // Compute
    final computed = _computeInstallment(price, dpRaw, months);

    // Build payload
    final payload = {
      "userId": user.uid,
      "productBrand": product['brand'],
      "productModel": product['model'],
      "price": price,
      "downPayment": dpRaw,
      "installmentMonths": months,
      "installmentPrice": computed['perMonth'],
      "planType": "${months} months",
      "createdAt": FieldValue.serverTimestamp(),
      "activeLoad": activeLoad,
      "computed": {
        "principal": computed['principal'],
        "interest": computed['interest'],
        "total": computed['total'],
        "rate": computed['rate'],
      },
    };

    try {
      // Animate feedback
      await _animController.forward();
      await FirebaseFirestore.instance.collection('loans').add(payload);
      await _animController.reverse();

      // ---------------------------------------------------------
      // 🔥 LOYALTY POINTS SYSTEM (Integrated)
      // ---------------------------------------------------------
      if (activeLoad == true) {
        int principal = computed['principal'].toInt();

        // +50 pts per ₱10,000 principal
        int earned = ((principal / 10000).round()) * 50;

        // update loyalty document
        final userRef = FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid);

        final snap = await userRef.get();
        int oldPoints = (snap.data()?["loyaltyPoints"] ?? 0).toInt();

        int newPoints = oldPoints + earned;
        String newTier = _calculateTier(newPoints);

        await userRef.set({
          "loyaltyPoints": newPoints,
          "loyaltyTier": newTier,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
        // ---------------------------------------------------------

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Loan application saved successfully.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    }
  }


  Widget _buildProductCard(int index, Map<String, dynamic> product, bool active) {
    final bool isFocused = index == _currentIndex;
    return AnimatedScale(
      duration: const Duration(milliseconds: 400),
      scale: isFocused ? 1.0 : 0.94,
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: isFocused ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // top banner - brand & model
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF781B34).withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      product['brand'][0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF781B34)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${product['brand']} · ${product['model']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product['desc'],
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // visual product area (placeholder)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    product['image'],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),


            // price row and quick details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Price", style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text(
                        "₱${(product['price'] as num).toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      )
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Active Load", style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 6),
                      Switch(
                        value: activeLoad,
                        activeColor: const Color(0xFFE86F64),
                        onChanged: (v) => setState(() => activeLoad = v),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlanChips(double price) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: _plans.map((m) {
        final bool selected = m == _selectedPlan;
        final rate = _interestRateForMonths(m);
        return ChoiceChip(
          label: Text("$m mo"),
          selected: selected,
          onSelected: (_) => setState(() => _selectedPlan = m),
          selectedColor: const Color(0xFFE86F64),
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstallmentSummary(Map<String, dynamic> product) {
    final price = (product['price'] as num).toDouble();

    final dp = double.tryParse(
      _downPaymentCtrl.text.replaceAll(",", "").trim(),
    ) ??
        0.0;

    final computed = _computeInstallment(price, dp, _selectedPlan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Installment Summary",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Principal + Interest row
        Row(
          children: [
            Expanded(
              child: Text("Principal: ₱${computed['principal'].toStringAsFixed(0)}"),
            ),
            Expanded(
              child: Text("Interest: ₱${computed['interest'].toStringAsFixed(0)}"),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Total + Months row
        Row(
          children: [
            Expanded(
              child: Text("Total: ₱${computed['total'].toStringAsFixed(0)}"),
            ),
            Expanded(
              child: Text("${_selectedPlan} months"),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Monthly payment container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF781B34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "₱${computed['perMonth'].toStringAsFixed(0)} / mo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              // Apply button
              ElevatedButton(
                onPressed: () => _applyLoan(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF781B34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (_, __) {
                    final t = _animController.value;
                    return Opacity(
                      opacity: 1.0 - (t * 0.6),
                      child: const Text("Apply / Buy"),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // top app bar with back button
  PreferredSizeWidget _topBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        padding: const EdgeInsets.only(top: 18, left: 12, right: 12, bottom: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text(
              "Loan Marketplace",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(LucideIcons.filter),
              onPressed: () {
                // placeholder for filters
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Filters coming soon")));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _products[_currentIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: const CustomMainAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // CAROUSEL
            SizedBox(
              height: 360,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return _buildProductCard(index, p, index == _currentIndex);
                },
              ),
            ),

            // page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_products.length, (i) {
                  final bool active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFE86F64) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // details + form (scrollable)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _loadingTier
                          ? const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.amber,
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Tier: $_userTier",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "$_userPoints pts",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // product title & price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${current['brand']} ${current['model']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          Text(
                            "₱${(current['price'] as num).toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF781B34)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // description
                      Text(current['desc'], style: TextStyle(color: Colors.grey[700])),

                      const SizedBox(height: 14),
                      const Divider(),

                      const SizedBox(height: 10),
                      const Text("Choose plan", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildPlanChips((current['price'] as num).toDouble()),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _downPaymentCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₱',
                                hintText: 'Down payment',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text("Plan", style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 6),
                                Text("$_selectedPlan mo", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 18),
                      _buildInstallmentSummary(current),

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() {
                                _downPaymentCtrl.text = '0';
                                _selectedPlan = 12;
                              }),
                              icon: const Icon(LucideIcons.refreshCw),
                              label: const Text("Reset"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _applyLoan(current),
                              icon: const Icon(LucideIcons.creditCard,  color: Colors.white),
                              label: const Text(
                                "Quick Apply",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF781B34),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      // notes and small animation
                      Row(
                        children: [
                          const Icon(LucideIcons.info, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Your application will be saved in your account. You can manage or cancel active loads later.", style: TextStyle(color: Colors.grey[700]))),
                        ],
                      ),

                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
