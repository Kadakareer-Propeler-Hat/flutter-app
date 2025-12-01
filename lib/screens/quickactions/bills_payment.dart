// lib/screens/bills_pay.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:horizonai/components/custom_mainappbar.dart';

import '../../service/paypal_payment.dart';

class BillsPayScreen extends StatefulWidget {
  const BillsPayScreen({super.key});

  @override
  State<BillsPayScreen> createState() => _BillsPayScreenState();
}

class _BillsPayScreenState extends State<BillsPayScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.86);
  int _page = 0;
  bool _paying = false;

  final NumberFormat currency =
  NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  final String loadsCollection = "loans";
  final Color _maroon = const Color(0xFF8B1538);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// ------------ Map Firestore Loan ------------
  Map<String, dynamic> _mapLoan(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    final brand = (d['productBrand'] ?? d['brand'] ?? '').toString();
    final model =
    (d['productModel'] ?? d['model'] ?? '').toString();

    final totalRaw = d['total'] ?? d['price'] ?? d['principal'] ?? 0;
    final total = (totalRaw is num)
        ? totalRaw.toDouble()
        : double.tryParse(totalRaw.toString()) ?? 0.0;

    double monthly = 0.0;
    if (d['installmentPrice'] != null) {
      final ip = d['installmentPrice'];
      monthly =
      (ip is num) ? ip.toDouble() : double.tryParse(ip.toString()) ?? 0.0;
    } else {
      final months = (d['installmentMonths'] ?? 12);
      final monthsNum = (months is num)
          ? months.toInt()
          : int.tryParse(months.toString()) ?? 12;
      monthly = monthsNum > 0 ? (total / monthsNum) : total;
    }

    final remRaw = d['remaining'] ?? d['balance'] ?? total;
    final remaining = (remRaw is num)
        ? remRaw.toDouble()
        : double.tryParse(remRaw.toString()) ?? total;

    final plan =
        d['planType'] ?? "${d['installmentMonths'] ?? 12} months";

    return {
      'id': doc.id,
      'brand': brand,
      'model': model,
      'description': [brand, model]
          .where((s) => s.toString().trim().isNotEmpty)
          .join(' ')
          .trim(),
      'total': total,
      'monthly': monthly,
      'remaining': remaining,
      'plan': plan,
      'raw': d,
    };
  }

  /// ------------ Pay Process (NO GEMINI ANYMORE) ------------
  Future<void> _payLoadDocument(DocumentSnapshot doc) async {
    if (_paying) return;
    setState(() => _paying = true);

    final mapped = _mapLoan(doc);
    final id = mapped['id'] as String;
    final desc = mapped['description'] as String;
    final model = mapped['model'] as String;
    final total = mapped['total'] as double;
    final remaining = mapped['remaining'] as double;
    final monthly = mapped['monthly'] as double;
    final payAmount = monthly;

    try {
      // Create PayPal order
      final order = await PayPalConfig.createOrder(
        amount: payAmount,
        description: "$desc ${model.isNotEmpty ? '($model)' : ''}",
      );

      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to create order.")));
        setState(() => _paying = false);
        return;
      }

      final orderId = order['id'] ?? "";
      final approvalUrl = order["links"]?.firstWhere(
            (l) => l["rel"] == "approve",
        orElse: () => null,
      )?["href"];

      if (approvalUrl != null) {
        await launchUrl(
          Uri.parse(approvalUrl),
          mode: LaunchMode.externalApplication,
        );
      }

      // SIMULATED SUCCESS (as in your original logic)
      final now = Timestamp.now();
      final newRemaining =
      (remaining - payAmount).clamp(0.0, double.infinity);
      final finished = newRemaining <= 0.001;

      await FirebaseFirestore.instance
          .collection(loadsCollection)
          .doc(id)
          .update({
        'remaining': newRemaining,
        'lastPaymentAt': now,
        'activeLoad': !finished,
      });

      await FirebaseFirestore.instance
          .collection(loadsCollection)
          .doc(id)
          .collection('payments')
          .add({
        'amount': payAmount,
        'currency': 'PHP',
        'paidAt': now,
        'paypalOrder': orderId,
        'note': 'Simulated PayPal success',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text("Payment ${currency.format(payAmount)} applied.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Payment error: $e")));
    } finally {
      setState(() => _paying = false);
    }
  }

  /// ------------ Build Loan Card ------------
  Widget _buildCarouselItem(DocumentSnapshot doc, bool active) {
    final loan = _mapLoan(doc);

    final desc = loan['description'] as String;
    final model = loan['model'] as String;
    final total = loan['total'] as double;
    final remaining = loan['remaining'] as double;
    final monthly = loan['monthly'] as double;
    final progress =
    (total > 0) ? ((total - remaining) / total).clamp(0.0, 1.0) : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      margin:
      EdgeInsets.symmetric(vertical: active ? 8 : 18, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Colors.white, Colors.white]),
        border: Border.all(
            color: _maroon.withOpacity(active ? 1.0 : 0.16),
            width: active ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(active ? 0.08 : 0.03),
            blurRadius: active ? 14 : 6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _maroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone_android, color: _maroon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  desc.isNotEmpty ? desc : 'Loan',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _maroon.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loan['plan'].toString(),
                  style: TextStyle(
                      color: _maroon, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          if (model.isNotEmpty)
            Text("Model: $model",
                style: TextStyle(color: Colors.grey[700])),

          const SizedBox(height: 12),

          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Remaining",
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  Text(currency.format(remaining),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Monthly",
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  Text(currency.format(monthly),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _maroon)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: _maroon,
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  _paying ? null : () => _showDetailsAndPay(doc),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _maroon),
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Pay Now",
                      style: TextStyle(
                          color: _maroon,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _paying ? null : () => _showQuickInfo(doc),
                icon:
                const Icon(Icons.info_outline, color: Colors.white),
                label: const Text(
                  "Details",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _maroon,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ------------ Payment & Info Dialogs ------------
  void _showQuickInfo(DocumentSnapshot doc) {
    final loan = _mapLoan(doc);
    final raw = loan['raw'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(
                        loan['description'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      )),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close))
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          "Total: ${currency.format(loan['total'])}")),
                  Expanded(
                      child: Text(
                        "Remaining: ${currency.format(loan['remaining'])}",
                        textAlign: TextAlign.end,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              if (raw['rate'] != null)
                Text("Interest rate: ${raw['rate']}"),
              if (raw['installmentMonths'] != null)
                Text("Term: ${raw['installmentMonths']} months"),
              const SizedBox(height: 12),
              if (raw['notes'] != null)
                Text(raw['notes'], style: const TextStyle(color: Colors.black54)),

              const SizedBox(height: 16),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection(loadsCollection)
                    .doc(loan['id'])
                    .collection('payments')
                    .orderBy('paidAt', descending: true)
                    .limit(5)
                    .get(),
                builder: (c, snap) {
                  if (snap.hasError) return const SizedBox();
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final payments = snap.data!.docs;
                  if (payments.isEmpty) {
                    return const Text(
                      "No payments recorded yet.",
                      style: TextStyle(color: Colors.black54),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Recent payments",
                          style:
                          TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...payments.map((p) {
                        final pm =
                            p.data() as Map<String, dynamic>? ?? {};
                        final amt = pm['amount'] ?? 0;
                        final paidAt = pm['paidAt'] is Timestamp
                            ? (pm['paidAt'] as Timestamp).toDate()
                            : null;

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(currency.format(
                              (amt is num)
                                  ? amt.toDouble()
                                  : double.tryParse(amt.toString()) ??
                                  0.0)),
                          subtitle: Text(paidAt != null
                              ? DateFormat.yMMMd()
                              .add_jm()
                              .format(paidAt)
                              : ''),
                          trailing: pm['note'] != null
                              ? Text(pm['note'],
                              style: const TextStyle(fontSize: 12))
                              : null,
                        );
                      }).toList()
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _maroon,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Center(child: Text("Close")),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDetailsAndPay(DocumentSnapshot doc) async {
    final loan = _mapLoan(doc);
    final payAmt = loan['monthly'] as double;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payments_rounded,
                    size: 58, color: _maroon),
                const SizedBox(height: 14),
                const Text("Confirm Payment",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("You are about to pay:",
                    style: TextStyle(
                        fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                Text(currency.format(payAmt),
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _maroon)),
                const SizedBox(height: 6),
                Text(
                  loan['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, false),
                        child: const Text("Cancel"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _maroon,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Proceed",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _payLoadDocument(doc);
    }
  }

  /// ------------ 3 Payment Feature Cards ------------
  Widget _buildFeatureCards() {
    final features = [
      {
        "icon": Icons.speed,
        "title": "Fast Payments",
        "desc":
        "Experience quick and seamless processing with each bill payment."
      },
      {
        "icon": Icons.security,
        "title": "Secured Transactions",
        "desc":
        "Every payment is encrypted and protected with multi-layer security."
      },
      {
        "icon": Icons.history,
        "title": "Payment Tracking",
        "desc":
        "View your history instantly and never lose track of your bills."
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding:
          EdgeInsets.only(left: 18, right: 18, bottom: 10, top: 20),
          child: Text(
            "Payment Features",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        ...features.map((f) {
          return Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 5)),
              ],
              border:
              Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _maroon.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f['icon'] as IconData,
                      color: _maroon, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(f['desc'] as String,
                          style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.4)),
                    ],
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// ------------ Build UI ------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CustomMainAppBar(),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(loadsCollection)
              .where('activeLoad', isEqualTo: true)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 18),

                  // If no loads
                  if (docs.isEmpty)
                    Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 86,
                            color: _maroon.withOpacity(0.95)),
                        const SizedBox(height: 12),
                        const Text("No active loads",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text("You're all caught up!",
                            style: TextStyle(
                                color: Colors.grey[700])),
                      ],
                    )
                  else
                    SizedBox(
                      height: 340,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: docs.length,
                        onPageChanged: (i) =>
                            setState(() => _page = i),
                        itemBuilder: (c, i) {
                          final active = i == _page;
                          return _buildCarouselItem(
                              docs[i], active);
                        },
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Page indicator
                  if (docs.isNotEmpty)
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: List.generate(docs.length, (i) {
                        final isActive = i == _page;
                        return AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 6),
                          width: isActive ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? _maroon
                                : Colors.grey.shade300,
                            borderRadius:
                            BorderRadius.circular(6),
                          ),
                        );
                      }),
                    ),

                  const SizedBox(height: 20),

                  // 3 Feature Cards
                  _buildFeatureCards(),

                  const SizedBox(height: 34),

                  if (_paying)
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator()),

                  const SizedBox(height: 34),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
