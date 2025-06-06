import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import 'identity_center_screen.dart';

class HomeScreen extends StatelessWidget {
  final String email;

  // Define brand colors
  static const Color primaryBlue = Color(0xFF0066CC);  // Main blue from logo
  static const Color accentBlue = Color(0xFF00A3FF);   // Lighter blue accent
  static const Color textDark = Color(0xFF1A1F36);     // Dark text color
  static const Color textGrey = Color(0xFF6B7280);     // Secondary text color

  const HomeScreen({super.key, required this.email});

  void _goToIdentityCenter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IdentityCenterScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 96.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoSection(
                          title: 'Verify Identity Before You Trust',
                          description: 'Always verify before making critical actions.\nConfirm the identity of your colleague or vendor - fast, secure, and reliable.',
                          icon: Icons.verified_user,
                          iconColor: primaryBlue,
                          backgroundColor: accentBlue.withOpacity(0.05),
                        ),
                        _InfoSection(
                          title: 'Employee to Employee Communication',
                          description: "When a colleague reaches out with a sensitive request use IdentityConnect to verify it's really them.",
                          icon: Icons.people,
                          iconColor: primaryBlue,
                          backgroundColor: accentBlue.withOpacity(0.05),
                        ),
                        _InfoSection(
                          title: 'Employee to Vendor Communication',
                          description: 'Before processing requesst from a vendor,\nverify their identity in real time with IdentityConnect.',
                          icon: Icons.business,
                          iconColor: primaryBlue,
                          backgroundColor: accentBlue.withOpacity(0.05),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _goToIdentityCenter(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.security, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Identity Center',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _InfoSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: HomeScreen.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: HomeScreen.textGrey,
              height: 1.5,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
