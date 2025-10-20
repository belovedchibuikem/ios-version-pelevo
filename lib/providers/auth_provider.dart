import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _authToken;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  String? get authToken => _authToken;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      debugPrint('🔐 AUTH PROVIDER: Initializing authentication...');

      // Check if we have a stored token
      final token = await _storageService.getToken();
      if (token != null) {
        debugPrint('🔐 AUTH PROVIDER: Found stored token, validating...');

        // Check if the session is still valid
        final isValid = await _authService.isAuthenticated();
        if (isValid) {
          debugPrint(
              '🔐 AUTH PROVIDER: Session is valid, loading user data...');

          // Load user data
          final userData = await _storageService.getUserData();
          if (userData != null) {
            _authToken = token;
            _userData = userData;
            _isAuthenticated = true;
            debugPrint('🔐 AUTH PROVIDER: User authenticated successfully');
          } else {
            // Do NOT clear token just because user data is missing; allow session to persist
            debugPrint(
                '🔐 AUTH PROVIDER: No user data found, preserving token/session and continuing');
            _authToken = token;
            _isAuthenticated = true;
          }
        } else {
          debugPrint('🔐 AUTH PROVIDER: Session expired, clearing data');
          await _authService.clearAuthData();
          _isAuthenticated = false;
        }
      } else {
        debugPrint('🔐 AUTH PROVIDER: No stored token found');
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('🔐 AUTH PROVIDER ERROR: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      await _authService.login(
        email: email,
        password: password,
      );

      // Get stored credentials after login
      _authToken = await _authService.getToken();
      _userData = await _storageService.getUserData();
      _isAuthenticated = true;

      debugPrint('🔐 AUTH PROVIDER: Login successful');
      notifyListeners();
    } catch (e) {
      debugPrint('🔐 AUTH PROVIDER ERROR: Login failed - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      _setLoading(true);

      await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      // Get stored credentials after registration
      _authToken = await _authService.getToken();
      _userData = await _storageService.getUserData();
      _isAuthenticated = true;

      debugPrint('🔐 AUTH PROVIDER: Registration successful');
      notifyListeners();
    } catch (e) {
      debugPrint('🔐 AUTH PROVIDER ERROR: Registration failed - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);

      await _authService.clearAuthData();

      _authToken = null;
      _userData = null;
      _isAuthenticated = false;

      debugPrint('🔐 AUTH PROVIDER: Logout successful');
      notifyListeners();
    } catch (e) {
      debugPrint('🔐 AUTH PROVIDER ERROR: Logout failed - $e');
      // Even if logout fails, clear local state
      _authToken = null;
      _userData = null;
      _isAuthenticated = false;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAuth() async {
    await _initializeAuth();
  }

  Future<void> handleSocialAuth(Map<String, dynamic> authData) async {
    try {
      _setLoading(true);

      // Save the token and user data from social auth
      await _storageService.saveToken(authData['token']);
      if (authData['expires_at'] != null) {
        await _storageService.saveTokenExpiry(authData['expires_at']);
      }
      await _storageService.saveUserData(authData['user']);

      _authToken = authData['token'];
      _userData = authData['user'];
      _isAuthenticated = true;

      debugPrint('🔐 AUTH PROVIDER: Social authentication successful');
      notifyListeners();
    } catch (e) {
      debugPrint('🔐 AUTH PROVIDER ERROR: Social authentication failed - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
