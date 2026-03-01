import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import '../widgets/image_gallery.dart';

class TaskDetailScreen extends StatelessWidget {
  final Report report;

  const TaskDetailScreen({super.key, required this.report});

  void _updateStatus(BuildContext context, String newStatus) async {
    final reportService = Provider.of<ReportService>(context, listen: false);
    try {
      await reportService.updateReport(report.id, {'status': newStatus});
      // Log audit
      if (context.mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final auditService = Provider.of<AuditService>(context, listen: false);
        final currentUser = await authService.getUserProfile(authService.currentUserId!);
        await auditService.logAction(
          reportId: report.id,
          userId: authService.currentUserId!,
          userName: currentUser?.displayName ?? 'Maintainer',
          action: 'status_changed',
          details: 'Status updated to ${newStatus.replaceAll('_', ' ')}',
          organizationId: currentUser?.organizationId ?? report.organizationId,
        );
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status successfully updated to ${newStatus.replaceAll('_', ' ')}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          )
        );
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Report"),
      ),
      body: ResponsiveCenter(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              
              __buildInfoCard(context, "Problem Description", report.description, Icons.description_outlined),
              const SizedBox(height: 16),
              
              __buildInfoCard(context, "Location", report.location, Icons.location_on_outlined),
              const SizedBox(height: 16),
              
              __buildInfoCard(context, "Incident Date", report.reportDateTime.toString().split(' ')[0], Icons.calendar_today_outlined),
              const SizedBox(height: 16),
              
              if (report.managerComments != null && report.managerComments!.isNotEmpty) ...[
                __buildInfoCard(context, "Manager Feedback", report.managerComments!, Icons.feedback_outlined),
                const SizedBox(height: 16),
              ],
              
              if (report.imageUrls.isNotEmpty) ...[
                ImageGallery(imageUrls: report.imageUrls),
                const SizedBox(height: 16),
              ],
              
              _buildContactSection(context),
              
              const SizedBox(height: 48),
              
              _buildActionsSection(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(report.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _StatusBadge(status: report.status),
      ],
    );
  }

  Widget __buildInfoCard(BuildContext context, String title, String content, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primaryContainer.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support_outlined, size: 18, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                "REPORTED BY",
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                child: Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.reporterName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(report.reporterPhone, style: textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {}, // Could implement call functionality
                icon: const Icon(Icons.phone_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    if (report.status == 'closed' || report.status == 'archived') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              "Task Completed",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              "This ticket is closed and waiting for managerial review.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "AVAILABLE ACTIONS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.2,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (report.status == 'assigned')
          FilledButton.icon(
            onPressed: () => _updateStatus(context, 'in_progress'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Start Work"),
          ),
        if (report.status == 'in_progress')
          FilledButton.icon(
            onPressed: () => _updateStatus(context, 'closed'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            icon: const Icon(Icons.check_rounded),
            label: const Text("Mark as Resolved"),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'assigned': color = const Color(0xFF8B5CF6); label = 'TO DO'; break;
      case 'in_progress': color = const Color(0xFFF59E0B); label = 'IN PROGRESS'; break;
      case 'closed': color = const Color(0xFF10B981); label = 'COMPLETED'; break;
      default: color = Colors.grey; label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}
