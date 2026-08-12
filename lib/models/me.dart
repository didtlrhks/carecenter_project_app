class CenterMembership {
  const CenterMembership({
    required this.id,
    required this.name,
    required this.status,
    required this.role,
  });

  final String id;
  final String name;
  final String status;
  final String role;

  bool get isCaregiver => role == 'CAREGIVER';

  factory CenterMembership.fromJson(Map<String, dynamic> json) {
    return CenterMembership(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'role': role,
      };
}

class Me {
  const Me({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.platformRole,
    required this.centers,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String platformRole;
  final List<CenterMembership> centers;

  bool get isCaregiver => centers.any((c) => c.isCaregiver);

  String get caregiverCenterName {
    final hit = centers.where((c) => c.isCaregiver);
    if (hit.isEmpty) return '';
    return hit.first.name;
  }

  factory Me.fromJson(Map<String, dynamic> json) {
    final raw = json['centers'];
    final centers = <CenterMembership>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          centers.add(CenterMembership.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return Me(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      platformRole: json['platformRole'] as String? ?? 'NONE',
      centers: centers,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'platformRole': platformRole,
        'centers': centers.map((c) => c.toJson()).toList(),
      };
}

class AuthPayload {
  const AuthPayload({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final Me user;

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    return AuthPayload(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: Me.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}

class RefreshTokens {
  const RefreshTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory RefreshTokens.fromJson(Map<String, dynamic> json) {
    return RefreshTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
