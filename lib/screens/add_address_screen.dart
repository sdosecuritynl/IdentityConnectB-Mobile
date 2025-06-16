import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/address.dart';
import '../services/address_service.dart';

const List<String> countryList = [
  'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
  'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia',
  'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cambodia',
  'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica',
  'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominica', 'Dominican Republic', 'Ecuador', 'Egypt',
  'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia', 'Fiji', 'Finland', 'France', 'Gabon',
  'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti',
  'Honduras', 'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan',
  'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia',
  'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta',
  'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro',
  'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger',
  'Nigeria', 'North Korea', 'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau', 'Palestine', 'Panama', 'Papua New Guinea',
  'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda', 'Saint Kitts and Nevis',
  'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal',
  'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa',
  'South Korea', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria', 'Taiwan',
  'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan',
  'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu',
  'Vatican City', 'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
];

class AddAddressScreen extends StatefulWidget {
  final Address? address;
  const AddAddressScreen({super.key, this.address});

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

  // Regex patterns
  final RegExp _lettersRegex = RegExp(r"^[A-Za-zÀ-ÿ'\-\.\s]+");
  final RegExp _stateRegex = RegExp(r"^[A-Za-zÀ-ÿ0-9'\-\.\s]+");
  final RegExp _phoneRegex = RegExp(r"^\+?[0-9\s\-()]{7,20}");
  final RegExp _emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w{2,}");
  final RegExp _streetRegex = RegExp(r"^[A-Za-zÀ-ÿ0-9'\-\.\,\s]+");
  final RegExp _zipRegex = RegExp(r"^[A-Za-z0-9\s\-]+$");

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _name = widget.address!.name;
      _organization = widget.address!.organization;
      _phone = widget.address!.phone;
      _email = widget.address!.email;
      _country = widget.address!.country;
      _streetAddress = widget.address!.streetAddress;
      _city = widget.address!.city;
      _state = widget.address!.state;
      _zipCode = widget.address!.zipCode;
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    try {
      final address = Address(
        id: widget.address?.id ?? _uuid.v4(),
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
      if (widget.address != null) {
        await _addressService.updateAddress(address);
      } else {
        await _addressService.saveAddress(address);
      }
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
                            if (!_lettersRegex.hasMatch(value)) {
                              return 'Only letters, spaces, apostrophes, hyphens, and periods allowed';
                            }
                            return null;
                          },
                          onSaved: (value) => _name = value!,
                          initialValue: _name,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Organization',
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !_lettersRegex.hasMatch(value)) {
                              return 'Only letters, spaces, apostrophes, hyphens, and periods allowed';
                            }
                            return null;
                          },
                          onSaved: (value) => _organization = value ?? '',
                          initialValue: _organization,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a phone number';
                            }
                            if (!_phoneRegex.hasMatch(value)) {
                              return 'Enter a valid phone number (digits, +, spaces, dashes, parentheses)';
                            }
                            return null;
                          },
                          onSaved: (value) => _phone = value ?? '',
                          initialValue: _phone,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!_emailRegex.hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value ?? '',
                          initialValue: _email,
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Country/Region',
                          ),
                          value: _country,
                          isExpanded: true,
                          items: countryList.map((country) {
                            return DropdownMenuItem<String>(
                              value: country,
                              child: Text(country),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a country';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _country = value!;
                            });
                          },
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
                            if (!_streetRegex.hasMatch(value)) {
                              return 'Invalid street address';
                            }
                            return null;
                          },
                          onSaved: (value) => _streetAddress = value!,
                          initialValue: _streetAddress,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'City',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a city';
                            }
                            if (!_lettersRegex.hasMatch(value)) {
                              return 'Only letters, spaces, apostrophes, hyphens, and periods allowed';
                            }
                            return null;
                          },
                          onSaved: (value) => _city = value!,
                          initialValue: _city,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'State',
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !_stateRegex.hasMatch(value)) {
                              return 'Only letters, numbers, spaces, apostrophes, hyphens, and periods allowed';
                            }
                            return null;
                          },
                          onSaved: (value) => _state = value ?? '',
                          initialValue: _state,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'ZIP Code',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a ZIP code';
                            }
                            if (!_zipRegex.hasMatch(value)) {
                              return 'Invalid ZIP code';
                            }
                            return null;
                          },
                          onSaved: (value) => _zipCode = value ?? '',
                          initialValue: _zipCode,
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