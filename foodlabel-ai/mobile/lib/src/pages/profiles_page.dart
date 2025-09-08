// foodlabel-ai/mobile/lib/src/pages/profiles_page.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});
  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  bool _loading = false;
  String? _error;
  List<Profile> _profiles = const [];

  @override
  void initState() {
    super.initState();
    // Kick off initial load after first frame to avoid build-time setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = _profiles.isEmpty; // show spinner if first load
      _error = null;
    });
    try {
      final profiles = await ProfileService.list();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      // Optional: surface via SnackBar as well.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profiles: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _goCreate() async {
    final created = await Navigator.pushNamed(context, '/profile_edit');
    if (created == true) {
      await _refresh();
    }
  }

  Future<void> _edit(Profile p) async {
    final updated = await Navigator.pushNamed(
      context,
      '/profile_edit',
      arguments: p,
    );
    if (updated == true) {
      await _refresh();
    }
  }

  Future<void> _confirmDelete(Profile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('This will delete ${p.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ProfileService.delete(p.id);
        await _refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_loading && _profiles.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _profiles.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_profiles.isEmpty) {
      body = const Center(
        child: Text('No profiles yet. Tap + to create.'),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _profiles.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = _profiles[i];
            final subtitleParts = <String>[];
            if (p.gender != null) subtitleParts.add('Gender: ${p.gender}');
            if (p.dob != null) subtitleParts.add('DOB: ${p.dob}');
            if (p.state != null) subtitleParts.add('State: ${p.state}');
            if (p.country != null) subtitleParts.add('Country: ${p.country}');
            if (p.allergens.isNotEmpty) {
              subtitleParts.add('Allergens: ${p.allergens.join(", ")}');
            }
            return ListTile(
              title: Text(p.name),
              subtitle: subtitleParts.isEmpty
                  ? null
                  : Text(subtitleParts.join(' • ')),
              onTap: () => _edit(p),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(p),
              ),
            );
          },
        ),
      );
    }

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
        bottom: _loading && _profiles.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
      body: body,
    );
  }
}
