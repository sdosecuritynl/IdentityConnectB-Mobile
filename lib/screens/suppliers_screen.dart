import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Temporary sample data
  final List<Supplier> _suppliers = [
    Supplier(
      id: '1',
      name: 'Apple Inc.',
      logoUrl: 'https://example.com/apple.png',
      allowIdentityRequests: false,
    ),
    Supplier(
      id: '2',
      name: 'Microsoft',
      logoUrl: 'https://example.com/microsoft.png',
      allowIdentityRequests: true,
    ),
    // Add more sample suppliers as needed
  ];

  List<Supplier> get _filteredSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers
        .where((supplier) =>
            supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Suppliers'),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search suppliers...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1),
                  ),
                ),
              ),
            ),
            // Explanatory Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Suppliers I allow to contact me.',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                ),
              ),
            ),
            // Suppliers List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = _filteredSuppliers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Business Logo
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                supplier.logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.business,
                                    color: Colors.grey,
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Business Name
                          Expanded(
                            child: Text(
                              supplier.name,
                              style: AppTheme.titleMedium.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // Checkbox
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: supplier.allowIdentityRequests,
                              onChanged: (bool? value) {
                                setState(() {
                                  supplier.allowIdentityRequests = value ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              activeColor: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 