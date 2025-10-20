import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/utils/network_error_handler.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';

class FeedbackService {
  late Dio _dio;

  FeedbackService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final authService = AuthService();
        final token = await authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// Submit feedback to the server
  Future<Map<String, dynamic>> submitFeedback({
    required String category,
    required String priority,
    required String subject,
    required String message,
    String? email,
    bool includeSystemInfo = true,
    Map<String, dynamic>? systemInfo,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.post(
        '/feedback/submit',
        data: {
          'category': category,
          'priority': priority,
          'subject': subject,
          'message': message,
          'email': email,
          'includeSystemInfo': includeSystemInfo,
          'systemInfo': systemInfo,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to submit feedback');
      }
    } on DioException catch (e) {
      if (context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'submitFeedback',
          onRetry: () => submitFeedback(
            category: category,
            priority: priority,
            subject: subject,
            message: message,
            email: email,
            includeSystemInfo: includeSystemInfo,
            systemInfo: systemInfo,
            context: context,
          ),
        );
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('Error submitting feedback: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => submitFeedback(
                category: category,
                priority: priority,
                subject: subject,
                message: message,
                email: email,
                includeSystemInfo: includeSystemInfo,
                systemInfo: systemInfo,
                context: context,
              ),
            ),
          ),
        );
      }

      rethrow;
    }
  }

  /// Get feedback categories from the server
  Future<List<String>> getCategories({BuildContext? context}) async {
    try {
      final response = await _dio.get('/feedback/categories');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Failed to fetch categories');
      }
    } on DioException catch (e) {
      if (context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'getCategories',
          onRetry: () => getCategories(context: context),
        );
      }

      // Return default categories on error
      return [
        'General Feedback',
        'Bug Report',
        'Feature Request',
        'Performance Issue',
        'UI/UX Suggestion',
        'Content Issue',
        'Account Problem',
        'Other',
      ];
    } catch (e) {
      debugPrint('Error fetching categories: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories. Using defaults.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Return default categories on error
      return [
        'General Feedback',
        'Bug Report',
        'Feature Request',
        'Performance Issue',
        'UI/UX Suggestion',
        'Content Issue',
        'Account Problem',
        'Other',
      ];
    }
  }

  /// Get priority levels from the server
  Future<List<String>> getPriorities({BuildContext? context}) async {
    try {
      final response = await _dio.get('/feedback/priorities');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Failed to fetch priorities');
      }
    } on DioException catch (e) {
      if (context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'getPriorities',
          onRetry: () => getPriorities(context: context),
        );
      }

      // Return default priorities on error
      return ['Low', 'Medium', 'High', 'Critical'];
    } catch (e) {
      debugPrint('Error fetching priorities: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load priorities. Using defaults.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Return default priorities on error
      return ['Low', 'Medium', 'High', 'Critical'];
    }
  }

  /// Get user's feedback history
  Future<Map<String, dynamic>> getUserFeedback({BuildContext? context}) async {
    try {
      final response = await _dio.get('/feedback/history');

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      } else {
        throw Exception('Failed to fetch feedback history');
      }
    } on DioException catch (e) {
      if (context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'getUserFeedback',
          onRetry: () => getUserFeedback(context: context),
        );
      }

      // Return empty data on error
      return {
        'feedback': [],
        'total': 0,
      };
    } catch (e) {
      debugPrint('Error fetching feedback history: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load feedback history.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Return empty data on error
      return {
        'feedback': [],
        'total': 0,
      };
    }
  }
}
