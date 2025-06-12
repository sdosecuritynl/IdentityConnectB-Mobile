import 'dart:convert';

class Address {
  final String id;
  final String name;
  final String organization;
  final String phone;
  final String email;
  final String country;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;

  Address({
    required this.id,
    required this.name,
    required this.organization,
    required this.phone,
    required this.email,
    required this.country,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'organization': organization,
    'phone': phone,
    'email': email,
    'country': country,
    'streetAddress': streetAddress,
    'city': city,
    'state': state,
    'zipCode': zipCode,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'],
    name: json['name'],
    organization: json['organization'],
    phone: json['phone'],
    email: json['email'],
    country: json['country'],
    streetAddress: json['streetAddress'],
    city: json['city'],
    state: json['state'],
    zipCode: json['zipCode'],
  );
} 