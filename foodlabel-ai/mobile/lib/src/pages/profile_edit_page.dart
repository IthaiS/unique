import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/profile.dart' as models;

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _name = TextEditingController();
  final _dob = TextEditingController(); // YYYY-MM-DD
  final _gender = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();

  final Set<String> _selected = <String>{};
  List<String> _allowlist = <String>[];
  bool _loading = true;
  String? _error;
  int? _editingId;
  bool _hydratedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _fetchAllowlist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hydrate once from route args (if provided)
    if (_hydratedFromArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    final models.Profile? editing =
        (args is models.Profile) ? args : null; // <- use aliased model
    if (editing != null) {
      _editingId = editing.id;
      _name.text = editing.name;
      _dob.text = editing.dob ?? '';
      _gender.text = editing.gender ?? '';
      _state.text = editing.state ?? '';
      _country.text = editing.country ?? '';
      _selected
        ..clear()
        ..addAll(editing.allergens);
    }
    _hydratedFromArgs = true;
  }

  Future<void> _fetchAllowlist() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ProfileService.allowedAllergens();
      setState(() {
        _allowlist = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_editingId == null) {
        await ProfileService.create(
          name: _name.text.trim(),
          dob: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
          gender: _gender.text.trim().isEmpty ? null : _gender.text.trim(),
          state: _state.text.trim().isEmpty ? null : _state.text.trim(),
          country: _country.text.trim().isEmpty ? null : _country.text.trim(),
          allergens: _selected.toList(),
        );
      } else {
        await ProfileService.update(
          id: _editingId!,
          name: _name.text.trim(),
          dob: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
          gender: _gender.text.trim().isEmpty ? null : _gender.text.trim(),
          state: _state.text.trim().isEmpty ? null : _state.text.trim(),
          country: _country.text.trim().isEmpty ? null : _country.text.trim(),
          allergens: _selected.toList(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _gender.dispose();
    _state.dispose();
    _country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingId == null ? 'New profile' : 'Edit profile'),
      ),
      body: _loading && _allowlist.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  spacing,
                  TextField(
                    controller: _dob,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth (YYYY-MM-DD)',
                    ),
                  ),
                  spacing,
                  TextField(
                    controller: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                  ),
                  spacing,
                  TextField(
                    controller: _state,
                    decoration: const InputDecoration(
                      labelText: 'State/Province',
                    ),
                  ),
                  spacing,
                  TextField(
                    controller: _country,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                  spacing,
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Allergens (from policy)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allowlist.map((a) {
                      final sel = _selected.contains(a);
                      return FilterChip(
                        label: Text(a),
                        selected: sel,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selected.add(a);
                            } else {
                              _selected.remove(a);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_error != null) ...[
                    spacing,
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  spacing,
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _loading ? null : _save,
                          child: Text(
                            _editingId == null
                                ? 'Create profile'
                                : 'Save changes',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
