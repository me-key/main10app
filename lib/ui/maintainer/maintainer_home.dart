import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'task_detail_screen.dart';
import '../widgets/responsive_center.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class MaintainerHome extends StatefulWidget {
  const MaintainerHome({super.key});

  @override
  State<MaintainerHome> createState() => _MaintainerHomeState();
}

class _MaintainerHomeState extends State<MaintainerHome> {
  String? _organizationId;
  String _filterStatus = 'all';
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
                  ? "${l10n.get('impersonating_msg')}: ${authService.impersonatedProfile!.displayName}" 
                  : l10n.get('my_tasks'),
              style: textTheme.titleLarge,
            ),
            if (authService.impersonatedProfile == null)
              Text(
                l10n.get('assigned_work'),
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
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => authService.signOut(), 
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: l10n.get('logout'),
          ),
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
                _buildFilterChip(l10n.get('to_do'), 'assigned', Icons.assignment_ind_rounded),
                _buildFilterChip(l10n.get('in_progress'), 'in_progress', Icons.construction_rounded),
                _buildFilterChip(l10n.get('on_hold'), 'on_hold', Icons.pause_circle_outline_rounded),
                _buildFilterChip(l10n.get('completed'), 'closed', Icons.check_circle_outline_rounded),
              ],
            ),
          ),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: StreamBuilder<List<Report>>(
          stream: reportService.getReportsForMaintainer(user.uid, _organizationId!, status: _filterStatus),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("${l10n.get('error_loading_reports')}: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                        child: Icon(Icons.task_alt_rounded, size: 64, color: colorScheme.secondary.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.get('all_caught_up'),
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.get('no_tasks_msg'),
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _TaskCard(report: report),
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

class _TaskCard extends StatelessWidget {
  final Report report;

  const _TaskCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(report: report)));
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
                        const SizedBox(height: 8),
                        _StatusChip(status: report.status),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildIconInfo(context, Icons.location_on_rounded, report.location),
                  const SizedBox(width: 24),
                  _buildIconInfo(context, Icons.access_time_rounded, "${AppLocalizations.of(context).get('incident_date')} ${report.reportDateTime.toString().split(' ')[0]}"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconInfo(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
      case 'assigned': 
        color = const Color(0xFF8B5CF6); // Purple
        icon = Icons.assignment_ind_rounded;
        label = AppLocalizations.of(context).get('to_do');
        break;
      case 'in_progress': 
        color = const Color(0xFFF59E0B); // Amber
        icon = Icons.construction_rounded;
        label = AppLocalizations.of(context).get('in_progress');
        break;
      case 'on_hold':
        color = Colors.orange;
        icon = Icons.pause_circle_outline_rounded;
        label = AppLocalizations.of(context).get('on_hold');
        break;
      case 'closed': 
        color = const Color(0xFF10B981); // Emerald
        icon = Icons.check_circle_outline_rounded;
        label = AppLocalizations.of(context).get('completed');
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
