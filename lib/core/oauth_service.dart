import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:seasons/core/oauth_config.dart';

/// Service for handling OAuth 2.0 / OIDC authentication with RUDN ID
class OAuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Initiate OAuth login flow
  /// 
  /// This will:
  /// 1. Open RUDN ID login page in an in-app browser
  /// 2. Handle user authentication
  /// 3. Capture the redirect with authorization code
  /// 4. Exchange code for tokens
  /// 5. Store tokens securely
  /// 
  /// Returns the user's display name/login or null if login failed
  Future<String?> login() async {
    try {
      // Validate OAuth configuration before attempting login
      OAuthConfig.validate();
      
      debugPrint('🔐 Starting OAuth login flow...');
      debugPrint('✅ Using OIDC Discovery: ${OAuthConfig.discoveryUrl}');
      
      // Configure the authorization and token request
      // ✅ Using OIDC Discovery for automatic endpoint resolution
      final AuthorizationTokenRequest request = AuthorizationTokenRequest(
        OAuthConfig.clientId,
        OAuthConfig.redirectUrl,
        discoveryUrl: OAuthConfig.discoveryUrl, // Auto-discover endpoints
        scopes: OAuthConfig.scopes,
        additionalParameters: OAuthConfig.additionalParameters,
      );

      // This will open the in-app browser and handle the full flow
      final AuthorizationTokenResponse? result = 
          await _appAuth.authorizeAndExchangeCode(request);

      if (result != null) {
        debugPrint('✅ OAuth login successful');
        debugPrint('📝 Access token: ${result.accessToken?.substring(0, 20)}...');
        
        // Store tokens securely
        await _storeTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          idToken: result.idToken,
          accessTokenExpiration: result.accessTokenExpirationDateTime,
        );

        // Get user info
        final userInfo = await _getUserInfo(result.accessToken!);
        if (userInfo != null) {
          await _storage.write(
            key: OAuthConfig.userInfoKey,
            value: jsonEncode(userInfo),
          );
          
          // Extract user's name/login from user info
          // Adjust field name based on RUDN ID's response
          return userInfo['name'] ?? 
                 userInfo['preferred_username'] ?? 
                 userInfo['email'] ?? 
                 'User';
        }
        
        return 'User';
      } else {
        debugPrint('❌ OAuth login cancelled or failed');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ OAuth login error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Logout and clear all stored tokens
  Future<void> logout() async {
    try {
      debugPrint('🔓 Logging out...');
      
      // Get tokens for logout endpoint
      final idToken = await _storage.read(key: OAuthConfig.idTokenKey);
      
      if (idToken != null) {
        try {
          // Attempt to end session with RUDN ID using discovery
          final EndSessionRequest request = EndSessionRequest(
            idTokenHint: idToken,
            postLogoutRedirectUrl: OAuthConfig.redirectUrl,
            discoveryUrl: OAuthConfig.discoveryUrl, // Auto-discover logout endpoint
          );
          
          await _appAuth.endSession(request);
          debugPrint('✅ Session ended with RUDN ID');
        } catch (e) {
          debugPrint('⚠️ Could not end session with RUDN ID: $e');
          // Continue with local logout even if remote logout fails
        }
      }
      
      // Clear all stored tokens
      await _clearTokens();
      debugPrint('✅ Local logout complete');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      // Always clear local tokens even if logout fails
      await _clearTokens();
      rethrow;
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await _storage.read(key: OAuthConfig.accessTokenKey);
    if (accessToken == null) return false;
    
    // Check if token is expired
    final expiryString = await _storage.read(key: OAuthConfig.tokenExpiryKey);
    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry)) {
        debugPrint('⚠️ Access token expired, attempting refresh...');
        return await refreshAccessToken();
      }
    }
    
    return true;
  }

  /// Get current access token, refreshing if necessary
  Future<String?> getAccessToken() async {
    final accessToken = await _storage.read(key: OAuthConfig.accessTokenKey);
    if (accessToken == null) return null;
    
    // Check if token is expired
    final expiryString = await _storage.read(key: OAuthConfig.tokenExpiryKey);
    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      // Refresh if expiring within 5 minutes
      if (DateTime.now().add(const Duration(minutes: 5)).isAfter(expiry)) {
        debugPrint('🔄 Access token expiring soon, refreshing...');
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return await _storage.read(key: OAuthConfig.accessTokenKey);
        }
      }
    }
    
    return accessToken;
  }

  /// Get stored user information
  Future<Map<String, dynamic>?> getUserInfo() async {
    final userInfoString = await _storage.read(key: OAuthConfig.userInfoKey);
    if (userInfoString == null) return null;
    
    try {
      return jsonDecode(userInfoString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error parsing user info: $e');
      return null;
    }
  }

  /// Get user's display name
  Future<String?> getUserDisplayName() async {
    final userInfo = await getUserInfo();
    if (userInfo == null) return null;
    
    // Try different possible name fields
    return userInfo['name'] ?? 
           userInfo['preferred_username'] ?? 
           userInfo['given_name'] ?? 
           userInfo['email'];
  }

  /// Refresh the access token using the refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: OAuthConfig.refreshTokenKey);
      if (refreshToken == null) {
        debugPrint('❌ No refresh token available');
        return false;
      }

      debugPrint('🔄 Refreshing access token...');
      
      final TokenRequest request = TokenRequest(
        OAuthConfig.clientId,
        OAuthConfig.redirectUrl,
        discoveryUrl: OAuthConfig.discoveryUrl, // Auto-discover token endpoint
        refreshToken: refreshToken,
      );

      final TokenResponse? response = await _appAuth.token(request);

      if (response != null) {
        await _storeTokens(
          accessToken: response.accessToken!,
          refreshToken: response.refreshToken ?? refreshToken,
          idToken: response.idToken,
          accessTokenExpiration: response.accessTokenExpirationDateTime,
        );
        
        debugPrint('✅ Access token refreshed successfully');
        return true;
      } else {
        debugPrint('❌ Token refresh failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    }
  }

  /// Store OAuth tokens securely
  Future<void> _storeTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? accessTokenExpiration,
  }) async {
    await _storage.write(key: OAuthConfig.accessTokenKey, value: accessToken);
    
    if (refreshToken != null) {
      await _storage.write(key: OAuthConfig.refreshTokenKey, value: refreshToken);
    }
    
    if (idToken != null) {
      await _storage.write(key: OAuthConfig.idTokenKey, value: idToken);
    }
    
    if (accessTokenExpiration != null) {
      await _storage.write(
        key: OAuthConfig.tokenExpiryKey,
        value: accessTokenExpiration.toIso8601String(),
      );
    }
  }

  /// Clear all stored tokens
  Future<void> _clearTokens() async {
    await _storage.delete(key: OAuthConfig.accessTokenKey);
    await _storage.delete(key: OAuthConfig.refreshTokenKey);
    await _storage.delete(key: OAuthConfig.idTokenKey);
    await _storage.delete(key: OAuthConfig.tokenExpiryKey);
    await _storage.delete(key: OAuthConfig.userInfoKey);
  }

  /// Fetch user information from RUDN ID
  Future<Map<String, dynamic>?> _getUserInfo(String accessToken) async {
    try {
      debugPrint('ℹ️ Fetching user info from RUDN ID...');
      
      // Call the userinfo endpoint with Bearer token
      final response = await http.get(
        Uri.parse(OAuthConfig.userInfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final userInfo = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ User info retrieved successfully');
        if (kDebugMode) {
          debugPrint('📋 User info keys: ${userInfo.keys.join(', ')}');
        }
        return userInfo;
      } else {
        debugPrint('❌ UserInfo request failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching user info: $e');
      return null;
    }
  }
}
