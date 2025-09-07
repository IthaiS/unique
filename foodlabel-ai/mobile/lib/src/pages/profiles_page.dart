import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});
  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  Future<List<Profile>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileService.list();
  }

  Future<void> _refresh() async {
    setState(() => _future = ProfileService.list());
    await _future;
  }

  void _goCreate() async {
    final created = await Navigator.pushNamed(context, '/profile_edit');
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          IconButton(
            onPressed: _goCreate,
            icon: const Icon(Icons.add),
            tooltip: 'Add profile',
          ),
        ],
      ),
      body: FutureBuilder<List<Profile>>(
        future: _future,
        builder: (c, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data ?? const [];
          if (data.isEmpty) {
            return const Center(
                child: Text('No profiles yet. Tap + to create.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = data[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text([
                    if (p.gender != null) 'Gender: ${p.gender}',
                    if (p.dob != null) 'DOB: ${p.dob}',
                    if (p.state != null) 'State: ${p.state}',
                    if (p.country != null) 'Country: ${p.country}',
                    if (p.allergens.isNotEmpty)
                      'Allergens: ${p.allergens.join(", ")}',
                  ].where((e) => e.isNotEmpty).join(' • ')),
                  onTap: () async {
                    final updated = await Navigator.pushNamed(
                      context,
                      '/profile_edit',
                      arguments: p,
                    );
                    if (updated == true) _refresh();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete profile?'),
                          content: Text('This will delete ${p.name}.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ProfileService.delete(p.id);
                        _refresh();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
