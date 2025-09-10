// mobile/test/profile_service_error_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Use relative imports to match your project layout
import '../lib/src/services/profile_service.dart';
import '../lib/src/models/profile.dart';

Future<HttpServer> _fakeServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  // Handle requests in the background
  unawaited(() async {
    await for (final req in server) {
      if (req.method == 'PUT' && req.uri.path.startsWith('/profiles/')) {
        req.response.statusCode = 500;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'detail': 'boom'}));
        await req.response.close();
      } else {
        req.response.statusCode = 404;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({}));
        await req.response.close();
      }
    }
  }());

  return server;
}

void main() {
  test('ProfileService.update surfaces friendly error on 500', () async {
    // Start fake backend
    final server = await _fakeServer();
    addTearDown(() => server.close(force: true));
    ProfileService.baseUrl = 'http://127.0.0.1:${server.port}';

    // Minimal valid profile for your current model
    final p = Profile(
      id: 1,
      name: 'Kid',
      allergens: const [],
    );

    // Call the real service and expect the friendly error
    await expectLater(
      () => ProfileService.update(
        id: p.id,
        name: p.name,
        allergens: p.allergens,
        // dob/gender/state/country are optional in your service
      ),
      throwsA(predicate((e) => e.toString().contains('Update profile failed'))),
    );
  });
}
