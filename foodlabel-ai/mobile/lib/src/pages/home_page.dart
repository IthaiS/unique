import 'package:flutter/material.dart';
import '../services/ocr_service.dart';
import '../services/assess_service.dart';
import '../services/i18n.dart';

class HomePage extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final Map<String, dynamic> translations;
  const HomePage({super.key, required this.onLocaleChange, required this.translations});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _rawText;
  List<String> _ingredients = [];
  AssessResult? _result;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = (String k, {Map<String, String>? params}) =>
        I18n.t(widget.translations, Localizations.localeOf(context), k, params: params);
    return Scaffold(
      appBar: AppBar(
        title: Text(t('app.title')),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v=='en') widget.onLocaleChange(const Locale('en'));
              if (v=='nl') widget.onLocaleChange(const Locale('nl','BE'));
              if (v=='fr') widget.onLocaleChange(const Locale('fr','BE'));
            },
            itemBuilder: (c) => [
              const PopupMenuItem(value:'en', child: Text('English')),
              const PopupMenuItem(value:'nl', child: Text('Nederlands (BE)')),
              const PopupMenuItem(value:'fr', child: Text('Français (BE)')),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(t('action.scan_label')),
                  onPressed: _busy ? null : () async {
                    setState(()=>_busy=true);
                    try{
                      final text = await OcrService.scanAndRecognizeText();
                      final tokens = AssessService.extractIngredients(text);
                      final res = await AssessService.assess(tokens);
                      setState((){ _rawText=text; _ingredients=tokens; _result=res; });
                    } finally { setState(()=>_busy=false); }
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
            if (_rawText!=null) Expanded(child: ListView(
              children: [
                Text(t('label.recognized_text'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_rawText!),
                const SizedBox(height: 16),
                Text(t('label.ingredients'), style: Theme.of(context).textTheme.titleMedium),
                Wrap(spacing: 8, children: _ingredients.map((e)=>Chip(label: Text(e))).toList()),
                const SizedBox(height: 16),
                if (_result!=null) Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('label.assessment'), style: Theme.of(context).textTheme.titleMedium),
                        Text(t('assess.verdict.${_result!.verdict}')),
                        Text(t('assess.score', params: {'score': _result!.score.toString()})),
                        const SizedBox(height: 8),
                        ..._result!.reasons.map((r)=>Text("• ${t('reason.${r['code']}', params: {'param': r['param']??''})}"))
                      ],
                    ),
                  ),
                )
              ],
            )),
          ],
        ),
      ),
    );
  }
}
