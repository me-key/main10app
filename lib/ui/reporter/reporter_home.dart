import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../widgets/responsive_center.dart';
import '../widgets/theme_toggle_button.dart';
import 'create_report_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class ReporterHome extends StatefulWidget {
  const ReporterHome({super.key});

  @override
  State<ReporterHome> createState() => _ReporterHomeState();
}

class _ReporterHomeState extends State<ReporterHome> {
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
    final reportService = Provider.of<ReportService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (user == null) return const Center(child: Text("Not Authenticated"));
    if (_isLoading || _organizationId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authService.impersonatedProfile != null 
                  ? "Impersonating: ${authService.impersonatedProfile!.displayName}" 
                  : l10n.get('my_dashboard'),
              style: textTheme.titleLarge,
            ),
            if (authService.impersonatedProfile == null)
              Text(
                l10n.get('overview_reports'),
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            onPressed: () => localeProvider.toggleLocale(),
            icon: Text(localeProvider.locale.languageCode == 'en' ? 'HE' : 'EN', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            tooltip: localeProvider.locale.languageCode == 'en' ? 'עברית' : 'English',
          ),
          const SizedBox(width: 8),
          if (authService.impersonatedProfile != null)
             Padding(
               padding: const EdgeInsets.only(right: 8.0),
               child: IconButton.filledTonal(
                 onPressed: () => authService.stopImpersonating(),
                 icon: const Icon(Icons.stop_screen_share_rounded, size: 20),
                 tooltip: "Stop Impersonating",
               ),
             ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => authService.signOut(), 
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: l10n.get('logout'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: StreamBuilder<List<Report>>(
          stream: reportService.getReportsForReporter(user.uid, _organizationId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final reports = snapshot.data ?? [];
            
            if (reports.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.note_add_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.get('no_reports_yet'),
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.get('no_reports_msg'),
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReportScreen())),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.get('create_first_report')),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _ReportCard(report: report),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReportScreen()));
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.get('new_report')),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Navigate to details if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.location,
                                style: textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildInfoItem(
                        context,
                        Icons.calendar_today_rounded,
                        report.reportDateTime.toString().split(' ')[0],
                      ),
                      const SizedBox(width: 16),
                      if (report.assignedTo != null)
                        _buildInfoItem(
                          context,
                          Icons.person_pin_rounded,
                          AppLocalizations.of(context).get('assigned'),
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color ?? colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: color != null ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'open': 
        color = const Color(0xFF3B82F6); // Blue
        icon = Icons.error_outline_rounded;
        label = AppLocalizations.of(context).get('open');
        break;
      case 'assigned': 
        color = const Color(0xFF8B5CF6); // Purple
        icon = Icons.assignment_ind_rounded;
        label = AppLocalizations.of(context).get('assigned');
        break;
      case 'in_progress': 
        color = const Color(0xFFF59E0B); // Amber
        icon = Icons.construction_rounded;
        label = AppLocalizations.of(context).get('working');
        break;
      case 'closed': 
        color = const Color(0xFF10B981); // Emerald
        icon = Icons.check_circle_outline_rounded;
        label = AppLocalizations.of(context).get('resolved');
        break;
      case 'archived': 
        color = const Color(0xFF64748B); // Slate
        icon = Icons.archive_outlined;
        label = AppLocalizations.of(context).get('archived');
        break;
      default: 
        color = Colors.grey; 
        icon = Icons.help_outline_rounded;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
