import 'package:flutter/material.dart';
import 'user_info_screen.dart';
import 'verified_ids_screen.dart';
import 'addresses_screen.dart';
import 'suppliers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  late AnimationController _controller;
  late List<Animation<double>> _animations;

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

    // Create animations for each icon
    _animations = List.generate(
      4,
      (index) => Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index / 4,
            (index + 1) / 4,
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );

    // Initial animation for the first selected item
    _animations[_selectedIndex].addListener(() => setState(() {}));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      // Reset previous animation
      _animations[_selectedIndex] = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            _selectedIndex / 4,
            (_selectedIndex + 1) / 4,
            curve: Curves.easeInOut,
          ),
        ),
      );

      _selectedIndex = index;

      // Setup new animation
      _animations[_selectedIndex] = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index / 4,
            (index + 1) / 4,
            curve: Curves.easeInOut,
          ),
        ),
      );

      // Add listener to the new animation
      _animations[_selectedIndex].addListener(() => setState(() {}));
    });

    // Reset and start animation
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _SearchDelegate(_titles[_selectedIndex]),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          _buildNavigationDestination(0, Icons.person_outline, Icons.person, 'My Info'),
          _buildNavigationDestination(1, Icons.credit_card_outlined, Icons.credit_card, 'IDs'),
          _buildNavigationDestination(2, Icons.location_on_outlined, Icons.location_on, 'Addresses'),
          _buildNavigationDestination(3, Icons.business_outlined, Icons.business, 'Suppliers'),
        ],
      ),
    );
  }

  Widget _buildNavigationDestination(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _selectedIndex == index;
    final scale = _animations[index].value;

    return NavigationDestination(
      icon: Transform.scale(
        scale: isSelected ? scale : 1.0,
        child: Icon(isSelected ? filledIcon : outlinedIcon),
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