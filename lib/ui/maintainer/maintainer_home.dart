import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'task_detail_screen.dart';

class MaintainerHome extends StatelessWidget {
  const MaintainerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<ReportService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("👤 MaintainerHome building for UID: ${user?.uid}");
    
    if (user == null) return const Center(child: Text("Not Authenticated"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        actions: [
          const ThemeToggleButton(),
          IconButton(onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(), icon: const Icon(Icons.logout))
        ],
      ),
      body: StreamBuilder<List<Report>>(
        stream: reportService.getReportsForMaintainer(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data ?? [];
          
          if (reports.isEmpty) {
            return const Center(child: Text("No assigned tasks."));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 child: ListTile(
                   title: Text(report.title),
                   subtitle: Text("Status: ${report.status.toUpperCase()}\nLoc: ${report.location}"),
                   isThreeLine: true,
                   onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(report: report)));
                   },
                 ),
              );
            },
          );
        },
      ),
    );
  }
}
