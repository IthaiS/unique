import 'package:flutter/material.dart';
import '../services/account_service.dart';

class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key});
  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  final _email = TextEditingController();
  final _ownerName = TextEditingController();
  final _stateProv = TextEditingController();
  final _country = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final me = await AccountService.me();
      if (!mounted) return;
      setState(() {
        _email.text = me.email;
        _ownerName.text = me.ownerName ?? "";
        _stateProv.text = me.state ?? "";
        _country.text = me.country ?? "";
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AccountService.update(
        ownerName: _ownerName.text.trim().isEmpty ? null : _ownerName.text.trim(),
        state: _stateProv.text.trim().isEmpty ? null : _stateProv.text.trim(),
        country: _country.text.trim().isEmpty ? null : _country.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner profile saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ownerName,
                  decoration: const InputDecoration(labelText: 'Owner name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _stateProv,
                  decoration: const InputDecoration(labelText: 'State/Province'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _country,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                const SizedBox(height: 20),
                _saving
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save changes'),
                      ),
              ],
            ),
    );
  }
}
