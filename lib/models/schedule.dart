class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.centerId,
    required this.recipientId,
    required this.caregiverId,
    this.jobRequestId,
    required this.source,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.serviceType,
    this.notes,
    this.recipientName,
    this.recipientRegionCode,
    this.centerName,
  });

  final String id;
  final String centerId;
  final String recipientId;
  final String caregiverId;
  final String? jobRequestId;
  final String source;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String serviceType;
  final String? notes;
  final String? recipientName;
  final String? recipientRegionCode;
  final String? centerName;

  bool get isCancelled => status == 'CANCELLED';
  bool get isUpcoming => !isCancelled && startsAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)));

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final recipient = json['recipient'];
    final center = json['center'];
    return ScheduleItem(
      id: json['id'] as String,
      centerId: json['centerId'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      caregiverId: json['caregiverId'] as String? ?? '',
      jobRequestId: json['jobRequestId'] as String?,
      source: json['source'] as String? ?? '',
      status: json['status'] as String? ?? 'SCHEDULED',
      startsAt: DateTime.parse(json['startsAt'] as String).toUtc(),
      endsAt: DateTime.parse(json['endsAt'] as String).toUtc(),
      serviceType: json['serviceType'] as String? ?? '',
      notes: json['notes'] as String?,
      recipientName: recipient is Map ? recipient['name'] as String? : null,
      recipientRegionCode: recipient is Map ? recipient['regionCode'] as String? : null,
      centerName: center is Map ? center['name'] as String? : null,
    );
  }
}
