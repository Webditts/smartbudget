enum UserRole { student, parent }

class AppUser {
  final String id;
  final String email;
  final String password; // For demo only; hash in production
  final UserRole role;
  final String? studentEmail; // only for parent accounts

  AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
    this.studentEmail,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'password': password,
    'role': role.toString(),
    'studentEmail': studentEmail,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      role: UserRole.values.firstWhere(
            (e) => e.toString() == json['role'],
        orElse: () => UserRole.student,
      ),
      studentEmail: json['studentEmail'],
    );
  }
}
