import 'package:flutter_test/flutter_test.dart';

import 'package:center_service_app/utils/labels.dart';
import 'package:center_service_app/utils/regions.dart';

void main() {
  test('내 지원 상태 배지는 제품 카피를 따른다', () {
    expect(candidateBadge('INVITED'), '새 콜');
    expect(candidateBadge('APPLIED'), '센터 확인 중');
    expect(candidateBadge('SELECTED'), '확정');
    expect(candidateBadge('NOT_SELECTED'), '마감');
  });

  test('알림 화면 카피', () {
    expect(notificationCopy('JOB_REQUEST_INVITED', 'x'), '새로운 근무 요청이 있습니다');
    expect(notificationCopy('ASSIGNED', 'x'), '근무가 확정되었습니다');
    expect(notificationCopy('NOT_SELECTED', 'x'), '근무 요청이 마감되었습니다');
    expect(notificationCopy('JOB_REQUEST_CANCELLED', 'x'), '근무 요청이 취소되었습니다');
  });

  test('시드 지역코드 11500은 강서구', () {
    expect(regionLabel('11500'), '서울 강서구');
  });
}
