import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import 'report_detail_manager_screen.dart';

class LocationTasksScreen extends StatefulWidget {
  const LocationTasksScreen({super.key});

  @override
  State<LocationTasksScreen> createState() => _LocationTasksScreenState();
}

class _LocationTasksScreenState extends State<LocationTasksScreen> {
  String? _organizationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;
    if (userId != null) {
      final profile = await authService.getUserProfile(userId);
      if (profile != null && mounted) {
        setState(() {
          _organizationId = profile.organizationId;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _organizationId == null) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reportService = Provider.of<ReportService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks by Location"),
      ),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: StreamBuilder<List<Report>>(
          stream: reportService.getReports(_organizationId!),
          builder: (context, reportSnapshot) {
            if (reportSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (reportSnapshot.hasError) {
              return Center(child: Text("Error loading reports"));
            }

            final allReports = reportSnapshot.data ?? [];

            // Grouping by location
            final groupedReports = <String, List<Report>>{};
            for (var report in allReports) {
              groupedReports.putIfAbsent(report.location, () => []).add(report);
            }

            final locations = groupedReports.keys.toList()..sort();

            if (locations.isEmpty) {
              return const Center(child: Text("No tasks found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                final reports = groupedReports[location]!;
                return _LocationGroup(
                  title: location,
                  reports: reports,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LocationGroup extends StatelessWidget {
  final String title;
  final List<Report> reports;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _LocationGroup({
    required this.title,
    required this.reports,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "$title (${reports.length})",
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (reports.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28.0, bottom: 16),
            child: Text("No tasks for this location", style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          )
        else
          ...reports.map((report) => _TaskMiniCard(report: report)),
        const Divider(),
      ],
    );
  }
}

class _TaskMiniCard extends StatelessWidget {
  final Report report;

  const _TaskMiniCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final difference = now.difference(report.createdAt);
    final daysOpen = difference.inDays;
    final hoursOpen = difference.inHours;

    String openDuration;
    if (daysOpen > 0) {
      openDuration = "$daysOpen day${daysOpen == 1 ? '' : 's'}";
    } else {
      openDuration = "$hoursOpen hour${hoursOpen == 1 ? '' : 's'}";
    }

    return Card(
      margin: const EdgeInsets.only(left: 28.0, bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailManagerScreen(report: report))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("By: ${report.reporterName}", style: textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusSmallChip(status: report.status),
                  const SizedBox(height: 4),
                  Text(
                    "Open for $openDuration",
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.secondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSmallChip extends StatelessWidget {
  final String status;
  const _StatusSmallChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'open': color = Colors.blue; break;
      case 'assigned': color = Colors.purple; break;
      case 'in_progress': color = Colors.orange; break;
      case 'on_hold': color = Colors.orange; break;
      case 'closed': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
