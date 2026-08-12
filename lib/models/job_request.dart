class JobCenter {
  const JobCenter({required this.id, required this.name});

  final String id;
  final String name;

  factory JobCenter.fromJson(Map<String, dynamic> json) {
    return JobCenter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class JobRequest {
  const JobRequest({
    required this.id,
    required this.status,
    required this.myCandidateStatus,
    required this.requestType,
    required this.scheduleMode,
    required this.serviceType,
    this.payAmount,
    this.regionCode,
    this.locationText,
    this.startsAt,
    this.endsAt,
    this.startDate,
    this.endDate,
    this.daysOfWeek = const [],
    this.recurrenceStartTime,
    this.recurrenceEndTime,
    this.specialRequirements,
    this.appliedAt,
    this.invitedAt,
    this.center,
  });

  final String id;
  final String status;
  final String myCandidateStatus;
  final String requestType;
  final String scheduleMode;
  final String serviceType;
  final int? payAmount;
  final String? regionCode;
  final String? locationText;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> daysOfWeek;
  final String? recurrenceStartTime;
  final String? recurrenceEndTime;
  final String? specialRequirements;
  final DateTime? appliedAt;
  final DateTime? invitedAt;
  final JobCenter? center;

  bool get isInvited => myCandidateStatus == 'INVITED';
  bool get isApplied => myCandidateStatus == 'APPLIED';
  bool get isSelected => myCandidateStatus == 'SELECTED';
  bool get isActive => isInvited || isApplied;
  bool get isPast =>
      myCandidateStatus == 'SELECTED' ||
      myCandidateStatus == 'NOT_SELECTED' ||
      myCandidateStatus == 'REJECTED' ||
      myCandidateStatus == 'CANCELLED' ||
      myCandidateStatus == 'EXPIRED';

  /// 확정 전에는 구 단위만. 서버도 locationText를 지역으로 내려준다.
  bool get canShowExactAddress => isSelected;

  factory JobRequest.fromJson(Map<String, dynamic> json) {
    return JobRequest(
      id: json['id'] as String,
      status: json['status'] as String? ?? '',
      myCandidateStatus: json['myCandidateStatus'] as String? ?? '',
      requestType: json['requestType'] as String? ?? '',
      scheduleMode: json['scheduleMode'] as String? ?? 'SINGLE',
      serviceType: json['serviceType'] as String? ?? '',
      payAmount: (json['payAmount'] as num?)?.toInt(),
      regionCode: json['regionCode'] as String?,
      locationText: json['locationText'] as String?,
      startsAt: _parseDate(json['startsAt']),
      endsAt: _parseDate(json['endsAt']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      daysOfWeek: _parseDays(json['daysOfWeek']),
      recurrenceStartTime: json['recurrenceStartTime'] as String?,
      recurrenceEndTime: json['recurrenceEndTime'] as String?,
      specialRequirements: json['specialRequirements'] as String?,
      appliedAt: _parseDate(json['appliedAt']),
      invitedAt: _parseDate(json['invitedAt']),
      center: json['center'] is Map
          ? JobCenter.fromJson(Map<String, dynamic>.from(json['center'] as Map))
          : null,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<int> _parseDays(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<num>().map((n) => n.toInt()).toList();
}
