class Availability {
  const Availability({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.id,
  });

  final String? id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Map<String, dynamic> toItemJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'] as String?,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }
}

class ServiceArea {
  const ServiceArea({this.id, required this.regionCode});

  final String? id;
  final String regionCode;

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      id: json['id'] as String?,
      regionCode: json['regionCode'] as String? ?? '',
    );
  }
}

class CaregiverUser {
  const CaregiverUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;

  factory CaregiverUser.fromJson(Map<String, dynamic> json) {
    return CaregiverUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class CaregiverProfile {
  const CaregiverProfile({
    required this.id,
    required this.userId,
    this.gender,
    required this.hasVehicle,
    required this.acceptsBackup,
    required this.acceptsNew,
    this.user,
    this.serviceAreas = const [],
    this.availabilities = const [],
  });

  final String id;
  final String userId;
  final String? gender;
  final bool hasVehicle;
  final bool acceptsBackup;
  final bool acceptsNew;
  final CaregiverUser? user;
  final List<ServiceArea> serviceAreas;
  final List<Availability> availabilities;

  CaregiverProfile copyWith({
    String? gender,
    bool? hasVehicle,
    bool? acceptsBackup,
    bool? acceptsNew,
    List<ServiceArea>? serviceAreas,
    List<Availability>? availabilities,
  }) {
    return CaregiverProfile(
      id: id,
      userId: userId,
      gender: gender ?? this.gender,
      hasVehicle: hasVehicle ?? this.hasVehicle,
      acceptsBackup: acceptsBackup ?? this.acceptsBackup,
      acceptsNew: acceptsNew ?? this.acceptsNew,
      user: user,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      availabilities: availabilities ?? this.availabilities,
    );
  }

  factory CaregiverProfile.fromJson(Map<String, dynamic> json) {
    return CaregiverProfile(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      gender: json['gender'] as String?,
      hasVehicle: json['hasVehicle'] as bool? ?? false,
      acceptsBackup: json['acceptsBackup'] as bool? ?? false,
      acceptsNew: json['acceptsNew'] as bool? ?? false,
      user: json['user'] is Map
          ? CaregiverUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      serviceAreas: _mapList(json['serviceAreas'], ServiceArea.fromJson),
      availabilities: _mapList(json['availabilities'], Availability.fromJson),
    );
  }
}

List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) map) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map) map(Map<String, dynamic>.from(item)),
  ];
}
