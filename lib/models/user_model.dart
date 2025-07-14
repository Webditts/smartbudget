enum UserRole { student, parent }

class AppUser {
  final String id;
  final String email;
  final String password; // For demo only; hash in production
  final UserRole role;
  final String? studentEmail; // Only for parent accounts

  AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
    this.studentEmail,
  });

  /// Convert AppUser to JSON format for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'role': role.toString(), // Stores as "UserRole.parent" or "UserRole.student"
      'studentEmail': studentEmail,
    };
  }

  /// Create AppUser instance from JSON (Firebase doc)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: _parseRole(json['role']),
      studentEmail: json['studentEmail'] as String?,
    );
  }

  /// Helper method to safely parse role
  static UserRole _parseRole(dynamic roleValue) {
    if (roleValue is String) {
      switch (roleValue) {
        case 'UserRole.parent':
        case 'parent':
          return UserRole.parent;
        case 'UserRole.student':
        case 'student':
          return UserRole.student;
      }
    }
    return UserRole.student; // Default fallback
  }
}
