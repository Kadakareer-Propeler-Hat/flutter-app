import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Screens
import 'package:horizonai/screens/quickactions/horizon_ai.dart';
import 'package:horizonai/screens/quickactions/quick_repayment.dart';
import 'package:horizonai/screens/quickactions/credit_line.dart';
import 'package:horizonai/screens/quickactions/check_receipt.dart';
import 'package:horizonai/screens/quickactions/bills_payment.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 95,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              index: 0,
              icon: LucideIcons.trendingUp,
              label: "Smart\nRepayment",
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuickRepaymentScreen()),
                );
              },
            ),
            _navItem(
              index: 1,
              icon: LucideIcons.coins,
              label: "Bills\nPay",
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BillsPayScreen()),
                );
              },
            ),

            // ⭐ CENTER NAV ITEM (Ask Horizon)
            _centerNavItem(context),

            _navItem(
              index: 3,
              icon: LucideIcons.checkCheck,
              label: "Check\nReceipt",
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckReceiptScreen()),
                );
              },
            ),
            _navItem(
              index: 4,
              icon: LucideIcons.creditCard,
              label: "Credit\nLine",
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreditLinePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Normal nav items
  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        onItemTapped(index);
        if (onTap != null) onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? const Color(0xFF6A0D33) : const Color(0xFF1C143A),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.1,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C143A),
            ),
          ),
        ],
      ),
    );
  }

  // 🔸 Ask Horizon (Middle Button)
  Widget _centerNavItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onItemTapped(2);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HorizonAI()),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFE86F64),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: const Icon(
              LucideIcons.messageSquare,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Ask\nHorizon",
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.1,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C143A),
            ),
          ),
        ],
      ),
    );
  }
}
