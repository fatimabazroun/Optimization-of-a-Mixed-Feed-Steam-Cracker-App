import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AuthService {
  /// Register a new user. Cognito will email a 6-digit verification code.
  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final userAttributes = {
      AuthUserAttributeKey.name: name,
      AuthUserAttributeKey.email: email,
    };
    await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(userAttributes: userAttributes),
    );
  }

  /// Confirm registration with the 6-digit code sent to email.
  static Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
  }

  /// Resend the confirmation code to the given email.
  static Future<void> resendSignUpCode(String email) async {
    await Amplify.Auth.resendSignUpCode(username: email);
  }

  /// Sign in with email and password. Returns true if sign-in succeeded.
  /// Throws [UserNotConfirmedException] if the user hasn't verified email yet.
  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
    return result.isSignedIn;
  }

  /// Sign the current user out.
  static Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  /// Returns true if a valid session exists (user is already logged in).
  static Future<bool> isSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  }

  /// Fetches the current user's name, email and sub (unique ID) from Cognito.
  /// Returns a map with keys 'name', 'email', 'sub'.
  static Future<Map<String, String>> fetchUserAttributes() async {
    final attributes = await Amplify.Auth.fetchUserAttributes();
    final map = <String, String>{};
    for (final attr in attributes) {
      if (attr.userAttributeKey == AuthUserAttributeKey.name) {
        map['name'] = attr.value;
      } else if (attr.userAttributeKey == AuthUserAttributeKey.email) {
        map['email'] = attr.value;
      } else if (attr.userAttributeKey == CognitoUserAttributeKey.sub) {
        map['sub'] = attr.value;
      }
    }
    return map;
  }

  /// Sends a password-reset code to the given email via Cognito.
  static Future<void> resetPassword(String email) async {
    await Amplify.Auth.resetPassword(username: email);
  }

  /// Completes the password reset using the code sent to email.
  static Future<void> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Amplify.Auth.confirmResetPassword(
      username: email,
      newPassword: newPassword,
      confirmationCode: code,
    );
  }

  /// Updates the user's display name in Cognito.
  static Future<void> updateName(String newName) async {
    await Amplify.Auth.updateUserAttribute(
      userAttributeKey: AuthUserAttributeKey.name,
      value: newName,
    );
  }

  /// Returns a human-readable message from an [AuthException].
  static String friendlyError(AuthException e) {
    if (e is UserNotFoundException) return 'No account found with this email.';
    if (e is UserNotConfirmedException) return 'Please verify your email before signing in.';
    if (e is UsernameExistsException) return 'An account with this email already exists.';
    if (e is CodeMismatchException) return 'Invalid code. Please check and try again.';
    // Match remaining types by message content (not all are exported by amplify_auth_cognito)
    final msg = e.message.toLowerCase();
    if (msg.contains('not authorized') || msg.contains('incorrect username or password')) {
      return 'Incorrect password. Please try again.';
    }
    if (msg.contains('expired') || msg.contains('code has expired')) {
      return 'Code has expired. Please request a new one.';
    }
    if (msg.contains('limit exceeded') || msg.contains('too many')) {
      return 'Too many attempts. Please wait and try again.';
    }
    if (msg.contains('invalid password') || msg.contains('password did not conform')) {
      return 'Password must be at least 8 characters and include a number and special character.';
    }
    return e.message;
  }
}
