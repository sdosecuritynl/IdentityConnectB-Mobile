// lib/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText; // Changed from 'label' to 'labelText'
  final String? hintText; // Added hintText
  final bool obscureText;
  final TextInputType? keyboardType; // Added keyboardType
  final IconData? prefixIcon; // Added prefixIcon
  final String? Function(String?)? validator; // Added validator
  final List<TextInputFormatter>? inputFormatters; // Added inputFormatters

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText, // Changed from 'label' to 'labelText'
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType, // Applied keyboardType
      validator: validator, // Applied validator
      inputFormatters: inputFormatters, // Applied inputFormatters
      decoration: AppTheme.textFieldDecoration.copyWith(
        labelText: labelText, // Used labelText
        hintText: hintText, // Used hintText
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primaryBlue) : null, // Used prefixIcon
      ),
      style: TextStyle(color: AppTheme.textDark),
    );
  }
}
