import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Authentication guard utility to ensure user is properly logged in
class AuthGuard {
  static final ApiService _apiService = ApiService();
  
  /// Check if user is authenticated and redirect to login if not
  static Future<bool> checkAndRedirect(BuildContext context) async {
    try {
      // Check for stored access token
      final token = await _apiService.getStoredAccessToken();
      final currentUser = _apiService.getCurrentUser();
      
      debugPrint('[AuthGuard] Token exists: ${token != null}');
      debugPrint('[AuthGuard] User exists: ${currentUser != null}');
      
      if (token == null || currentUser == null) {
        debugPrint('[AuthGuard] Authentication failed, redirecting to login');
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('[AuthGuard] Error checking authentication: $e');
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
      return false;
    }
  }
  
  /// Check authentication status without redirecting
  static Future<bool> isAuthenticated() async {
    try {
      final token = await _apiService.getStoredAccessToken();
      final currentUser = _apiService.getCurrentUser();
      return token != null && currentUser != null;
    } catch (e) {
      return false;
    }
  }
}
