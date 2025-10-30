/// Twilio Configuration
///
/// Contains test credentials for Twilio Video SDK
/// NOTE: In production, these should be stored securely on a backend server
class TwilioConfig {
  // // Test Account SID - used to exercise the REST API
  static const String accountSid = 'ACc14ae9a35a6c83d3361a8b07093376f7';

  // Test Auth Token
  static const String authToken = '5711858c1000faa1b07e5c38558262a9';

  // Video Grant API Key SID (needed for access token generation)
  //
  // TO GET YOUR API KEY:
  // 1. Go to https://console.twilio.com
  // 2. Navigate to Account -> API Keys & Tokens
  // 3. Click "Create API Key"
  // 4. Copy the SID (starts with SK...) and paste it below
  // 5. Copy the Secret and paste it in apiKeySecret below
  //
  // IMPORTANT: The Secret is only shown once! Save it securely.
  static const String apiKeySid = ''; // Replace with your API Key SID from Twilio Console

  // Video Grant API Key Secret (needed for access token generation)
  // IMPORTANT: This is only shown once when you create the API Key!
  static const String apiKeySecret = ''; // Replace with your API Key Secret from Twilio Console
}
