import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/address.dart';
import '../services/address_service.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressService = AddressService();
  final _uuid = const Uuid();

  String _name = '';
  String _organization = '';
  String _phone = '';
  String _email = '';
  String _country = 'Israel';
  String _streetAddress = '';
  String _city = '';
  String _state = '';
  String _zipCode = '';

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final address = Address(
        id: _uuid.v4(),
        name: _name,
        organization: _organization,
        phone: _phone,
        email: _email,
        country: _country,
        streetAddress: _streetAddress,
        city: _city,
        state: _state,
        zipCode: _zipCode,
      );

      await _addressService.saveAddress(address);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Custom header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Address',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                          onSaved: (value) => _name = value!,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Organization',
                          ),
                          onSaved: (value) => _organization = value ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => _phone = value ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _email = value ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Country/Region',
                          ),
                          initialValue: 'Israel',
                          enabled: false,
                          onSaved: (value) => _country = value ?? 'Israel',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Street Address',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a street address';
                            }
                            return null;
                          },
                          onSaved: (value) => _streetAddress = value!,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'City',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a city';
                            }
                            return null;
                          },
                          onSaved: (value) => _city = value!,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'State',
                          ),
                          onSaved: (value) => _state = value ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'ZIP Code',
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _zipCode = value ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Save button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _saveAddress,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.save),
            ),
          ),
        ],
      ),
    );
  }
} 