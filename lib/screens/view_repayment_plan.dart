// lib/screens/view_repayment_plan.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:horizonai/components/custom_mainappbar.dart';

class ViewRepaymentPlanScreen extends StatefulWidget {
  const ViewRepaymentPlanScreen({Key? key}) : super(key: key);

  @override
  State<ViewRepaymentPlanScreen> createState() =>
      _ViewRepaymentPlanScreenState();
}

class _ViewRepaymentPlanScreenState extends State<ViewRepaymentPlanScreen> {
  final double sectionSpacing = 20;
  final double cardSpacing = 12;
  final BorderRadius radius = BorderRadius.circular(16);

  List<QueryDocumentSnapshot> myLoans = [];
  final Color _maroon = const Color(0xFF8B1538);
  final NumberFormat currency =
  NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  String? _selectedLoanId;
  Map<String, dynamic>? _selectedLoanData;
  List<Map<String, dynamic>> _amortization = [];

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance.collection("loans").snapshots().listen((snap) {
      setState(() {
        myLoans = snap.docs;
      });
    });
  }

  // =============================
  // AMORTIZATION BUILDERS
  // =============================

  List<Map<String, dynamic>> _buildAmortization({
    required double principal,
    required double annualRate,
    required int months,
    required double monthlyPayment,
    DateTime? startDate,
  }) {
    final schedule = <Map<String, dynamic>>[];
    double balance = principal;
    final monthlyRate = annualRate / 12.0;
    DateTime date = startDate ?? DateTime.now();

    for (int i = 1; i <= months; i++) {
      double interest = balance * monthlyRate;
      double principalPaid = monthlyPayment - interest;

      if (principalPaid > balance) {
        principalPaid = balance;
      } else if (principalPaid < 0) {
        principalPaid = 0;
      }

      balance = max(0, balance - principalPaid);

      schedule.add({
        'month': i,
        'date': DateTime(date.year, date.month + i - 1, date.day),
        'payment': principalPaid + interest,
        'interest': interest,
        'principal': principalPaid,
        'balance': balance,
      });

      if (balance <= 0.001) break;
    }

    return schedule;
  }

  double _computeMonthlyPayment(double principal, double annualRate, int months) {
    if (months <= 0) return principal;
    final r = annualRate / 12.0;

    if (r == 0) return principal / months;

    final denom = 1 - pow(1 + r, -months);
    return denom == 0 ? principal / months : principal * (r / denom);
  }

  void _prepareSchedule(Map<String, dynamic> loan) {
    double parseDouble(dynamic v, [double fb = 0]) {
      if (v == null) return fb;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fb;
      return fb;
    }

    final principal =
    parseDouble(loan['principal'], parseDouble(loan['price'], 0));
    final rate = parseDouble(loan['rate'], 0);
    final months = (loan['installmentMonths'] is num)
        ? (loan['installmentMonths'] as num).toInt()
        : int.tryParse(loan['installmentMonths']?.toString() ?? "") ?? 12;

    final regMonthly = parseDouble(loan['installmentPrice'], 0);
    final monthlyPayment = regMonthly > 0
        ? regMonthly
        : _computeMonthlyPayment(principal, rate, months);

    DateTime? start;
    final createdAt = loan['createdAt'];
    if (createdAt is Timestamp) start = createdAt.toDate();
    if (createdAt is DateTime) start = createdAt;
    if (createdAt is String) start = DateTime.tryParse(createdAt);

    final schedule = _buildAmortization(
      principal: principal,
      annualRate: rate,
      months: months,
      monthlyPayment: monthlyPayment,
      startDate: start,
    );

    setState(() {
      _selectedLoanData = loan;
      _amortization = schedule;
    });
  }

  // =============================
  // LOAN SELECTOR
  // =============================

  Widget _loanSelector(AsyncSnapshot<QuerySnapshot> snap) {
    final docs = snap.data!.docs;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Select a loan product"),
          value: _selectedLoanId,
          items: docs.map((d) {
            final data = (d.data() as Map<String, dynamic>);
            final brand = (data['productBrand'] ?? "").toString();
            final model = (data['productModel'] ?? "").toString();
            final title = brand.isEmpty ? model : "$brand $model";
            final remaining = data['remaining'];

            String remText = "";
            if (remaining != null) {
              if (remaining is num) remText = currency.format(remaining);
              if (remaining is String) {
                final n = double.tryParse(remaining);
                if (n != null) remText = currency.format(n);
              }
            }

            return DropdownMenuItem(
              value: d.id,
              child: Row(
                children: [
                  Expanded(child: Text(title.isEmpty ? d.id : title)),
                  Text(remText,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;

            setState(() {
              _selectedLoanId = val;
              _selectedLoanData = null;
              _amortization = [];
            });

            final doc = docs.firstWhere((e) => e.id == val);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _prepareSchedule(doc.data() as Map<String, dynamic>);
            });
          },
        ),
      ),
    );
  }

  // =============================
  // CHARTS
  // =============================

  Widget _balanceLineChart() {
    if (_amortization.isEmpty) {
      return Center(child: Text("No schedule to show"));
    }

    final spots = _amortization
        .map((e) => FlSpot(
      (e['month'] as int).toDouble(),
      (e['balance'] as num).toDouble(),
    ))
        .toList();


    double maxY = _amortization.first['balance'].toDouble();
    double interval = (maxY / 4).roundToDouble();


    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: spots.length.toDouble(),
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _maroon,
              barWidth: 3,
              dotData: FlDotData(show: false),
            )
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "₱${(value ~/ 1000)}K",
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  if (v % max(1, (spots.length ~/ 4)) == 0) {
                    return Text("M${v.toInt()}");
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _principalInterestPie() {
    if (_amortization.isEmpty) return const SizedBox.shrink();

    final totalInterest = _amortization.fold<double>(
      0.0,
          (p, e) => p + (e['interest'] as num).toDouble(),
    );

    final totalPrincipal = _amortization.fold<double>(
      0.0,
          (p, e) => p + (e['principal'] as num).toDouble(),
    );


    if (totalInterest == 0 && totalPrincipal == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(
                    value: totalPrincipal,
                    color: Colors.green,
                    title: "Principal\n${currency.format(totalPrincipal)}",
                    radius: 46,
                    titleStyle:
                    const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: totalInterest,
                    color: Colors.orange,
                    title: "Interest\n${currency.format(totalInterest)}",
                    radius: 46,
                    titleStyle:
                    const TextStyle(fontSize: 12, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, "Principal",
                  currency.format(totalPrincipal)),
              const SizedBox(height: 8),
              _legendDot(
                  Colors.orange, "Interest", currency.format(totalInterest)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label, String value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(label), Text(value, style: const TextStyle(fontSize: 12))]),
      ],
    );
  }

  // =============================
  // AMORTIZATION TABLE
  // =============================

  Widget _amortizationTable() {
    if (_amortization.isEmpty) {
      return Center(child: Text("No schedule available"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Month")),
          DataColumn(label: Text("Payment")),
          DataColumn(label: Text("Principal")),
          DataColumn(label: Text("Interest")),
          DataColumn(label: Text("Balance")),
        ],
        rows: _amortization
            .map(
              (e) => DataRow(cells: [
            DataCell(Text(e['month'].toString())),
            DataCell(Text(currency.format(e['payment']))),
            DataCell(Text(currency.format(e['principal']))),
            DataCell(Text(currency.format(e['interest']))),
            DataCell(Text(currency.format(e['balance']))),
          ]),
        )
            .toList(),
      ),
    );
  }

  // =============================
  // GENERATE SMART TIPS
  // =============================

  List<String> _generateTips(
      Map<String, dynamic> loan, List<Map<String, dynamic>> sched) {
    double parseDouble(dynamic v, [double fb = 0]) {
      if (v == null) return fb;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fb;
      return fb;
    }

    final tips = <String>[];
    final rate = parseDouble(loan['rate'], 0);
    final remaining =
    parseDouble(loan['remaining'], parseDouble(loan['total'], 0));
    final monthly = sched.isNotEmpty ? sched.first['payment'] : 0.0;

    tips.add("Round up your monthly payment by ₱${(monthly * 0.1).round()}.");

    if (rate > 0.08) {
      tips.add(
          "High interest rate. Paying extra principal can save you more money.");
    } else if (rate > 0) {
      tips.add("Your interest is manageable—stay consistent.");
    } else {
      tips.add("No interest—focus on finishing early.");
    }

    tips.add("Keep an emergency buffer of ₱1,000–₱3,000 for safety.");

    if (sched.isNotEmpty) {
      final midIndex = (sched.length / 2).ceil() - 1;
      final bal = sched[midIndex]['balance'];
      tips.add("Halfway through, your balance will be ${currency.format(bal)}.");
    }

    tips.add("Use bonuses or windfalls to reduce principal faster.");

    return tips;
  }

  // =============================
  // BUILD UI
  // =============================

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final loansQuery = FirebaseFirestore.instance
        .collection('loans')
        .where('userId', isEqualTo: uid)
        .where('activeLoad', isEqualTo: true)
        .orderBy('createdAt', descending: true);


    return Scaffold(
      appBar: const CustomMainAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: loansQuery.snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text("You have no loans."));
          }

          // AUTO-SELECT FIRST
          if (_selectedLoanId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final first = docs.first;
                _selectedLoanId = first.id;
                _prepareSchedule(first.data() as Map<String, dynamic>);
                setState(() {});
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _loanSelector(snap),
                const SizedBox(height: 12),

                // SUMMARY CARDS
                Row(
                  children: [
                    Expanded(child: _buildRemainingCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMonthlyCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTermCard()),
                  ],
                ),

                const SizedBox(height: 16),

                // CHART / PIE
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Balance Projection",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _balanceLineChart(),
                      const SizedBox(height: 20),
                      _principalInterestPie(),
                    ],
                  ),
                ),


                const SizedBox(height: 16),

                if (_selectedLoanData != null) ...[
                  const Text("Smart Tips",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._generateTips(_selectedLoanData!, _amortization)
                      .map(
                        (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: _maroon,
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t)),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                  const SizedBox(height: 14),
                ],

                const Text("Amortization Schedule",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // TABLE WRAPPED WITH FIXED HEIGHT
                Container(
                  height: 340, // ✔ SCROLLABLE TABLE BUT FITS SCREEN
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: _amortizationTable(),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Colors.black87),

          const SizedBox(height: 6),

          // TITLE (auto ellipsis, never expands)
          SizedBox(
            height: 18,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // VALUE (auto-shrink using FittedBox)
          SizedBox(
            height: 24,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRemainingCard() {
    if (_selectedLoanData == null) {
      return _summaryCard("Remaining", "—", Icons.money_off);
    }

    dynamic r = _selectedLoanData!['remaining'];
    dynamic t = _selectedLoanData!['total'];

    double rem = 0;
    if (r is num) rem = r.toDouble();
    else if (t is num) rem = t.toDouble();
    else rem = double.tryParse(r?.toString() ?? t?.toString() ?? "0") ?? 0;

    return _summaryCard("Remaining", currency.format(rem), Icons.money_off);
  }

  Widget _buildMonthlyCard() {
    return _summaryCard(
      "Monthly",
      _selectedLoanData == null
          ? "—"
          : currency.format(
          _amortization.isNotEmpty ? _amortization.first['payment'] : 0.0),
      Icons.calendar_month,
    );
  }

  Widget _buildTermCard() {
    return _summaryCard(
      "Term",
      _selectedLoanData == null
          ? "—"
          : "${_selectedLoanData!['installmentMonths']} months",
      Icons.schedule,
    );
  }
}
