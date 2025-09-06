import "dart:io" show Platform;
import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "../services/ocr_service.dart";
import "../services/assess_service.dart";
import "../services/i18n.dart";

class HomePage extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final Map<String, dynamic> translations;
  const HomePage(
      {super.key, required this.onLocaleChange, required this.translations});
  @override
  State<HomePage> createState() => _H();
}

class _H extends State<HomePage> {
  String? _raw;
  List<String> _ings = [];
  AssessResult? _res;
  bool _busy = false;
  Map<String, dynamic> _translations = {};

  @override
  void initState() {
    super.initState();
    // Load the translations you ship; adjust the list if needed
    I18n.loadTranslations(["en", "fr_BE", "nl_BE"]).then((m) {
      setState(() => _translations = m);
    });
  }

  String t(String key, {Map<String, String>? params}) {
    return I18n.t(_translations, Localizations.localeOf(context), key,
        params: params);
  }

  @override
  Widget build(BuildContext ctx) {
    String t(String k, {Map<String, String>? params}) =>
        I18n.t(widget.translations, Localizations.localeOf(ctx), k,
            params: params);
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final isWindows = !kIsWeb && Platform.isWindows;
    final isMac = !kIsWeb && Platform.isMacOS;
    return Scaffold(
      appBar: AppBar(title: Text(t("app.title")), actions: [
        PopupMenuButton<String>(
            onSelected: (v) {
              if (v == "en") widget.onLocaleChange(const Locale("en"));
              if (v == "nl") widget.onLocaleChange(const Locale("nl", "BE"));
              if (v == "fr") widget.onLocaleChange(const Locale("fr", "BE"));
            },
            itemBuilder: (c) => const [
                  PopupMenuItem(value: "en", child: Text("English")),
                  PopupMenuItem(value: "nl", child: Text("Nederlands (BE)")),
                  PopupMenuItem(value: "fr", child: Text("Français (BE)")),
                ])
      ]),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMobile
                ? t("hint.mobile_ocr")
                : (isWindows
                    ? t("hint.windows_cloud_ocr")
                    : (isMac
                        ? t("hint.macos_cloud_ocr")
                        : t("hint.desktop_cloud_ocr")))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: Text(t("action.scan_label")),
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              try {
                                final text =
                                    await OcrService.scanAndRecognizeText();
                                final toks =
                                    AssessService.extractIngredients(text);
                                final ret = await AssessService.assess(toks);
                                setState(() {
                                  _raw = text;
                                  _ings = toks;
                                  _res = ret;
                                });
                              } finally {
                                setState(() => _busy = false);
                              }
                            }))
            ]),
            const SizedBox(height: 16),
            if (_raw != null)
              Expanded(
                  child: ListView(children: [
                Text(t("label.recognized_text"),
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_raw!),
                const SizedBox(height: 16),
                Text(t("label.ingredients"),
                    style: Theme.of(ctx).textTheme.titleMedium),
                Wrap(
                    spacing: 8,
                    children: _ings.map((e) => Chip(label: Text(e))).toList()),
                const SizedBox(height: 16),
                if (_res != null)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t("label.assessment"),
                                    style: Theme.of(ctx).textTheme.titleMedium),
                                Text(t("assess.verdict.${_res!.verdict}")),
                                Text(t("assess.score",
                                    params: {"score": _res!.score.toString()})),
                                const SizedBox(height: 8),
                                ..._res!.reasons.map((r) {
                                  final code = r.code; // <-- field
                                  final param = r.param; // <-- field
                                  final text = I18n.t(
                                    _translations, // make sure you defined _translations in your State
                                    Localizations.localeOf(context),
                                    "reasons.$code",
                                    params: {"param": param},
                                  );
                                  return Text("• $text");
                                }),
                              ]))),
              ])),
          ])),
    );
  }
}
