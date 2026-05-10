import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../reporter/reporter_home.dart';
import '../maintainer/maintainer_home.dart';
import '../manager/manager_home.dart';

class TesterHome extends StatefulWidget {
  const TesterHome({super.key});

  @override
  State<TesterHome> createState() => _TesterHomeState();
}

class _TesterHomeState extends State<TesterHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ReporterHome(),
    const ManagerHome(),
    const MaintainerHome(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_pin_circle_rounded),
              label: l10n.get('reporters'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.engineering_rounded),
              label: l10n.get('managers'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.manage_accounts_rounded),
              label: l10n.get('maintainers'),
            ),
          ],
        ),
      ),
    );
  }
}
