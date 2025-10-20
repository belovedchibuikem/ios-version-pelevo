import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class NameInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;

  const NameInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: const Icon(Icons.person_outline),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.error,
            width: 2,
          ),
        ),
      ),
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      autocorrect: false,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Name is required';
        }
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
          return 'Name can only contain letters and spaces';
        }
        if (value.length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }
}
