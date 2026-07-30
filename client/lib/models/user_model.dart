class UserModel {
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String profilePhoto;

  UserModel({
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    required this.createdAt,
    required this.lastLogin,
    required this.profilePhoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? 'User',
      email: json['email'],
      phone: json['phone'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : DateTime.now(),
      profilePhoto: json['profile_photo'] ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=LegalScanner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
      'profile_photo': profilePhoto,
    };
  }

  String get displayIdentifier {
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    return 'Registered User';
  }
}
