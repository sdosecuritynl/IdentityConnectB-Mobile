import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/address_service.dart';
import '../services/storage_service.dart';
import '../models/address.dart';
import '../widgets/app_header.dart';

class MyInformationScreen extends StatefulWidget {
  const MyInformationScreen({Key? key}) : super(key: key);

  @override
  State<MyInformationScreen> createState() => _MyInformationScreenState();
}

class _MyInformationScreenState extends State<MyInformationScreen> with RouteAware {
  final AddressService _addressService = AddressService();
  final SecureStorageService _storage = SecureStorageService();
  Address? _defaultAddress;
  bool _isLoading = true;
  
  // User information
  String _fullName = '';
  String _dateOfBirth = '';
  String _licenseNumber = '';
  String _licenseExpiration = '';
  String _passportNumber = '';
  String _passportExpiration = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadDefaultAddress(),
      _loadUserInformation(),
    ]);
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await _addressService.getAddresses();
      if (mounted) {
        setState(() {
          _defaultAddress = addresses.isNotEmpty ? addresses[0] : null;
        });
      }
    } catch (e) {
      print('[MyInfo] Error loading addresses: $e');
    }
  }

  Future<void> _loadUserInformation() async {
    try {
      final results = await Future.wait([
        _storage.getFullName(),
        _storage.getDateOfBirth(),
        _storage.getLicenseNumber(),
        _storage.getLicenseExpiration(),
        _storage.getPassportNumber(),
        _storage.getPassportExpiration(),
      ]);
      
      if (mounted) {
        setState(() {
          _fullName = results[0] ?? '';
          _dateOfBirth = results[1] ?? '';
          _licenseNumber = results[2] ?? '';
          _licenseExpiration = results[3] ?? '';
          _passportNumber = results[4] ?? '';
          _passportExpiration = results[5] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[MyInfo] Error loading user information: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  Widget _buildDisabledTextField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: value),
            enabled: false,
            style: AppTheme.bodyText.copyWith(
              fontSize: 16,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const AppHeader(title: 'My Information'),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Privacy Information Button
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Data Privacy',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () => Navigator.of(context).pop(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'At IdentityConnect, your personal data is stored only on your device and is never shared unless you explicitly choose to share it with a verified third party.',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'We only store your phone number on our servers, which helps identify your account.',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 24),
                                            const Text(
                                              'Why is this secure?',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Even if someone gets access to your phone number, they cannot impersonate you.',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'To verify your identity, every user must complete a secure enrollment process:',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 8),
                                            const Padding(
                                              padding: EdgeInsets.only(left: 16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('• Face Liveness Detection',
                                                      style: TextStyle(fontSize: 16)),
                                                  SizedBox(height: 4),
                                                  Text('• Selfie Matching',
                                                      style: TextStyle(fontSize: 16)),
                                                  SizedBox(height: 4),
                                                  Text('• ID Document Scan',
                                                      style: TextStyle(fontSize: 16)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'This means only you can activate or re-enroll on a new device.\n\nNo shortcuts, no backdoors.',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Data Stays Private',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildDisabledTextField('Full Name', _fullName.isEmpty ? '' : _fullName),
                        _buildDisabledTextField('Date of Birth', _dateOfBirth.isEmpty ? '' : _dateOfBirth),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Address Information',
                            style: AppTheme.titleMedium.copyWith(fontSize: 18),
                          ),
                        ),
                        _buildDisabledTextField('Address', _defaultAddress?.streetAddress ?? 'No default address'),
                        _buildDisabledTextField('Zip Code', _defaultAddress?.zipCode ?? 'No zip code'),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Driver License',
                            style: AppTheme.titleMedium.copyWith(fontSize: 18),
                          ),
                        ),
                        _buildDisabledTextField('License Number', _licenseNumber.isEmpty ? '' : _licenseNumber),
                        _buildDisabledTextField('Expiration', _licenseExpiration.isEmpty ? '' : _licenseExpiration),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Passport',
                            style: AppTheme.titleMedium.copyWith(fontSize: 18),
                          ),
                        ),
                        _buildDisabledTextField('Passport Number', _passportNumber.isEmpty ? '' : _passportNumber),
                        _buildDisabledTextField('Expiration', _passportExpiration.isEmpty ? '' : _passportExpiration),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
} 