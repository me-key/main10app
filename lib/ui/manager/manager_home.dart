import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'report_detail_manager_screen.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  String _filterStatus = 'all'; // 'all', 'open', 'closed', 'archived'
  Stream<List<Report>>? _reportStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  void _updateStream() {
    final reportService = Provider.of<ReportService>(context, listen: false);
    setState(() {
      _reportStream = reportService.getReports(status: _filterStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<ReportService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        actions: [
          const ThemeToggleButton(),
          IconButton(onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(), icon: const Icon(Icons.logout))
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Open', 'open'),
                _buildFilterChip('Closed', 'closed'),
                _buildFilterChip('Archived', 'archived'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Report>>(
        stream: _reportStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final filteredReports = snapshot.data ?? [];
          
          if (filteredReports.isEmpty) {
            return const Center(child: Text("No reports found."));
          }

          return ListView.builder(
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              final report = filteredReports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 child: ListTile(
                   title: Text(report.title),
                   subtitle: Text("Status: ${report.status.toUpperCase()}"),
                   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                   onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailManagerScreen(report: report)));
                   },
                 ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _filterStatus == value,
        onSelected: (selected) {
          if (_filterStatus != value) {
            _filterStatus = value;
            _updateStream();
          }
        },
      ),
    );
  }
}
