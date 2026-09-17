import '../../../core/constants/app_constants.dart';

class UserProfile {
  final String id;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? skinTonePref;
  final DateTime? acceptedTermsAt;

  const UserProfile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.skinTonePref,
    this.acceptedTermsAt,
  });

  bool get hasAcceptedTerms => acceptedTermsAt != null;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.consumer;
    final roleStr = json['role'] as String?;
    if (roleStr == 'seller') parsedRole = UserRole.seller;
    if (roleStr == 'delivery') parsedRole = UserRole.delivery;
    if (roleStr == 'admin') parsedRole = UserRole.admin;

    return UserProfile(
      id: json['id'] as String,
      role: parsedRole,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      skinTonePref: json['skin_tone_pref'] as String?,
      acceptedTermsAt: json['accepted_terms_at'] != null
          ? DateTime.tryParse(json['accepted_terms_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'skin_tone_pref': skinTonePref,
      'accepted_terms_at': acceptedTermsAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? skinTonePref,
    DateTime? acceptedTermsAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      skinTonePref: skinTonePref ?? this.skinTonePref,
      acceptedTermsAt: acceptedTermsAt ?? this.acceptedTermsAt,
    );
  }
}
