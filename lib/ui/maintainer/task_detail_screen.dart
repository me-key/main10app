import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';

class TaskDetailScreen extends StatelessWidget {
  final Report report;

  const TaskDetailScreen({super.key, required this.report});

  void _updateStatus(BuildContext context, String newStatus) async {
    final reportService = Provider.of<ReportService>(context, listen: false);
    try {
      await reportService.updateReport(report.id, {'status': newStatus});
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Chip(label: Text(report.status.toUpperCase())),
            const SizedBox(height: 16),
            Text("Description:", style: Theme.of(context).textTheme.titleMedium),
            Text(report.description),
            const SizedBox(height: 16),
            Text("Location: ${report.location}"),
            const SizedBox(height: 8),
            Text("Contact: ${report.reporterName} (${report.reporterPhone})"),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text("Actions:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (report.status == 'assigned')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _updateStatus(context, 'in_progress'),
                  child: const Text("Start Work (Mark In Progress)"),
                ),
              ),
             if (report.status == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _updateStatus(context, 'closed'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Mark Fixed (Close Ticket)"),
                ),
              ),
              if (report.status == 'closed')
                 const Center(child: Text("Task Completed. Waiting for Manager Archival.")),
          ],
        ),
      ),
    );
  }
}
