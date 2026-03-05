import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'report_detail_manager_screen.dart';
import '../widgets/responsive_center.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import 'manage_locations_screen.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import 'maintainer_tasks_screen.dart';
import 'reporter_tasks_screen.dart';
import 'location_tasks_screen.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  String _filterStatus = 'all';
  late Stream<List<Report>> _reportStream;
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
        _updateStream();
      }
    }
  }

  void _updateStream() {
    if (_organizationId == null) return;
    final reportService = Provider.of<ReportService>(context, listen: false);
    setState(() {
      _reportStream = reportService.getReports(
        _organizationId!,
        status: _filterStatus == 'all' ? null : _filterStatus,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    if (_isLoading || _organizationId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authService.impersonatedProfile != null 
                  ? "${l10n.get('impersonating_msg')}: ${authService.impersonatedProfile!.displayName}" 
                  : l10n.get('manager_dashboard'),
              style: textTheme.titleLarge,
            ),
            if (authService.impersonatedProfile == null)
              Text(
                l10n.get('overall_activity'),
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
                 tooltip: l10n.get('stop_impersonating'),
               ),
             ),
          IconButton.filledTonal(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageLocationsScreen())),
            icon: const Icon(Icons.location_on_rounded, size: 20),
            tooltip: l10n.get('manage_locations'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bar_chart_rounded, size: 20, color: colorScheme.onSecondaryContainer),
            ),
            tooltip: l10n.get('task_distribution'),
            onSelected: (value) {
              if (value == 'maintainers') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintainerTasksScreen()));
              } else if (value == 'reporters') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReporterTasksScreen()));
              } else if (value == 'locations') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationTasksScreen()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'maintainers',
                child: Row(
                  children: [
                    Icon(Icons.engineering_rounded, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(l10n.get('by_maintainer')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reporters',
                child: Row(
                  children: [
                    Icon(Icons.person_pin_circle_rounded, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(l10n.get('by_reporter')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'locations',
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(l10n.get('by_location')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => authService.signOut(), 
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: l10n.get('logout'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(l10n.get('all_tasks'), 'all', Icons.dashboard_rounded),
                _buildFilterChip(l10n.get('open'), 'open', Icons.error_outline_rounded),
                _buildFilterChip(l10n.get('assigned'), 'assigned', Icons.assignment_ind_rounded),
                _buildFilterChip(l10n.get('working'), 'in_progress', Icons.construction_rounded),
                _buildFilterChip(l10n.get('on_hold'), 'on_hold', Icons.pause_circle_outline_rounded),
                _buildFilterChip(l10n.get('resolved'), 'closed', Icons.check_circle_outline_rounded),
              ],
            ),
          ),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: StreamBuilder<List<Report>>(
          stream: _reportStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text(l10n.get('failed_load_reports'), style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text("${snapshot.error}", textAlign: TextAlign.center, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reports = snapshot.data ?? [];
            
            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(l10n.get('no_reports_match'), style: textTheme.bodyLarge),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _ManagerReportCard(report: report),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5)),
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (_filterStatus != value) {
            setState(() {
              _filterStatus = value;
              _updateStream();
            });
          }
        },
        showCheckmark: false,
        backgroundColor: Colors.transparent,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _ManagerReportCard extends StatelessWidget {
  final Report report;

  const _ManagerReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailManagerScreen(report: report)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.report_problem_rounded, color: colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: textTheme.titleMedium?.copyWith(height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${l10n.get('loc_prefix')}${report.location}",
                          style: textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusChip(status: report.status),
                      if (report.assignedTo != null && (report.status == 'assigned' || report.status == 'in_progress'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: FutureBuilder<UserProfile?>(
                            future: Provider.of<UserService>(context, listen: false).getUserProfile(report.assignedTo!),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Text(
                                  "${AppLocalizations.of(context).get('assigned')}: ${snapshot.data!.displayName}",
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                    ],
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
        color = const Color(0xFF3B82F6); 
        icon = Icons.error_outline_rounded;
        label = AppLocalizations.of(context).get('open');
        break;
      case 'assigned': 
        color = const Color(0xFF8B5CF6); 
        icon = Icons.assignment_ind_rounded;
        label = AppLocalizations.of(context).get('assigned');
        break;
      case 'in_progress': 
        color = const Color(0xFFF59E0B); 
        icon = Icons.construction_rounded;
        label = AppLocalizations.of(context).get('working');
        break;
      case 'on_hold':
        color = Colors.orange;
        icon = Icons.pause_circle_outline_rounded;
        label = AppLocalizations.of(context).get('on_hold');
        break;
      case 'closed': 
        color = const Color(0xFF10B981); 
        icon = Icons.check_circle_outline_rounded;
        label = AppLocalizations.of(context).get('resolved');
        break;
      case 'archived': 
        color = const Color(0xFF64748B); 
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
