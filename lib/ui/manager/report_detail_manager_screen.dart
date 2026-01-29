import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../models/user_profile.dart';
import '../../services/report_service.dart';
import '../../services/user_service.dart';

class ReportDetailManagerScreen extends StatefulWidget {
  final Report report;

  const ReportDetailManagerScreen({super.key, required this.report});

  @override
  State<ReportDetailManagerScreen> createState() => _ReportDetailManagerScreenState();
}

class _ReportDetailManagerScreenState extends State<ReportDetailManagerScreen> {
  UserProfile? _selectedMaintainer;
  bool _isLoading = false;

  void _assignMaintainer() async {
    if (_selectedMaintainer == null) return;
    setState(() => _isLoading = true);
    
    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.updateReport(widget.report.id, {
        'assignedTo': _selectedMaintainer!.uid,
        'status': 'assigned',
      });
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Assigned to ${_selectedMaintainer!.displayName}")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
      });
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Archived")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Report")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.report.title, style: Theme.of(context).textTheme.headlineMedium),
            Text("Status: ${widget.report.status.toUpperCase()}"),
             const SizedBox(height: 16),
            Text(widget.report.description),
            const Divider(height: 32),
            
            // Assignment Section
            if (widget.report.status == 'open') ...[
              Text("Assign to Maintainer", style: Theme.of(context).textTheme.titleMedium),
               StreamBuilder<List<UserProfile>>(
                 stream: Provider.of<UserService>(context, listen: false).getMaintainers(),
                 builder: (context, snapshot) {
                   if (!snapshot.hasData) return const CircularProgressIndicator();
                   final maintainers = snapshot.data!;
                   
                   return DropdownButtonFormField<UserProfile>(
                     items: maintainers.map((user) => DropdownMenuItem(
                       value: user,
                       child: Text(user.displayName),
                     )).toList(),
                     onChanged: (val) => setState(() => _selectedMaintainer = val),
                     decoration: const InputDecoration(labelText: "Select Maintainer"),
                   );
                 },
               ),
               const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 child: FilledButton(
                   onPressed: (_selectedMaintainer != null && !_isLoading) ? _assignMaintainer : null,
                   child: const Text("Assign"),
                 ),
               )
            ],

            // Archiving Section
            if (widget.report.status == 'closed') ...[
               Text("Action Required", style: Theme.of(context).textTheme.titleMedium),
               const SizedBox(height: 8),
               Container(
                 padding: const EdgeInsets.all(8),
                 color: Colors.green.shade100,
                 child: const Text("Maintainer has marked this issue as closed. Please review and archive."),
               ),
               const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 child: FilledButton(
                   onPressed: _isLoading ? null : _archiveReport,
                   child: const Text("Archive Report"),
                 ),
               )
            ],
            
            if (widget.report.status == 'assigned' || widget.report.status == 'in_progress')
              const Text("Work in progress by maintainer."),
              
            if (widget.report.status == 'archived')
              const Text("This report is archived."),
          ],
        ),
      ),
    );
  }
}
