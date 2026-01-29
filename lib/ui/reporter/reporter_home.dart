import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../widgets/responsive_center.dart';
import '../widgets/theme_toggle_button.dart';
import 'create_report_screen.dart';

class ReporterHome extends StatelessWidget {
  const ReporterHome({super.key});

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<ReportService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) return const Center(child: Text("Not Authenticated"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports"),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(), 
            icon: const Icon(Icons.logout)
          )
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: StreamBuilder<List<Report>>(
          stream: reportService.getReportsForReporter(user.uid),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      "No reports yet",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap the + button to create a new report",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: reports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  elevation: 0, // Using subtle border instead of elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Navigate to details if needed
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  report.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildStatusChip(context, report.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                "Created on ${report.createdAt.toString().split(' ')[0]}", // Display just date
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
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
        label: const Text("New Report"),
      ),
    );
  }
  
  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'open': 
        color = Colors.blue; 
        icon = Icons.new_releases;
        label = 'Open';
        break;
      case 'assigned': 
        color = Colors.orange; 
        icon = Icons.assignment_ind;
        label = 'Assigned';
        break;
      case 'in_progress': 
        color = Colors.amber.shade700; 
        icon = Icons.construction;
        label = 'In Progress';
        break;
      case 'closed': 
        color = Colors.green; 
        icon = Icons.check_circle;
        label = 'Closed';
        break;
      case 'archived': 
        color = Colors.grey; 
        icon = Icons.archive;
        label = 'Archived';
        break;
      default: 
        color = Colors.grey; 
        icon = Icons.help;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
