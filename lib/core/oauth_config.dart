/// OAuth 2.0 Configuration for RUDN ID
/// 
/// DISCOVERED ENDPOINTS (Nov 15, 2025):
/// - Authorization: https://id.rudn.ru/sign-in (confirmed from website)
/// - Token: https://id.rudn.ru/token (standard endpoint - verify with RUDN ID team)
/// - Website client_id: 4f8afa25-70e8-4ef3-a7ff-c8a8d71dac51 (DO NOT USE - for reference only)
/// 
/// IMPORTANT: You MUST register your mobile app separately to get your own client_id
class OAuthConfig {
  // OAuth 2.0 / OIDC Endpoints - ✅ VERIFIED via OIDC Discovery (Nov 15, 2025)
  // Source: https://id.rudn.ru/.well-known/openid-configuration
  
  /// Authorization endpoint - User login page
  static const String authorizationEndpoint = 'https://id.rudn.ru/sign-in';
  
  /// Token endpoint - Exchange authorization code for tokens
  /// Note: API endpoints use id-api.rudn.ru subdomain
  static const String tokenEndpoint = 'https://id-api.rudn.ru/api/v1/oauth2/token';
  
  /// UserInfo endpoint - Fetch authenticated user's profile
  static const String userInfoEndpoint = 'https://id-api.rudn.ru/api/v1/oauth2/me';
  
  /// Logout/End Session endpoint - Terminate OAuth session
  static const String endSessionEndpoint = 'https://id-api.rudn.ru/api/v1/oauth2/logout';
  
  // Client Configuration
  // ⚠️ CRITICAL: You MUST register your mobile app with RUDN ID to get YOUR OWN client_id
  // DO NOT use the website's client_id (4f8afa25-70e8-4ef3-a7ff-c8a8d71dac51)
  
  /// Your app's client ID - obtain by registering with RUDN ID
  /// Contact: RUDN ID administrators to register your app
  static const String clientId = const String.fromEnvironment(
    'RUDN_OAUTH_CLIENT_ID',
    defaultValue: 'YOUR_MOBILE_APP_CLIENT_ID_HERE',
  );
  
  /// Client secret - OPTIONAL for mobile apps (PKCE flow doesn't require it)
  /// Leave empty unless RUDN ID specifically requires it
  static const String clientSecret = ''; // Mobile apps should NOT use client secrets
  
  // Redirect URI - MUST match what you register with RUDN ID
  // ⚠️ IMPORTANT: This is YOUR app's custom scheme, NOT the website's redirect_uri
  // Website uses: http://seasons.rudn.ru/oauth/login_callback (DO NOT USE THIS)
  // Your app uses: com.lebedev.seasons://oauth2redirect
  // 
  // When registering your app with RUDN ID, provide THIS redirect URI:
  static const String redirectUrl = 'com.lebedev.seasons://oauth2redirect';
  
  // OAuth Scopes - ✅ Available scopes from OIDC Discovery:
  // Supported: openid, profile, passport, education, job, contact_info
  // Claims: phone, email
  static const List<String> scopes = [
    'openid',       // Required for OIDC
    'profile',      // User name and basic profile
    'contact_info', // Phone and email (includes 'email' claim)
    // Optional scopes (add if needed):
    // 'passport',   // Passport information
    // 'education',  // Education/student information
    // 'job',        // Employment information
  ];
  
  // ✅ OIDC Discovery URL - VERIFIED WORKING!
  // Using discovery is MORE RELIABLE than manual endpoints
  // Discovery document auto-updates if RUDN ID changes endpoints
  static const String? discoveryUrl = 'https://id.rudn.ru/.well-known/openid-configuration';
  
  // Additional Parameters (optional)
  static const Map<String, String> additionalParameters = {
    // Add any custom parameters required by RUDN ID
    // e.g., 'prompt': 'login',
  };
  
  // Token Storage Keys
  static const String accessTokenKey = 'oauth_access_token';
  static const String refreshTokenKey = 'oauth_refresh_token';
  static const String idTokenKey = 'oauth_id_token';
  static const String tokenExpiryKey = 'oauth_token_expiry';
  static const String userInfoKey = 'oauth_user_info';
  
  /// Validates that OAuth configuration is properly set up
  /// Call this before attempting to use OAuth
  static void validate() {
    if (clientId == 'YOUR_MOBILE_APP_CLIENT_ID_HERE' || clientId.isEmpty) {
      throw Exception(
        'OAuth client_id not configured!\n\n'
        'You must register your mobile app with RUDN ID and obtain a client_id.\n'
        'Then set it using:\n'
        '  flutter run --dart-define=RUDN_OAUTH_CLIENT_ID=your_actual_client_id\n\n'
        'See RUDN_ID_INTEGRATION.md for detailed instructions.',
      );
    }
  }
}
