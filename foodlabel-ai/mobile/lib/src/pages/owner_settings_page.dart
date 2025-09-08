import 'package:flutter/material.dart';

class OwnerSettingsPage extends StatefulWidget {
  const OwnerSettingsPage({super.key});

  @override
  State<OwnerSettingsPage> createState() => _OwnerSettingsPageState();
}

class _OwnerSettingsPageState extends State<OwnerSettingsPage> {
  bool _enableAdvancedOCR = true;
  double _ocrConfidence = 0.7;
  String _model = 'Balanced';
  bool _telemetry = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Scanning & OCR'),
          SwitchListTile(
            value: _enableAdvancedOCR,
            onChanged: (v) => setState(() => _enableAdvancedOCR = v),
            title: const Text('Enable advanced OCR'),
            subtitle: const Text('Use heuristics to improve ingredient parsing'),
          ),
          ListTile(
            title: const Text('Minimum OCR confidence'),
            subtitle: Text('${(_ocrConfidence * 100).toStringAsFixed(0)}%'),
          ),
          Slider(
            value: _ocrConfidence,
            onChanged: (v) => setState(() => _ocrConfidence = v),
            min: 0.5,
            max: 0.95,
            divisions: 9,
            label: '${(_ocrConfidence * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 12),
          const _SectionHeader('Risk Model'),
          DropdownButtonFormField<String>(
            value: _model,
            items: const [
              DropdownMenuItem(value: 'Fast', child: Text('Fast')),
              DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
              DropdownMenuItem(value: 'Thorough', child: Text('Thorough')),
            ],
            onChanged: (v) => setState(() => _model = v ?? _model),
            decoration: const InputDecoration(
              labelText: 'Model profile',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionHeader('Privacy & Telemetry'),
          SwitchListTile(
            value: _telemetry,
            onChanged: (v) => setState(() => _telemetry = v),
            title: const Text('Anonymous telemetry'),
            subtitle: const Text('Help improve accuracy with opt-in analytics'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: persist to backend when available
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}
