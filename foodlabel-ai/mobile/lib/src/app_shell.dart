
import 'dart:async';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/profiles_page.dart';
import 'services/auth_service.dart';
import 'services/account_service.dart';

void _noopLocaleChange(Locale _) {}


// Minimal shell used by tests and app; routes (e.g., '/owner/profile') are pushed by name.
// The actual target pages are provided by MaterialApp.routes in tests/app.

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.isOwner = true,
    this.onLocaleChange = _noopLocaleChange,
    this.translations = const {},
  });

  final bool isOwner;
  final void Function(Locale) onLocaleChange;
  final Map<String, dynamic> translations;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _setIndex(int i) => setState(() => _index = i);

  // --- Owner menu ---
  void _openOwnerMenu() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _OwnerMenuSheet(
        onNavigate: (route) =>
            Navigator.of(context, rootNavigator: true).pushNamed(route),
        onLogout: _logout,
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (r) => false);
      }
      // Cleanup deferred; replace with actual services if needed.
      Future.microtask(() async {
        // await AccountService.clearLocalCache();
        // await AuthService.logout();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
      final pages = <Widget>[
        HomePage(onLocaleChange: widget.onLocaleChange, translations: widget.translations),
        const ProfilesPage(),
      ];

      final content = IndexedStack(index: _index, children: pages);

      if (wide) {
        return Scaffold(
          body: Row(
            children: [
              _Rail(
                index: _index,
                onTap: _setIndex,
                isOwner: widget.isOwner,
                onOwnerTap: _openOwnerMenu,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('FoodLabel AI'),
          actions: [
            if (widget.isOwner)
              IconButton(
                tooltip: 'Owner menu',
                icon: const Icon(Icons.admin_panel_settings_outlined),
                onPressed: _openOwnerMenu,
              ),
          ],
        ),
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _setIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.center_focus_strong_outlined),
              selectedIcon: Icon(Icons.center_focus_strong),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Profiles',
            ),
          ],
        ),
      );
    }
  }
  class _Rail extends StatelessWidget {
  const _Rail({
    required this.index,
    required this.onTap,
    this.isOwner = true,
    required this.onOwnerTap,
  });
  final int index;
  final ValueChanged<int> onTap;
  final bool isOwner;
  final VoidCallback onOwnerTap;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
            icon: Icon(Icons.center_focus_strong_outlined),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: Text('Scan')),
        NavigationRailDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Profiles')),
      ],
      trailing: isOwner
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Owner menu',
                    icon:
                        const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: onOwnerTap,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _OwnerMenuSheet extends StatelessWidget {
  const _OwnerMenuSheet({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  final void Function(String route) onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_outline, 'Owner profile', '/owner/profile',
          'Name, email & region'),
      (Icons.settings_suggest_outlined, 'Owner settings', '/owner/settings',
          'OCR thresholds, model options, privacy'),
      (Icons.analytics_outlined, 'Analytics', null,
          'Scans, risk trends, usage'),
      (Icons.rule_folder_outlined, 'Moderation', null,
          'Flagged labels & feedback'),
      (Icons.cloud_outlined, 'Backend health', null,
          'API status & latency'),
      (Icons.logout, 'Log out', 'LOGOUT',
          'Sign out and clear this device'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const ListTile(
            title: Text('Owner Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const Divider(),
          ...items.map((it) => ListTile(
                leading: Icon(it.$1),
                title: Text(it.$2),
                subtitle: Text(it.$4),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  final route = it.$3;
                  if (route == 'LOGOUT') {
                    Future.microtask(onLogout);
                  } else if (route != null) {
                    Future.microtask(() => onNavigate(route));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${it.$2} coming soon')),
                    );
                  }
                },
              )),
        ],
      ),
    );
  }
}
