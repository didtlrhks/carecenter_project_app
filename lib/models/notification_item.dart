class NotificationItem {
  const NotificationItem({
    required this.id,
    this.centerId,
    this.jobRequestId,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String? centerId;
  final String? jobRequestId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  String? get targetJobRequestId {
    if (jobRequestId != null && jobRequestId!.isNotEmpty) return jobRequestId;
    final fromPayload = payload?['jobRequestId'];
    if (fromPayload is String && fromPayload.isNotEmpty) return fromPayload;
    return null;
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? payload;
    final raw = json['payload'];
    if (raw is Map) payload = Map<String, dynamic>.from(raw);
    return NotificationItem(
      id: json['id'] as String,
      centerId: json['centerId'] as String?,
      jobRequestId: json['jobRequestId'] as String?,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      payload: payload,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now().toUtc(),
    );
  }
}
