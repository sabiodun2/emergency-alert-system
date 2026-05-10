class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student' or 'security'
  final String? phoneNumber;
  final String? studentId; // For students
  final String? staffId; // For security personnel
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.studentId,
    this.staffId,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'studentId': studentId,
      'staffId': staffId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      phoneNumber: map['phoneNumber'],
      studentId: map['studentId'],
      staffId: map['staffId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}