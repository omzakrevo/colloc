import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Lit /version.json (écrit par la CI à chaque déploiement, jamais mis en cache).
Future<String?> fetchLatestVersion() async {
  try {
    final r = await web.window
        .fetch('version.json?t=${DateTime.now().millisecondsSinceEpoch}'.toJS)
        .toDart;
    if (!r.ok) return null;
    final body = (await r.text().toDart).toDart;
    return (jsonDecode(body) as Map)['colloc_version'] as String?;
  } catch (_) {
    return null;
  }
}

void reloadApp() => web.window.location.reload();
