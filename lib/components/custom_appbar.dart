import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomAppBar extends StatelessWidget {
  final String firstName;
  final VoidCallback onSettingsPressed;

  const CustomAppBar({
    super.key,
    required this.firstName,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⚙️ Settings icon
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onSettingsPressed,
                child: const Icon(
                  LucideIcons.settings,
                  color: Color(0xFF1C143A),
                  size: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            "Good evening,",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1C143A),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            "Welcome back, $firstName!",
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C143A),
            ),
          ),
        ],
      ),
    );
  }
}
