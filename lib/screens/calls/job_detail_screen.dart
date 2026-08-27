import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api_error.dart';
import '../../models/job_request.dart';
import '../../services/api_client.dart';
import '../../state/jobs_controller.dart';
import '../../state/schedules_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/labels.dart';
import '../../utils/regions.dart';
import '../../widgets/job_when.dart';
import '../../widgets/status_badge.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobRequest? _job;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final job = await context.read<ApiClient>().myJobRequest(widget.jobId);
      if (!mounted) return;
      setState(() => _job = job);
      context.read<JobsController>().upsert(job);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isNotInvited) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인할 수 없는 근무 요청입니다.')),
        );
        Navigator.of(context).pop();
        return;
      }
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '상세 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    final confirmed = await _confirm(
      title: '가능으로 보낼까요?',
      body: '센터에 가능 의사를 전달합니다.\n진행할까요?',
      action: '보내기',
    );
    if (confirmed != true || !mounted) return;
    await _runAction(() async {
      try {
        final job = await context.read<ApiClient>().apply(widget.jobId);
        if (!mounted) return;
        setState(() => _job = job);
        context.read<JobsController>().upsert(job);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('센터에 전달되었습니다.')),
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        if (e.code == 'ALREADY_APPLIED') {
          await _load();
          return;
        }
        if (e.code == 'SCHEDULE_CONFLICT') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기존 일정과 겹칩니다')),
          );
          return;
        }
        if (e.isNotInvited) {
          Navigator.of(context).pop();
          return;
        }
        if (e.code == 'INVALID_STATE') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 마감되었거나 취소된 요청입니다.')),
          );
          await _load();
          return;
        }
        rethrow;
      }
    });
  }

  Future<void> _reject() async {
    final confirmed = await _confirm(
      title: '거절할까요?',
      body: '거절하면 이 근무에 다시 지원할 수 없습니다.',
      action: '거절',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await _runAction(() async {
      final job = await context.read<ApiClient>().reject(widget.jobId);
      if (!mounted) return;
      setState(() => _job = job);
      context.read<JobsController>().upsert(job);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('거절했습니다.')));
    });
  }

  Future<void> _withdraw() async {
    final confirmed = await _confirm(
      title: '가능 의사를 취소할까요?',
      body: '취소하면 다시 가능·거절을 선택할 수 있습니다.',
      action: '취소하기',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await _runAction(() async {
      final job = await context.read<ApiClient>().withdraw(widget.jobId);
      if (!mounted) return;
      setState(() => _job = job);
      context.read<JobsController>().upsert(job);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가능 의사를 취소했습니다.')));
    });
  }

  Future<void> _runAction(Future<void> Function() fn) async {
    setState(() => _acting = true);
    try {
      await fn();
      if (mounted) await context.read<SchedulesController>().refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.body,
                  height: 1.5,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: (destructive
                        ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                        : FilledButton.styleFrom())
                    .copyWith(
                  minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                child: Text(action),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                child: const Text('취소'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          '근무 요청',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('다시 시도')),
                      ],
                    ),
                  ),
                )
              : job == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.pageH,
                                AppSpacing.md,
                                AppSpacing.pageH,
                                AppSpacing.xl,
                              ),
                              children: [
                                _Header(job: job),
                                const SizedBox(height: AppSpacing.md),
                                _HeroSummary(job: job),
                                const SizedBox(height: AppSpacing.md),
                                _InfoCard(job: job),
                                if (job.isApplied) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  const _Notice(
                                    color: AppColors.purpleSoft,
                                    text: '센터에서 확인 중입니다.\n결과가 나오면 알려드릴게요.',
                                  ),
                                ],
                                if (job.isInvited) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  const _Notice(
                                    color: AppColors.primarySoft,
                                    text: '가능하시면 아래 버튼을 눌러 주세요.',
                                  ),
                                ],
                                if (job.isSelected) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  const _Notice(
                                    color: AppColors.successSoft,
                                    text: '근무가 확정되었습니다.\n방문 주소와 시간을 확인해 주세요.',
                                  ),
                                ],
                                if (job.myCandidateStatus == 'NOT_SELECTED') ...[
                                  const SizedBox(height: AppSpacing.md),
                                  const _Notice(
                                    color: Color(0xFFEEF1F4),
                                    text: '다른 분이 선정되어 모집이 마감되었습니다.',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (job.isInvited || job.isApplied)
                          _Actions(
                            job: job,
                            acting: _acting,
                            onApply: _apply,
                            onReject: _reject,
                            onWithdraw: _withdraw,
                          ),
                      ],
                    ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatusBadge(status: job.myCandidateStatus, large: true),
        const SizedBox(width: 10),
        Text(
          requestTypeLabel(job.requestType),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.heading,
          ),
        ),
        const Spacer(),
        Text(
          jobStatusLabel(job.status),
          style: const TextStyle(
            color: AppColors.body,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceTypeLabel(job.serviceType),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.heading,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            payLabel(job.payAmount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            jobWhenLabel(job),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    final location = job.canShowExactAddress
        ? (job.locationText?.isNotEmpty == true ? job.locationText! : regionLabel(job.regionCode))
        : regionLabel(job.regionCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row(job.canShowExactAddress ? '주소' : '지역', location),
          _row('센터', job.center?.name ?? '—'),
          _row(
            '요청사항',
            (job.specialRequirements?.trim().isNotEmpty == true)
                ? job.specialRequirements!.trim()
                : '없음',
          ),
          if (!job.canShowExactAddress)
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '방문 주소는 확정 후 확인할 수 있습니다.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.body,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.heading,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color, borderRadius: AppRadii.mdAll),
      child: Text(
        text,
        style: const TextStyle(
          height: 1.5,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.heading,
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.job,
    required this.acting,
    required this.onApply,
    required this.onReject,
    required this.onWithdraw,
  });

  final JobRequest job;
  final bool acting;
  final VoidCallback onApply;
  final VoidCallback onReject;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: job.isInvited
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: acting ? null : onReject,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        child: const Text('거절'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: acting ? null : onApply,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        child: Text(acting ? '처리 중…' : '가능'),
                      ),
                    ),
                  ],
                )
              : FilledButton(
                  onPressed: acting ? null : onWithdraw,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size.fromHeight(56),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  child: Text(acting ? '처리 중…' : '가능 취소'),
                ),
        ),
      ),
    );
  }
}
