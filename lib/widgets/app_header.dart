import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 32,
                    width: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'IdentityConnect',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showBackButton)
              Positioned(
                left: 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: AppTheme.primaryBlue,
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  tooltip: 'Back to Home',
                ),
              ),
          ],
        ),
      ),
    );
  }
} 