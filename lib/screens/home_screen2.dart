import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../theme/app_theme.dart';
import 'user_info_screen.dart';
import 'verified_ids_screen.dart';
import 'addresses_screen.dart';
import 'suppliers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  final List<Widget> _screens = [
    const UserInfoScreen(),
    const VerifiedIDsScreen(),
    const AddressesScreen(),
    const SuppliersScreen(),
  ];

  final List<String> _titles = [
    'My Information',
    'Verified IDs',
    'Addresses',
    'Suppliers',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Create animations for each tab
    _animations = List.generate(4, (index) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2, // Stagger the animations
            index * 0.2 + 0.5,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          height: 90,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _buildNavigationDestination(0, Icons.person_outline, Icons.person, 'My Info'),
            _buildNavigationDestination(1, Icons.badge_outlined, Icons.badge, 'IDs'),
            _buildNavigationDestination(2, Icons.location_on_outlined, Icons.location_on, 'Addresses'),
            _buildNavigationDestination(3, Icons.business_outlined, Icons.business, 'Suppliers'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDestination(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _selectedIndex == index;
    final scale = _animations[index].value;

    return NavigationDestination(
      icon: Transform.scale(
        scale: isSelected ? scale : 1.0,
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? AppTheme.primaryBlue : Colors.grey,
          size: 28,
        ),
      ),
      label: label,
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