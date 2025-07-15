import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'user_info_screen.dart';
import 'verified_ids_screen.dart';
import 'addresses_screen.dart';
import 'suppliers_screen.dart';
import 'my_information_screen.dart';
import 'secure_mailbox_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for each tab
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _controllers.add(controller);
      _animations.add(
        Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        ),
      );
    }
    // Start animation for initial selected tab
    _controllers[0].forward();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    setState(() {
      // Reset previous selection
      _controllers[_selectedIndex].reverse();
      _selectedIndex = index;
      // Animate new selection
      _controllers[index].forward();
    });
  }

  Widget _buildIcon(IconData icon, int index) {
    return ScaleTransition(
      scale: _animations[index],
      child: Icon(
        icon,
        size: 28,
        color: _selectedIndex == index ? AppTheme.primaryBlue : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const SecureMailboxScreen(), // Secure Mailbox tab
          const VerifiedIDsScreen(), // IDs tab
          const AddressesScreen(), // Addresses tab
          const SuppliersScreen(), // Suppliers tab
        ],
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: AppTheme.bodyText.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.bodyText.copyWith(
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.mail_lock, 0),
              label: 'Mailbox',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.credit_card, 1),
              label: 'IDs',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.location_on_outlined, 2),
              label: 'Addresses',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.business_outlined, 3),
              label: 'Suppliers',
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDelegate extends SearchDelegate {
  final String section;

  _SearchDelegate(this.section);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implement search results based on the section
    return Center(
      child: Text('Search results for "$query" in $section'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Implement search suggestions based on the section
    return Center(
      child: Text('Type to search in $section'),
    );
  }
} 