class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final double commissionRate;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.isActive = true,
    this.commissionRate = 10.0,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'CUSTOMER',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      commissionRate: (json['commission_rate'] != null)
          ? double.tryParse(json['commission_rate'].toString()) ?? 10.0
          : 10.0,
      fcmToken: json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'commission_rate': commissionRate,
      'fcm_token': fcmToken,
    };
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isDispatcher => role == 'DISPATCHER';
  bool get isDriver => role == 'DRIVER';
  bool get isCustomer => role == 'CUSTOMER';
}
