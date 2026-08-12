import '../models/job_request.dart';
import '../utils/date_format.dart';
import '../utils/labels.dart';

String jobWhenLabel(JobRequest job) {
  if (job.scheduleMode == 'RECURRING') {
    final days = daysOfWeekLabel(job.daysOfWeek);
    final start = job.startDate != null ? formatKstDate(job.startDate) : '';
    final end = job.endDate != null ? formatKstDate(job.endDate) : '';
    final range = [start, end].where((s) => s.isNotEmpty && s != '—').join(' ~ ');
    final time = [
      if (job.recurrenceStartTime != null) job.recurrenceStartTime,
      if (job.recurrenceEndTime != null) job.recurrenceEndTime,
    ].join('-');
    return [
      if (range.isNotEmpty) range,
      if (days != '—') days,
      if (time.isNotEmpty) time,
    ].join(' · ');
  }
  return formatKstRange(job.startsAt, job.endsAt);
}
