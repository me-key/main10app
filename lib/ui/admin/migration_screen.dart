import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import '../../scripts/migrate_to_multitenancy.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isRunning = false;
  String _status = '';
  bool _completed = false;
  bool _hasError = false;

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Starting migration...';
      _completed = false;
      _hasError = false;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Redirect print statements to status
      await migrateToMultiTenancy(firestore);
      
      setState(() {
        _isRunning = false;
        _completed = true;
        _status = 'Migration completed successfully! ✅\n\nAll existing data has been assigned to the "test" organization.';
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _hasError = true;
        _status = 'Migration failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration'),
        actions: [
          IconButton(
            onPressed: () => authService.signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'IMPORTANT',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This migration should only be run ONCE after deploying the multi-tenancy code changes.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'It will:',
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Create a "test" organization\n'
                      '• Assign all existing users to this organization\n'
                      '• Assign all existing reports to this organization\n'
                      '• Assign all existing locations to this organization\n'
                      '• Assign all existing audit logs to this organization',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status Display
              if (_status.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _hasError 
                        ? Colors.red.withValues(alpha: 0.1)
                        : _completed
                            ? Colors.green.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hasError
                          ? Colors.red.withValues(alpha: 0.3)
                          : _completed
                              ? Colors.green.withValues(alpha: 0.3)
                              : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isRunning)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_completed)
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                          else if (_hasError)
                            const Icon(Icons.error_rounded, color: Colors.red, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _isRunning ? 'Running...' : _completed ? 'Complete' : 'Error',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _hasError ? Colors.red : _completed ? Colors.green : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_status, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Run Button
              FilledButton.icon(
                onPressed: _isRunning || _completed ? null : _runMigration,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                ),
                icon: _isRunning 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_completed ? 'Migration Already Completed' : 'Run Migration'),
              ),
              
              if (_completed) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Admin'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
