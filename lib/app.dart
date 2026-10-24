import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/members_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/renewals_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indian Fitness Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MembersScreen(),
    PlansScreen(),
    PaymentsScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Members',
    'Plans',
    'Payments',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: _currentIndex == 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Indian Fitness Gym',
                    style: AppTheme.headlineMd.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
                _titles[_currentIndex],
                style: AppTheme.headlineLg.copyWith(
                  color: AppTheme.onSurface,
                ),
              ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.outlineVariant,
            height: 1,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 3,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.primaryContainer,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Payments',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.surfaceContainerLowest,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gym Admin',
                          style: AppTheme.headlineMd.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Indian Fitness Gym',
                          style: AppTheme.labelSm.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Primary nav items
              _DrawerItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: _currentIndex == 0,
                onTap: () {
                  setState(() => _currentIndex = 0);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.group,
                label: 'Members',
                isSelected: _currentIndex == 1,
                onTap: () {
                  setState(() => _currentIndex = 1);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.event_note,
                label: 'Plans',
                isSelected: _currentIndex == 2,
                onTap: () {
                  setState(() => _currentIndex = 2);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.payments,
                label: 'Payments',
                isSelected: _currentIndex == 3,
                onTap: () {
                  setState(() => _currentIndex = 3);
                  Navigator.pop(context);
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(color: AppTheme.outlineVariant),
              ),

              // Secondary nav items
              _DrawerItem(
                icon: Icons.autorenew,
                label: 'Renewals',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Scaffold(
                      body: RenewalsScreen(),
                    )),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.bar_chart,
                label: 'Reports',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Scaffold(
                      body: ReportsScreen(),
                    )),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              const Spacer(),

              // App version
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'v1.0.0',
                  style: AppTheme.labelSm.copyWith(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppTheme.primaryContainer.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: isSelected
                  ? const Border(
                      left: BorderSide(color: AppTheme.primary, width: 4),
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTheme.bodyMd.copyWith(
                    color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
