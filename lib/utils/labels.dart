import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const dowLabels = ['일', '월', '화', '수', '목', '금', '토'];

String requestTypeLabel(String type) {
  switch (type) {
    case 'BACKUP':
      return '대타';
    case 'NEW':
      return '신규';
    case 'ADDITIONAL':
      return '추가 근무';
    case 'TEMPORARY':
      return '임시';
    default:
      return type;
  }
}

String serviceTypeLabel(String type) {
  switch (type) {
    case 'VISIT_CARE':
      return '방문요양';
    case 'VISIT_BATH':
      return '방문목욕';
    case 'VISIT_NURSING':
      return '방문간호';
    case 'DAY_NIGHT':
      return '주야간보호';
    case 'OTHER':
      return '기타';
    default:
      return type;
  }
}

String scheduleModeLabel(String mode) {
  switch (mode) {
    case 'SINGLE':
      return '단일';
    case 'RECURRING':
      return '반복';
    default:
      return mode;
  }
}

String jobStatusLabel(String status) {
  switch (status) {
    case 'DRAFT':
      return '작성 중';
    case 'OPEN':
      return '모집 중';
    case 'PENDING_APPROVAL':
      return '지원자 대기';
    case 'ASSIGNED':
      return '최종 확정';
    case 'CANCELLED':
      return '취소';
    case 'EXPIRED':
      return '만료';
    default:
      return status;
  }
}

/// 앱 리스트/상세에 쓰는 내 지원 상태 배지.
String candidateBadge(String status) {
  switch (status) {
    case 'INVITED':
      return '새 콜';
    case 'APPLIED':
      return '센터 확인 중';
    case 'SELECTED':
      return '확정';
    case 'NOT_SELECTED':
      return '마감';
    case 'REJECTED':
      return '거절';
    case 'CANCELLED':
      return '취소';
    case 'EXPIRED':
      return '만료';
    default:
      return status;
  }
}

(Color, Color) candidateBadgeColors(String status) {
  switch (status) {
    case 'INVITED':
      return (AppColors.infoSoft, const Color(0xFF1A7A96));
    case 'APPLIED':
      return (AppColors.purpleSoft, AppColors.purple);
    case 'SELECTED':
      return (AppColors.successSoft, AppColors.primaryDark);
    case 'NOT_SELECTED':
      return (const Color(0xFFEEF1F4), AppColors.body);
    case 'REJECTED':
      return (AppColors.dangerSoft, AppColors.danger);
    default:
      return (const Color(0xFFEEF1F4), AppColors.body);
  }
}

String scheduleStatusLabel(String status) {
  switch (status) {
    case 'SCHEDULED':
      return '예정';
    case 'COMPLETED':
      return '완료';
    case 'CANCELLED':
      return '취소';
    case 'REPLACED':
      return '대타 대체';
    default:
      return status;
  }
}

String genderLabel(String? gender) {
  switch (gender) {
    case 'MALE':
      return '남';
    case 'FEMALE':
      return '여';
    case 'OTHER':
      return '기타';
    case 'UNDISCLOSED':
      return '미공개';
    default:
      return '미설정';
  }
}

/// 서버 title보다 화면 카피를 우선한다.
String notificationCopy(String type, String fallback) {
  switch (type) {
    case 'JOB_REQUEST_INVITED':
      return '새로운 근무 요청이 있습니다';
    case 'ASSIGNED':
      return '근무가 확정되었습니다';
    case 'NOT_SELECTED':
      return '근무 요청이 마감되었습니다';
    case 'JOB_REQUEST_CANCELLED':
      return '근무 요청이 취소되었습니다';
    default:
      return fallback;
  }
}

String daysOfWeekLabel(List<int> days) {
  if (days.isEmpty) return '—';
  return days.map((d) => d >= 0 && d < dowLabels.length ? dowLabels[d] : '$d').join('·');
}
