import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../core/utils/validation_utils.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/exceptions/auth_exception.dart';
import '../../theme/app_theme.dart';
import './widgets/auth_button_widget.dart';
import './widgets/auth_mode_toggle_widget.dart';
import './widgets/confirm_password_input_widget.dart';
import './widgets/email_input_widget.dart';
import './widgets/forgot_password_widget.dart';
import './widgets/name_input_widget.dart';
import './widgets/password_input_widget.dart';
import './widgets/password_rules_widget.dart';
import './widgets/terms_checkbox_widget.dart';
import '../../providers/subscription_provider.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final AuthService _authService = AuthService();
  final UnifiedAuthService _unifiedAuthService = UnifiedAuthService();

  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // Add focus listeners
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
    _confirmPasswordFocusNode.addListener(_handleConfirmPasswordFocusChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.removeListener(_handlePasswordFocusChange);
    _confirmPasswordFocusNode.removeListener(_handleConfirmPasswordFocusChange);
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _clearErrors();
      if (_isLoginMode) {
        _nameController.clear();
        _confirmPasswordController.clear();
        _acceptTerms = false;
      }
    });
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });
  }

  bool _validateName(String name) {
    return name.length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  bool _validateEmail(String email) {
    return ValidationUtils.isValidEmail(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  }

  bool _isFormValid() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !_validateEmail(email)) return false;
    if (password.isEmpty || !_validatePassword(password)) return false;

    if (!_isLoginMode) {
      final name = _nameController.text.trim();
      if (name.isEmpty || !_validateName(name)) return false;
      if (confirmPassword.isEmpty || password != confirmPassword) return false;
      if (!_acceptTerms) return false;
    }

    return true;
  }

  void _validateForm() {
    setState(() {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (!_isLoginMode) {
        final name = _nameController.text.trim();
        _nameError = name.isEmpty
            ? 'Name is required'
            : !_validateName(name)
                ? 'Name can only contain letters and spaces'
                : null;
      }

      _emailError = email.isEmpty
          ? 'Email is required'
          : !_validateEmail(email)
              ? 'Please enter a valid email'
              : null;

      _passwordError = password.isEmpty
          ? 'Password is required'
          : !_validatePassword(password)
              ? 'Password must be at least 8 characters and contain uppercase, lowercase, number, and special character'
              : null;

      if (!_isLoginMode) {
        _confirmPasswordError = confirmPassword.isEmpty
            ? 'Please confirm your password'
            : password != confirmPassword
                ? 'Passwords do not match'
                : null;
      }
    });
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

  void _showValidationErrors(Map<String, dynamic> errors) {
    if (errors.containsKey('validation_errors')) {
      final validationErrors =
          errors['validation_errors'] as Map<String, dynamic>;
      validationErrors.forEach((field, messages) {
        if (field == 'name') {
          setState(() => _nameError = messages[0]);
        } else if (field == 'email') {
          setState(() => _emailError = messages[0]);
        } else if (field == 'password') {
          setState(() => _passwordError = messages[0]);
        }
      });
    } else if (errors.containsKey('password_requirements')) {
      final requirements = errors['password_requirements'] as List;
      setState(() => _passwordError = requirements.join('\n'));
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: const Text(
          'Please check your email to verify your account before logging in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Only close the dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuthentication() async {
    _validateForm();

    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
      _clearErrors();
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLoginMode) {
        await _authService.login(
          email: email,
          password: password,
        );

        // Ensure guest mode is disabled after a real login
        await _unifiedAuthService.setGuestMode(false);

        // Sync subscriptions after login
        await Provider.of<SubscriptionProvider>(context, listen: false)
            .fetchAndSetSubscriptionsFromBackend();

        HapticFeedback.lightImpact();
        Navigator.pushReplacementNamed(context, '/home-screen');
      } else {
        final name = _nameController.text.trim();
        await _authService.register(
          name: name,
          email: email,
          password: password,
          passwordConfirmation: _confirmPasswordController.text,
        );

        // Ensure guest mode is disabled after a successful registration
        await _unifiedAuthService.setGuestMode(false);

        // Sync subscriptions after registration
        await Provider.of<SubscriptionProvider>(context, listen: false)
            .fetchAndSetSubscriptionsFromBackend();

        HapticFeedback.lightImpact();
        // Navigate to email confirmation screen instead of showing dialog
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.emailConfirmationScreen,
          arguments: {'email': email},
        );
      }
    } on ValidationException catch (e) {
      if (e.errors != null) {
        _showValidationErrors(e.errors!);
      } else {
        _showErrorSnackBar(e.message);
      }
    } on RateLimitException catch (e) {
      _showErrorSnackBar(
        '${e.message} Please try again in ${e.retryAfter} seconds.',
        duration: Duration(seconds: e.retryAfter),
      );
    } on EmailVerificationException {
      _showEmailVerificationDialog();
    } on AccountDeactivatedException catch (e) {
      _showErrorSnackBar(e.message);
    } on NetworkException catch (e) {
      _showErrorSnackBar(e.message);
    } on ServerException catch (e) {
      _showErrorSnackBar(e.message);
    } on TokenException catch (e) {
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

  Future<void> _continueAsGuest() async {
    try {
      setState(() => _isLoading = true);
      await _unifiedAuthService.setGuestMode(true);
      HapticFeedback.selectionClick();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
      }
    } catch (e) {
      _showErrorSnackBar('Could not start guest session. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    Navigator.pushNamed(context, AppRoutes.forgotPasswordScreen);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // App Logo
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('App logo loading error: $error');
                                return Container(
                                  color: AppTheme.lightTheme.primaryColor,
                                  child: Center(
                                    child: Text(
                                      'P',
                                      style: AppTheme
                                          .lightTheme.textTheme.displayMedium
                                          ?.copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'Pelevo',
                          style: AppTheme.lightTheme.textTheme.headlineMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          'Listen & Earn Rewards',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Auth Mode Toggle
                      AuthModeToggleWidget(
                        isLoginMode: _isLoginMode,
                        onToggle: _toggleAuthMode,
                      ),

                      const SizedBox(height: 32),

                      // Name Input (Register mode only)
                      if (!_isLoginMode) ...[
                        NameInputWidget(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          errorText: _nameError,
                          onChanged: (value) {
                            if (_nameError != null) {
                              setState(() {
                                _nameError = null;
                              });
                            }
                          },
                          onSubmitted: (value) {
                            _emailFocusNode.requestFocus();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Input
                      EmailInputWidget(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        errorText: _emailError,
                        onChanged: (value) {
                          if (_emailError != null) {
                            setState(() {
                              _emailError = null;
                            });
                          }
                        },
                        onSubmitted: (value) {
                          _passwordFocusNode.requestFocus();
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Input
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
                          if (!_isLoginMode) {
                            _confirmPasswordFocusNode.requestFocus();
                          } else {
                            _handleAuthentication();
                          }
                        },
                      ),

                      // Password Rules (Register mode only)
                      if (!_isLoginMode &&
                          (_isPasswordFocused ||
                              _passwordController.text.isNotEmpty)) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: PasswordRulesWidget(
                            password: _passwordController.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else if (!_isLoginMode) ...[
                        const SizedBox(height: 16),
                      ],

                      // Confirm Password (Register mode only)
                      if (!_isLoginMode) ...[
                        ConfirmPasswordInputWidget(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          isVisible: _isConfirmPasswordVisible,
                          errorText: _confirmPasswordError,
                          onVisibilityToggle: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                          onChanged: (value) {
                            _validateConfirmPassword(
                                _passwordController.text, value);
                          },
                          onSubmitted: (value) {
                            _handleAuthentication();
                          },
                        ),

                        // Confirm Password Rule
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

                        const SizedBox(height: 16),

                        // Terms Checkbox
                        TermsCheckboxWidget(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Auth Button
                      AuthButtonWidget(
                        isLoginMode: _isLoginMode,
                        isLoading: _isLoading,
                        isEnabled: _isFormValid(),
                        onPressed: _handleAuthentication,
                      ),

                      // Forgot Password (Login mode only)
                      if (_isLoginMode) ...[
                        const SizedBox(height: 16),
                        ForgotPasswordWidget(
                          onPressed: _handleForgotPassword,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _isLoading ? null : _continueAsGuest,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            icon: Icon(
                              Icons.person_outline,
                              color: AppTheme.lightTheme.primaryColor,
                              size: 20,
                            ),
                            label: Text(
                              'Continue as Guest',
                              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Social Login - Temporarily disabled
                      // SocialLoginWidget(
                      //   socialAuthService: SocialAuthService(),
                      //   onError: (message) => _showErrorSnackBar(message),
                      //   isLoading: _isLoading,
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
