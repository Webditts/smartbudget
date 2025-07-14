import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../utils/password_utils.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  /// Load Firestore user data after auth login
  Future<void> _loadUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      _currentUser = AppUser.fromJson(doc.data()!);
      notifyListeners();
    }
  }

  /// Register a student
  Future<String?> registerStudent(String email, String password) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final hashedPassword = PasswordUtils.hashPassword(password);

      final newUser = AppUser(
        id: userCred.user!.uid,
        email: email,
        password: hashedPassword,
        role: UserRole.student,
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());

      _currentUser = newUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Register error: ${e.code} - ${e.message}");
      return e.message;
    }
  }

  /// Register a parent if student exists
  Future<String?> registerParent(String parentEmail, String password, String studentEmail) async {
    try {
      final students = await _firestore
          .collection('users')
          .where('email', isEqualTo: studentEmail)
          .where('role', isEqualTo: UserRole.student.toString())
          .get();

      if (students.docs.isEmpty) {
        return "Student email not found.";
      }

      final userCred = await _auth.createUserWithEmailAndPassword(
        email: parentEmail,
        password: password,
      );

      final hashedPassword = PasswordUtils.hashPassword(password);

      final newUser = AppUser(
        id: userCred.user!.uid,
        email: parentEmail,
        password: hashedPassword,
        role: UserRole.parent,
        studentEmail: studentEmail,
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());

      _currentUser = newUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Register error: ${e.code} - ${e.message}");
      return e.message;
    }
  }

  /// Login and load user data
  Future<String?> login(String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserData(userCred.user!.uid);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login error: ${e.code} - ${e.message}");
      return e.message;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
