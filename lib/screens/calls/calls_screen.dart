import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/job_request.dart';
import '../../state/jobs_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/labels.dart';
import '../../utils/regions.dart';
import '../../widgets/empty_duty_illustration.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/job_when.dart';
import '../../widgets/segmented_pills.dart';
import '../../widgets/status_badge.dart';
import 'job_detail_screen.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobsController>();
    final items = _tab == 0 ? jobs.active : jobs.past;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                AppSpacing.pageTop,
                AppSpacing.pageH,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('근무', style: AppType.pageTitle),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedPills(
                    labels: const ['진행중 공고', '지원 내역'],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            ),
            Expanded(
              child: _JobList(
                items: items,
                loading: jobs.loading,
                error: jobs.error,
                emptyTitle: _tab == 0 ? '진행 중인 근무가 없습니다' : '지원 내역이 없습니다',
                emptySubtitle: _tab == 0
                    ? '새로운 근무 요청이 오면\n여기서 확인할 수 있습니다.'
                    : '응답한 근무가 여기에 표시됩니다.',
                showDutyIllustration: _tab == 0,
                onRefresh: jobs.refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.items,
    required this.loading,
    required this.error,
    required this.emptyTitle,
    this.emptySubtitle,
    this.showDutyIllustration = false,
    required this.onRefresh,
  });

  final List<JobRequest> items;
  final bool loading;
  final String? error;
  final String emptyTitle;
  final String? emptySubtitle;
  final bool showDutyIllustration;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (error != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.body, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(onPressed: onRefresh, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: EmptyState(
                    illustration: showDutyIllustration
                        ? const EmptyDutyIllustration(size: 72)
                        : null,
                    icon: showDutyIllustration ? null : Icons.inbox_outlined,
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                    illustrationSize: 72,
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                0,
                AppSpacing.pageH,
                AppSpacing.xxl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => JobCard(job: items[i]),
            ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});

  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadii.mdAll,
      child: InkWell(
        borderRadius: AppRadii.mdAll,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(status: job.myCandidateStatus),
                  const Spacer(),
                  Text(
                    requestTypeLabel(job.requestType),
                    style: const TextStyle(
                      color: AppColors.body,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${serviceTypeLabel(job.serviceType)} · ${payLabel(job.payAmount)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                jobWhenLabel(job),
                style: const TextStyle(color: AppColors.heading, height: 1.35, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${regionLabel(job.regionCode)} · ${job.center?.name ?? '센터'}',
                style: const TextStyle(color: AppColors.body, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
