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
  String _selectedCategory = 'All';

  // Updated supplier data organized by categories
  final Map<String, List<Supplier>> _suppliersByCategory = {
    'Fintech': [
      Supplier(id: 'fintech_1', name: 'Revolut', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'fintech_2', name: 'N26', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'fintech_3', name: 'Stripe', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'fintech_4', name: 'PayPal', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'fintech_5', name: 'Chime', logoUrl: '', allowIdentityRequests: false),
    ],
    'Marketplace': [
      Supplier(id: 'marketplace_1', name: 'eBay', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'marketplace_2', name: 'Etsy', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'marketplace_3', name: 'Amazon Marketplace', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'marketplace_4', name: 'Airbnb Experiences', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'marketplace_5', name: 'Upwork', logoUrl: '', allowIdentityRequests: false),
    ],
    'Social Media': [
      Supplier(id: 'social_1', name: 'Facebook', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'social_2', name: 'Instagram', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'social_3', name: 'LinkedIn', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'social_4', name: 'Twitter', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'social_5', name: 'TikTok', logoUrl: '', allowIdentityRequests: false),
    ],
    'Traveling': [
      Supplier(id: 'travel_1', name: 'Expedia', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'travel_2', name: 'Booking.com', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'travel_3', name: 'Airbnb', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'travel_4', name: 'TripAdvisor', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'travel_5', name: 'Uber', logoUrl: '', allowIdentityRequests: false),
    ],
    'Dating': [
      Supplier(id: 'dating_1', name: 'Tinder', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'dating_2', name: 'Bumble', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'dating_3', name: 'OkCupid', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'dating_4', name: 'Hinge', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'dating_5', name: 'Match.com', logoUrl: '', allowIdentityRequests: false),
    ],
    'Delivery': [
      Supplier(id: 'delivery_1', name: 'DoorDash', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'delivery_2', name: 'Uber Eats', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'delivery_3', name: 'Postmates', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'delivery_4', name: 'Deliveroo', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'delivery_5', name: 'Grubhub', logoUrl: '', allowIdentityRequests: false),
    ],
    'Education & Exam': [
      Supplier(id: 'education_1', name: 'Coursera', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'education_2', name: 'Khan Academy', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'education_3', name: 'Udemy', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'education_4', name: 'Pearson VUE', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'education_5', name: 'ETS (TOEFL, GRE)', logoUrl: '', allowIdentityRequests: false),
    ],
    'Gaming': [
      Supplier(id: 'gaming_1', name: 'Steam', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'gaming_2', name: 'Epic Games', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'gaming_3', name: 'Xbox Live', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'gaming_4', name: 'PlayStation Network', logoUrl: '', allowIdentityRequests: false),
      Supplier(id: 'gaming_5', name: 'Twitch', logoUrl: '', allowIdentityRequests: false),
    ],
  };

  List<Supplier> get _filteredSuppliers {
    List<Supplier> allSuppliers = [];
    
    // Get suppliers based on selected category
    if (_selectedCategory == 'All') {
      _suppliersByCategory.values.forEach((suppliers) => allSuppliers.addAll(suppliers));
    } else {
      allSuppliers = _suppliersByCategory[_selectedCategory] ?? [];
    }
    
    // Filter by search query
    if (_searchQuery.isEmpty) return allSuppliers;
    return allSuppliers
        .where((supplier) =>
            supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<String> get _categories => ['All', ..._suppliersByCategory.keys.toList()];

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
            
            // Category Filter
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textGrey,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
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
              child: _filteredSuppliers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = _filteredSuppliers[index];
                        return _buildSupplierCard(supplier);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
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
                child: supplier.logoUrl.isNotEmpty
                    ? Image.network(
                        supplier.logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultIcon(supplier.name);
                        },
                      )
                    : _buildDefaultIcon(supplier.name),
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
  }

  Widget _buildDefaultIcon(String supplierName) {
    // Return different icons based on supplier category
    if (supplierName.contains('Bank') || supplierName.contains('Pay') || 
        supplierName.contains('Stripe') || supplierName.contains('Revolut') || 
        supplierName.contains('N26') || supplierName.contains('Chime')) {
      return const Icon(Icons.account_balance, color: Colors.grey, size: 24);
    } else if (supplierName.contains('Facebook') || supplierName.contains('Instagram') || 
               supplierName.contains('LinkedIn') || supplierName.contains('Twitter') || 
               supplierName.contains('TikTok')) {
      return const Icon(Icons.share, color: Colors.grey, size: 24);
    } else if (supplierName.contains('Airbnb') || supplierName.contains('Booking') || 
               supplierName.contains('Expedia') || supplierName.contains('TripAdvisor') || 
               supplierName.contains('Uber')) {
      return const Icon(Icons.flight, color: Colors.grey, size: 24);
    } else if (supplierName.contains('Tinder') || supplierName.contains('Bumble') || 
               supplierName.contains('OkCupid') || supplierName.contains('Hinge') || 
               supplierName.contains('Match')) {
      return const Icon(Icons.favorite, color: Colors.grey, size: 24);
    } else if (supplierName.contains('DoorDash') || supplierName.contains('Uber Eats') || 
               supplierName.contains('Postmates') || supplierName.contains('Deliveroo') || 
               supplierName.contains('Grubhub')) {
      return const Icon(Icons.delivery_dining, color: Colors.grey, size: 24);
    } else if (supplierName.contains('Coursera') || supplierName.contains('Khan') || 
               supplierName.contains('Udemy') || supplierName.contains('Pearson') || 
               supplierName.contains('ETS')) {
      return const Icon(Icons.school, color: Colors.grey, size: 24);
    } else if (supplierName.contains('Steam') || supplierName.contains('Epic') || 
               supplierName.contains('Xbox') || supplierName.contains('PlayStation') || 
               supplierName.contains('Twitch')) {
      return const Icon(Icons.games, color: Colors.grey, size: 24);
    } else {
      return const Icon(Icons.business, color: Colors.grey, size: 24);
    }
  }
} 