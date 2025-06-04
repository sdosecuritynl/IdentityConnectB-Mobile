import 'package:flutter/material.dart';
import '../services/menu_actions.dart';
import 'user_info_screen.dart';
import 'identity_center_screen.dart';

class HomeScreen extends StatelessWidget {
  final String email;
  final MenuActions _menuActions = MenuActions();

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
                    const Text(
                      'Logged in as',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Identity Center'),
                onTap: () => _menuActions.goToIdentityCenter(context, email),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('My Information'),
                onTap: () => _menuActions.goToUserInfo(context, email),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Delete Account'),
                onTap: () => _menuActions.showDeleteConfirmation(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () => _menuActions.signOut(context),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 50,
                        width: 50,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'IdentityConnect.io',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 39, color: Colors.black87),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ],
              ),
              // Message
              const Center(),
            ],
          ),
        ),
      ),
    );
  }
}
