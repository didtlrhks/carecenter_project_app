import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/job_request.dart';
import '../../state/jobs_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/labels.dart';
import '../../utils/regions.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/job_when.dart';
import '../../widgets/status_badge.dart';
import 'job_detail_screen.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobsController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('콜'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFADB7BE),
            tabs: [
              Tab(text: '진행중'),
              Tab(text: '지난 건'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JobList(
              items: jobs.active,
              loading: jobs.loading,
              error: jobs.error,
              emptyTitle: '진행 중인 콜이 없습니다',
              emptySubtitle: '센터에서 근무 요청이 오면 여기에 표시됩니다.',
              onRefresh: jobs.refresh,
            ),
            _JobList(
              items: jobs.past,
              loading: jobs.loading,
              error: jobs.error,
              emptyTitle: '지난 콜이 없습니다',
              onRefresh: jobs.refresh,
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
    required this.onRefresh,
  });

  final List<JobRequest> items;
  final bool loading;
  final String? error;
  final String emptyTitle;
  final String? emptySubtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRefresh, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.5,
                  child: EmptyState(
                    icon: Icons.campaign_outlined,
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(status: job.myCandidateStatus),
                  const Spacer(),
                  Text(
                    requestTypeLabel(job.requestType),
                    style: const TextStyle(color: AppColors.body, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${serviceTypeLabel(job.serviceType)} · ${payLabel(job.payAmount)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.heading),
              ),
              const SizedBox(height: 6),
              Text(jobWhenLabel(job), style: const TextStyle(color: AppColors.heading, height: 1.35)),
              const SizedBox(height: 4),
              Text(
                '${regionLabel(job.regionCode)} · ${job.center?.name ?? '센터'}',
                style: const TextStyle(color: AppColors.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
