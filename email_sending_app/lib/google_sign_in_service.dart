// google_sign_in_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class GoogleSignInService {
  // Private constructor
  GoogleSignInService._privateConstructor();

  // Single instance
  static final GoogleSignInService _instance = GoogleSignInService._privateConstructor();

  // Factory constructor to return the same instance
  factory GoogleSignInService() {
    return _instance;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      gmail.GmailApi.gmailSendScope,
      gmail.GmailApi.gmailComposeScope,
      'email',
    ],
  );

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;

  // Initialize the sign-in process
  Future<void> initialize() async {
    _currentUser = _googleSignIn.currentUser;
    if (_currentUser == null) {
      _currentUser = await _googleSignIn.signInSilently();
      logger.e('Silent sign-in result: $_currentUser');
    } else {
      logger.e('Already signed in: $_currentUser');
    }
  }

  // Prompt user to sign in
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        // User canceled the sign-in
        logger.e('User canceled Google Sign-In.');
        return false;
      }

      final auth = await _currentUser!.authentication;

      // Store tokens securely
      await _secureStorage.write(key: 'accessToken', value: auth.accessToken);
      await _secureStorage.write(key: 'idToken', value: auth.idToken);
      // Note: Gmail API primarily uses access tokens
      logger.e('Google Sign-In successful. Access Token: ${auth.accessToken}');
      return true;
    } catch (error, stacktrace) {
      logger.e('Error during Google Sign-In: $error');
      logger.e('Stacktrace: $stacktrace');
      return false;
    }
  }

  // Sign out the user
  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'idToken');
    _currentUser = null;
    logger.e('User signed out from Google.');
  }

  // Get authenticated Gmail API client
  Future<gmail.GmailApi?> getGmailApiClient() async {
    if (_currentUser == null) {
      logger.e('No Google user is connected.');
      return null;
    }

    final auth = await _currentUser!.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      logger.e('Access token is null.');
      return null;
    }

    final authClient = AuthenticatedClient(accessToken);

    return gmail.GmailApi(authClient);
  }
}

// Custom authenticated client
class AuthenticatedClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  AuthenticatedClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
