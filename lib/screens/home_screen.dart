import 'package:flutter/material.dart';
import '../services/menu_actions.dart';
import 'identity_center_screen.dart';

class HomeScreen extends StatelessWidget {
  final String email;
  final MenuActions _menuActions = MenuActions();

  // Define brand colors
  static const Color primaryBlue = Color(0xFF0066CC);  // Main blue from logo
  static const Color accentBlue = Color(0xFF00A3FF);   // Lighter blue accent
  static const Color textDark = Color(0xFF1A1F36);     // Dark text color
  static const Color textGrey = Color(0xFF6B7280);     // Secondary text color

  HomeScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logged in as',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              Divider(thickness: 1, color: textGrey.withOpacity(0.2)),
              ListTile(
                leading: Icon(Icons.home, color: primaryBlue),
                title: Text('Home', style: TextStyle(color: textDark)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.security, color: primaryBlue),
                title: Text('Identity Center', style: TextStyle(color: textDark)),
                onTap: () => _menuActions.goToIdentityCenter(context, email),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: primaryBlue),
                title: Text('Sign Out', style: TextStyle(color: textDark)),
                onTap: () => _menuActions.signOut(context),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: textGrey.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'IdentityConnect.io',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, size: 28, color: primaryBlue),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoSection(
                            title: 'Verify Identity Before You Trust',
                            description: 'Always verify before making critical actions.\nConfirm the identity of your colleague or vendor - fast, secure, and reliable.',
                            icon: Icons.verified_user,
                            iconColor: primaryBlue,
                            backgroundColor: accentBlue.withOpacity(0.05),
                          ),
                          const SizedBox(height: 24),
                          _InfoSection(
                            title: 'Employee to Employee Communication',
                            description: "When a colleague reaches out with a sensitive request use IdentityConnect to verify it's really them.",
                            icon: Icons.people,
                            iconColor: primaryBlue,
                            backgroundColor: accentBlue.withOpacity(0.05),
                          ),
                          const SizedBox(height: 24),
                          _InfoSection(
                            title: 'Employee to Vendor Communication',
                            description: 'Before processing requesst from a vendor,\nverify their identity in real time with IdentityConnect.',
                            icon: Icons.business,
                            iconColor: primaryBlue,
                            backgroundColor: accentBlue.withOpacity(0.05),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
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
                        onPressed: () => _menuActions.goToIdentityCenter(context, email),
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
