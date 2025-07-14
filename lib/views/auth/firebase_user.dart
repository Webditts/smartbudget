import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUserHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the current logged-in Firebase user
  static User? get user => _auth.currentUser;

  /// Returns true if a user is currently logged in
  static bool get isLoggedIn => user != null;

  /// Returns the UID of the current user
  static String? get uid => user?.uid;

  /// Returns the email of the current user
  static String? get email => user?.email;

  /// Refreshes the current user data
  static Future<void> refresh() async {
    if (user != null) {
      await user!.reload();
    }
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
