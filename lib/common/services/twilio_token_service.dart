import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:chime/common/config/twilio_config.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

/// Service to generate Twilio Video access tokens
///
/// NOTE: In production, token generation should be done on a backend server
/// for security reasons. This service is for testing purposes only.
class TwilioTokenService {
  final Logger log = Logger();
  final Uuid _uuid = const Uuid();

  /// Generate a Twilio Video access token
  ///
  /// [identity] - The identity of the user (e.g., username or user ID)
  /// [roomName] - The name of the room to join (optional, '*' allows joining any room)
  /// [ttl] - Time to live in seconds (default: 3600 = 1 hour)
  ///
  /// Returns a JWT access token that can be used to connect to Twilio Video rooms
  Future<String> generateAccessToken({required String identity, String? roomName, int ttl = 3600}) async {
    try {
      log.d("TwilioTokenService:::generateAccessToken::identity: $identity, roomName: $roomName");

      // If API Key credentials are available, use JWT generation
      if (TwilioConfig.apiKeySid != 'SK...' && TwilioConfig.apiKeySecret != '...') {
        return _generateJwtToken(identity: identity, roomName: roomName, ttl: ttl);
      } else {
        // Fallback: Generate token via Twilio REST API (not implemented here)
        log.w("TwilioTokenService:::API Key credentials not configured. Using HTTP API method.");
        return await _generateTokenViaHttp(identity: identity, roomName: roomName ?? '*', ttl: ttl);
      }
    } catch (e) {
      log.e("TwilioTokenService:::generateAccessToken::Error: $e");
      rethrow;
    }
  }

  /// Generate JWT token using API Key credentials
  String _generateJwtToken({required String identity, String? roomName, int ttl = 3600}) {
    try {
      // Validate credentials
      if (TwilioConfig.apiKeySid.isEmpty || TwilioConfig.apiKeySecret.isEmpty) {
        throw Exception('API Key credentials are not configured');
      }
      if (TwilioConfig.accountSid.isEmpty) {
        throw Exception('Account SID is not configured');
      }

      // Get current time in seconds
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiry = now + ttl;

      log.d("TwilioTokenService:::Generating JWT token::identity: $identity, roomName: ${roomName ?? '*'}, expiry: $expiry");

      // Create JWT claims following Twilio Access Token format
      final claims = {
        'iss': TwilioConfig.apiKeySid, // API Key SID
        'sub': TwilioConfig.accountSid, // Account SID
        'iat': now, // Issued at
        'nbf': now, // Not before
        'exp': expiry, // Expiration
        'jti': _uuid.v4(), // Token ID
        'grants': {
          'identity': identity,
          'video': {'room': roomName ?? '*'},
        },
      };

      // Create JWT with Twilio-required header (cty)
      final token = JWT(claims, header: {'typ': 'JWT', 'cty': 'twilio-fpa;v=1'});

      // Sign the token with the API Key Secret using HS256
      final jwtString = token.sign(SecretKey(TwilioConfig.apiKeySecret));

      log.d("TwilioTokenService:::Generated JWT token successfully (length: ${jwtString.length})");
      return jwtString;
    } catch (e) {
      log.e("TwilioTokenService:::_generateJwtToken::Error: $e");
      rethrow;
    }
  }

  /// Generate token using Account SID and Auth Token
  ///
  /// NOTE: Twilio doesn't provide a direct REST API for token generation.
  /// This method creates a token structure but requires API Key credentials for signing.
  ///
  /// For testing, you need to:
  /// 1. Go to Twilio Console (https://console.twilio.com)
  /// 2. Navigate to Account -> API Keys & Tokens
  /// 3. Create a new API Key (note down the SID and Secret)
  /// 4. Update TwilioConfig with apiKeySid and apiKeySecret
  Future<String> _generateTokenViaHttp({required String identity, required String roomName, int ttl = 3600}) async {
    log.w("TwilioTokenService:::Token generation requires API Key credentials");
    log.w("TwilioTokenService:::Please create an API Key in Twilio Console and update TwilioConfig");

    // For now, we'll show a helpful error message
    throw Exception(
      'Twilio access tokens require API Key SID and Secret to be generated.\n\n'
      'To set up for testing:\n'
      '1. Go to https://console.twilio.com\n'
      '2. Navigate to Account -> API Keys & Tokens\n'
      '3. Click "Create API Key"\n'
      '4. Copy the SID (starts with SK...) and Secret\n'
      '5. Update lib/common/config/twilio_config.dart with:\n'
      '   - apiKeySid = "SK..."\n'
      '   - apiKeySecret = "..."\n\n'
      'Alternatively, use a backend service to generate tokens securely.',
    );
  }

  /// Quick test token generator (for development/testing only)
  ///
  /// WARNING: This generates a token structure but may not be valid without proper signing
  /// For actual testing, you need either:
  /// 1. API Key SID and Secret configured
  /// 2. A backend endpoint that generates tokens
  /// 3. Use Twilio's test credentials with proper API setup
  String generateTestToken({required String identity, String? roomName}) {
    log.w("TwilioTokenService:::generateTestToken::WARNING - Test token may not work without proper API Key credentials");

    return 'TEST_TOKEN_PLACEHOLDER_${identity}_${roomName ?? "default"}';
  }
}
