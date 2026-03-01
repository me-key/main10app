import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../models/user_profile.dart';
import '../../services/report_service.dart';
import '../../services/user_service.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import '../widgets/image_gallery.dart';
import '../widgets/audit_trail_widget.dart';

class ReportDetailManagerScreen extends StatefulWidget {
  final Report report;

  const ReportDetailManagerScreen({super.key, required this.report});

  @override
  State<ReportDetailManagerScreen> createState() => _ReportDetailManagerScreenState();
}

class _ReportDetailManagerScreenState extends State<ReportDetailManagerScreen> {
  UserProfile? _selectedMaintainer;
  bool _isLoading = false;
  late TextEditingController _commentsController;
  String? _organizationId;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController(text: widget.report.managerComments);
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
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  void _assignMaintainer() async {
    if (_selectedMaintainer == null) return;
    setState(() => _isLoading = true);
    
    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.updateReport(widget.report.id, {
        'assignedTo': _selectedMaintainer!.uid,
        'status': 'assigned',
      });
      // Log audit
      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final auditService = Provider.of<AuditService>(context, listen: false);
        final currentUser = await authService.getUserProfile(authService.currentUserId!);
        await auditService.logAction(
          reportId: widget.report.id,
          userId: authService.currentUserId!,
          userName: currentUser?.displayName ?? 'Manager',
          action: 'assigned',
          details: 'Assigned to ${_selectedMaintainer!.displayName}',
          organizationId: currentUser?.organizationId ?? widget.report.organizationId,
        );
      }
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("Successfully assigned to ${_selectedMaintainer!.displayName}"),
             behavior: SnackBarBehavior.floating,
             backgroundColor: Theme.of(context).colorScheme.primary,
           )
         );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _archiveReport() async {
    setState(() => _isLoading = true);
    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.updateReport(widget.report.id, {
        'status': 'archived',
        'managerComments': _commentsController.text,
      });
      // Log audit
      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final auditService = Provider.of<AuditService>(context, listen: false);
        final currentUser = await authService.getUserProfile(authService.currentUserId!);
        await auditService.logAction(
          reportId: widget.report.id,
          userId: authService.currentUserId!,
          userName: currentUser?.displayName ?? 'Manager',
          action: 'archived',
          details: 'Report archived with comments: ${_commentsController.text}',
          organizationId: currentUser?.organizationId ?? widget.report.organizationId,
        );
      }
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text("Report successfully archived"),
             behavior: SnackBarBehavior.floating,
           )
         );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reassignReport() async {
    setState(() => _isLoading = true);
    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.updateReport(widget.report.id, {
        'status': 'assigned',
        'managerComments': _commentsController.text,
      });
      // Log audit
      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final auditService = Provider.of<AuditService>(context, listen: false);
        final currentUser = await authService.getUserProfile(authService.currentUserId!);
        await auditService.logAction(
          reportId: widget.report.id,
          userId: authService.currentUserId!,
          userName: currentUser?.displayName ?? 'Manager',
          action: 'reassigned',
          details: 'Report reassigned with comments: ${_commentsController.text}',
          organizationId: currentUser?.organizationId ?? widget.report.organizationId,
        );
      }
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text("Report reassigned for further work"),
             behavior: SnackBarBehavior.floating,
             backgroundColor: Colors.orange,
           )
         );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile || _organizationId == null) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Report")),
      body: ResponsiveCenter(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              
              _buildInfoSection(context, "Problem Details", [
                _buildInfoItem(context, "Title", widget.report.title),
                const SizedBox(height: 16),
                _buildInfoItem(context, "Description", widget.report.description),
                const SizedBox(height: 16),
                _buildInfoItem(context, "Location", widget.report.location),
                const SizedBox(height: 16),
                _buildInfoItem(context, "Incident Date", widget.report.reportDateTime.toString().split(' ')[0]),
                if (widget.report.status == 'on_hold' && widget.report.onHoldReason != null) ...[
                   const SizedBox(height: 16),
                   _buildInfoItem(context, "Hold Reason", widget.report.onHoldReason!, isWarning: true),
                ],
                if (widget.report.managerComments != null && widget.report.managerComments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(context, "Manager Feedback", widget.report.managerComments!),
                ],
                ImageGallery(imageUrls: widget.report.imageUrls),
              ]),
              
              const SizedBox(height: 24),
              
              _buildInfoSection(context, "Reporter Details", [
                _buildInfoItem(context, "Name", widget.report.reporterName),
                const SizedBox(height: 16),
                _buildInfoItem(context, "Contact", widget.report.reporterPhone),
              ]),
              
              const SizedBox(height: 48),
              
              _buildManagementActions(context),
              const SizedBox(height: 48),
              AuditTrailWidget(reportId: widget.report.id),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("REPORT CASE", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text("#${widget.report.id.substring(0, 8).toUpperCase()}", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            _StatusBadge(status: widget.report.status),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
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
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, {bool isWarning = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isWarning ? Colors.orange : const Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: textTheme.bodyLarge?.copyWith(color: isWarning ? Colors.orange : null)),
      ],
    );
  }

  Widget _buildManagementActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.report.status == 'open') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primaryContainer.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Assign Maintainer", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Select a team member to handle this ticket.", style: textTheme.bodySmall),
            const SizedBox(height: 24),
            StreamBuilder<List<UserProfile>>(
              stream: Provider.of<UserService>(context, listen: false).getMaintainers(_organizationId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final maintainers = snapshot.data!;
                
                return DropdownButtonFormField<UserProfile>(
                  value: _selectedMaintainer,
                  items: maintainers.map((user) => DropdownMenuItem(
                    value: user,
                    child: Text(user.displayName),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedMaintainer = val),
                  decoration: const InputDecoration(
                    labelText: "Select Staff",
                    prefixIcon: Icon(Icons.person_pin_rounded),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: (_selectedMaintainer != null && !_isLoading) ? _assignMaintainer : null,
              icon: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.assignment_turned_in_rounded),
              label: const Text("Assign Now"),
            )
          ],
        ),
      );
    }

    if (widget.report.status == 'closed') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.green),
                SizedBox(width: 12),
                Text("Resolution Pending", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "The maintainer has completed the work. Please verify the fix and archive the ticket to complete the process.",
              style: TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Feedback/Comments",
                hintText: "Add notes about the resolution or reasons for reassignment...",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _reassignReport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text("Reassign"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _archiveReport,
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    icon: const Icon(Icons.archive_rounded),
                    label: const Text("Archive & Close"),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    return Center(
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            widget.report.status == 'archived' ? "This report is archived." : "Maintainer is currently working on this.",
            style: textTheme.bodySmall,
          ),
        ],
      ),
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
      case 'open': color = const Color(0xFF3B82F6); label = 'OPEN'; break;
      case 'assigned': color = const Color(0xFF8B5CF6); label = 'ASSIGNED'; break;
      case 'in_progress': color = const Color(0xFFF59E0B); label = 'WORKING'; break;
      case 'on_hold': color = Colors.orange; label = 'ON HOLD'; break;
      case 'closed': color = const Color(0xFF10B981); label = 'RESOLVED'; break;
      case 'archived': color = const Color(0xFF64748B); label = 'ARCHIVED'; break;
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
