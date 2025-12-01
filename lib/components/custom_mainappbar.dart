import 'package:flutter/material.dart';

class CustomMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final Color backgroundColor;

  const CustomMainAppBar({
    super.key,
    this.onBack,
    this.backgroundColor = const Color(0xFF800000), // Maroon
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/logo/branding_name.png',
          height: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}