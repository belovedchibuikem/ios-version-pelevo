import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class PasswordRulesWidget extends StatelessWidget {
  final String password;
  final bool isConfirmPassword;
  final String? confirmPassword;

  const PasswordRulesWidget({
    super.key,
    required this.password,
    this.isConfirmPassword = false,
    this.confirmPassword,
  });

  bool _hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  bool _hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  bool _hasNumber(String password) => RegExp(r'[0-9]').hasMatch(password);
  bool _hasSpecialChar(String password) =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  bool _hasMinLength(String password) => password.length >= 8;
  bool _passwordsMatch() => password == confirmPassword;

  @override
  Widget build(BuildContext context) {
    if (isConfirmPassword) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Password must match',
            style: TextStyle(
              color: confirmPassword != null && !_passwordsMatch()
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Password must contain:',
          style: TextStyle(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        _buildRule('At least 8 characters', _hasMinLength(password)),
        _buildRule('One uppercase letter', _hasUppercase(password)),
        _buildRule('One lowercase letter', _hasLowercase(password)),
        _buildRule('One number', _hasNumber(password)),
        _buildRule('One special character', _hasSpecialChar(password)),
      ],
    );
  }

  Widget _buildRule(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
