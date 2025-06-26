import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/password_utils.dart';

class AuthController extends ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  final List<AppUser> _users = []; // Temporary in-memory store

  // Register a student
  Future<String?> registerStudent(String email, String password) async {
    if (_users.any((u) => u.email == email)) {
      return "Student already exists.";
    }

    final hashedPassword = PasswordUtils.hashPassword(password);

    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      password: hashedPassword,
      role: UserRole.student,
    );

    _users.add(newUser);
    notifyListeners();
    return null;
  }

  // Register a parent only if a student with matching email exists
  Future<String?> registerParent(String parentEmail, String password, String studentEmail) async {
    final studentExists = _users.any((u) =>
    u.email == studentEmail && u.role == UserRole.student);

    if (!studentExists) return "Student email not found.";
    if (_users.any((u) => u.email == parentEmail)) {
      return "Parent already registered.";
    }

    final hashedPassword = PasswordUtils.hashPassword(password);

    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: parentEmail,
      password: hashedPassword,
      role: UserRole.parent,
      studentEmail: studentEmail,
    );

    _users.add(newUser);
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final hashedPassword = PasswordUtils.hashPassword(password);

    try {
      final user = _users.firstWhere(
            (u) => u.email == email && u.password == hashedPassword,
      );
      _currentUser = user;
      notifyListeners();
      return null; // Login successful
    } catch (e) {
      return "Invalid credentials."; // No user matched
    }
  }


  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
