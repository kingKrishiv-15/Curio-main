import 'package:flutter/material.dart';
import '../../../core/services/family_service.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/curio_gloss.dart';

class FamilyInboxPage extends StatefulWidget {
  const FamilyInboxPage({this.reportsOnly = false, super.key});
  final bool reportsOnly;
  @override
  State<FamilyInboxPage> createState() => _FamilyInboxPageState();
}

class _FamilyInboxPageState extends State<FamilyInboxPage> {
  final _service = FamilyService();
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = widget.reportsOnly ? _service.reports() : _service.notifications();
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    title: widget.reportsOnly ? 'Weekly reports' : 'Your inbox',
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('We couldn’t load this just yet.'),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        final items = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _items;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              if (items.isEmpty)
                CurioGloss(
                  child: Column(
                    children: [
                      Icon(
                        widget.reportsOnly
                            ? Icons.insights_outlined
                            : Icons.notifications_none_rounded,
                        size: 42,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.reportsOnly
                            ? 'Your story is just beginning.'
                            : 'You’re all caught up.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.reportsOnly
                            ? 'Your first report arrives after a completed calendar week. In the meantime, your parent dashboard shows your progress.'
                            : 'Reminders and new weekly reports will appear here. Set your preferences in the parent dashboard.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: widget.reportsOnly
                      ? WeeklyReportCard(report: item)
                      : CurioGloss(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item['kind'] == 'weekly_report'
                                        ? Icons.insights_outlined
                                        : Icons.notifications_outlined,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  if (item['read_at'] == null)
                                    const Badge(label: Text('New')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(item['body'] as String),
                              const SizedBox(height: 8),
                              Text(
                                (item['created_at'] as String).substring(0, 10),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (item['read_at'] == null)
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await _service.markRead(
                                        item['id'] as String,
                                      );
                                      if (mounted) setState(_reload);
                                    } catch (_) {
                                      if (context.mounted)
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Could not mark this as read. Try again.',
                                            ),
                                          ),
                                        );
                                    }
                                  },
                                  child: const Text('Mark as read'),
                                ),
                              if (item['kind'] == 'weekly_report')
                                TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const FamilyInboxPage(
                                        reportsOnly: true,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Read weekly reports'),
                                ),
                            ],
                          ),
                        ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class WeeklyReportCard extends StatelessWidget {
  const WeeklyReportCard({required this.report, super.key});
  final Map<String, dynamic> report;
  @override
  Widget build(BuildContext context) {
    final summary = report['summary'] as Map<String, dynamic>;
    final learners = summary['learners'] as List;
    return CurioGloss(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CurioEyebrow('A week of little discoveries'),
          const SizedBox(height: 12),
          Text(
            '${summary['week_start']} – ${summary['week_end']}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final learner in learners) ...[
            const SizedBox(height: 20),
            Text(
              learner['name'] as String,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${learner['activities']} activities · ${learner['practice_days']} practice days',
            ),
            const SizedBox(height: 8),
            Text(
              '${learner['total_xp']} lifetime XP · ${learner['discoveries']} discoveries collected',
            ),
            const SizedBox(height: 16),
            for (final entry
                in (learner['skills'] as Map<String, dynamic>).entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${entry.key}: ${((entry.value as num) * 100).round()}% mastery',
                ),
              ),
            const Text('Ask your explorer: “What surprised you this week?”'),
          ],
        ],
      ),
    );
  }
}
