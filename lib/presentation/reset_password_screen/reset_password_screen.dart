import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/app_export.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/exceptions/auth_exception.dart';
import '../../theme/app_theme.dart';
import '../authentication_screen/widgets/password_input_widget.dart';
import '../authentication_screen/widgets/confirm_password_input_widget.dart';
import '../authentication_screen/widgets/password_rules_widget.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
    _confirmPasswordFocusNode.addListener(_handleConfirmPasswordFocusChange);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.removeListener(_handlePasswordFocusChange);
    _confirmPasswordFocusNode.removeListener(_handleConfirmPasswordFocusChange);
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handlePasswordFocusChange() {
    setState(() {
      _isPasswordFocused = _passwordFocusNode.hasFocus;
      if (_isPasswordFocused) {
        _validatePasswordWithError(_passwordController.text);
      }
    });
  }

  void _handleConfirmPasswordFocusChange() {
    setState(() {
      _isConfirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
      if (_isConfirmPasswordFocused) {
        _validateConfirmPassword(
            _passwordController.text, _confirmPasswordController.text);
      }
    });
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  }

  void _validatePasswordWithError(String password) {
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
    } else if (!_validatePassword(password)) {
      setState(() => _passwordError =
          'Password must be at least 8 characters and contain uppercase, lowercase, number, and special character');
    } else {
      setState(() => _passwordError = null);
    }
  }

  void _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
    } else {
      setState(() => _confirmPasswordError = null);
    }
  }

  void _showErrorSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    try {
      await AuthService().resetPassword(
        token: widget.token,
        email: widget.email,
        password: _passwordController.text,
      );

      HapticFeedback.lightImpact();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset Successful'),
            content: const Text(
              'Your password has been reset successfully. You can now login with your new password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(context, '/auth');
                },
                child: const Text('Proceed to Login'),
              ),
            ],
          ),
        );
      }
    } on ValidationException catch (e) {
      if (e.errors != null) {
        if (e.errors!.containsKey('password')) {
          setState(() => _passwordError = e.errors!['password'][0]);
        }
        if (e.errors!.containsKey('token')) {
          _showErrorSnackBar('Invalid or expired reset token. Please request a new one.');
        }
      } else {
        _showErrorSnackBar(e.message);
      }
    } on RateLimitException catch (e) {
      _showErrorSnackBar(
        '${e.message} Please try again in ${e.retryAfter} seconds.',
        duration: Duration(seconds: e.retryAfter),
      );
    } on NetworkException catch (e) {
      _showErrorSnackBar(e.message);
    } on ServerException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reset Password',
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your new password.',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                PasswordInputWidget(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  isVisible: _isPasswordVisible,
                  errorText: _passwordError,
                  onVisibilityToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  onChanged: (value) {
                    _validatePasswordWithError(value);
                  },
                  onSubmitted: (value) {
                    _confirmPasswordFocusNode.requestFocus();
                  },
                ),
                if (_isPasswordFocused || _passwordController.text.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: PasswordRulesWidget(
                      password: _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ConfirmPasswordInputWidget(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  isVisible: _isConfirmPasswordVisible,
                  errorText: _confirmPasswordError,
                  onVisibilityToggle: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  onChanged: (value) {
                    _validateConfirmPassword(_passwordController.text, value);
                  },
                  onSubmitted: (value) {
                    _handleResetPassword();
                  },
                ),
                if (_isConfirmPasswordFocused ||
                    _confirmPasswordController.text.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: PasswordRulesWidget(
                      password: _confirmPasswordController.text,
                      isConfirmPassword: true,
                      confirmPassword: _passwordController.text,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 