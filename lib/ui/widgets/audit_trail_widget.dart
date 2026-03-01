import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/audit_log.dart';
import '../../services/audit_service.dart';
import 'package:intl/intl.dart';

class AuditTrailWidget extends StatelessWidget {
  final String reportId;

  const AuditTrailWidget({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final auditService = Provider.of<AuditService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AUDIT TRAIL",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.2,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<AuditLog>>(
          stream: auditService.getAuditLogs(reportId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text("Error loading audit logs: ${snapshot.error}");
            }
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return const Text("No audit logs available for this report.");
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _AuditLogItem(log: log);
              },
            );
          },
        ),
      ],
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  final AuditLog log;

  const _AuditLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData icon;
    Color color;
    switch (log.action) {
      case 'created':
        icon = Icons.add_circle_outline_rounded;
        color = Colors.blue;
        break;
      case 'assigned':
        icon = Icons.person_add_alt_1_rounded;
        color = Colors.purple;
        break;
      case 'status_changed':
        icon = Icons.update_rounded;
        color = Colors.orange;
        break;
      case 'reassigned':
        icon = Icons.replay_rounded;
        color = Colors.orange;
        break;
      case 'archived':
        icon = Icons.archive_rounded;
        color = Colors.grey;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = colorScheme.primary;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    log.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    DateFormat('MMM d, HH:mm').format(log.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                log.details,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
