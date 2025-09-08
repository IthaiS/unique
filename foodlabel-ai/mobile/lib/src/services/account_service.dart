
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OwnerAccount {
  final String email;
  final String? ownerName;
  final String? state;
  final String? country;

  OwnerAccount({
    required this.email,
    this.ownerName,
    this.state,
    this.country,
  });

  factory OwnerAccount.fromJson(Map<String, dynamic> m) => OwnerAccount(
        email: (m['email'] ?? m['username'] ?? m['user'] ?? '').toString(),
        ownerName: (m['ownerName'] ?? m['name'] ?? m['owner_name'])?.toString(),
        state: (m['state'] ?? m['region'] ?? m['stateProvince'] ?? m['state_province'])?.toString(),
        country: m['country']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        if (ownerName != null) 'ownerName': ownerName,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
      };
}

String? _decodeJwtEmail(String? jwt) {
  if (jwt == null || jwt.isEmpty) return null;
  final parts = jwt.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final m = jsonDecode(payload) as Map<String, dynamic>;
    return (m['email'] ?? m['sub'] ?? '').toString();
  } catch (_) {
    return null;
  }
}

class AccountService {
  static Future<File> _cacheFile() async {
    final dir = Directory('${Directory.systemTemp.path}/foodlabel_ai');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/owner_account.json');
  }

  static Future<OwnerAccount?> _readCache() async {
    try {
      final f = await _cacheFile();
      if (!await f.exists()) return null;
      final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return OwnerAccount.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(OwnerAccount a) async {
    try {
      final f = await _cacheFile();
      await f.writeAsString(jsonEncode(a.toJson()));
    } catch (_) {}
  }

  static Future<void> clearLocalCache() async {
    try {
      final f = await _cacheFile();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// GET current owner account. Merge server response with cache for fields the server omits.
  static Future<OwnerAccount> me() async {
    Future<http.Response> _get(String path) => http.get(
          Uri.parse("${AuthService.baseUrl}$path"),
          headers: AuthService.authHeaders(),
        );

    OwnerAccount? cached = await _readCache();
    try {
      http.Response r = await _get("/auth/me");
      if (r.statusCode == 404 || r.statusCode == 405) {
        r = await _get("/account/me");
      }
      if (r.statusCode ~/ 100 == 2) {
        final serverMap = r.body.isNotEmpty
            ? jsonDecode(r.body) as Map<String, dynamic>
            : <String, dynamic>{};
        final email = (serverMap['email'] ?? _decodeJwtEmail(AuthService.token) ?? AuthService.lastEmail ?? '').toString();
        final merged = OwnerAccount(
          email: email,
          ownerName: (serverMap['ownerName'] ?? serverMap['name'] ?? serverMap['owner_name'])?.toString() ?? cached?.ownerName,
          state: (serverMap['state'] ?? serverMap['region'] ?? serverMap['stateProvince'] ?? serverMap['state_province'])?.toString() ?? cached?.state,
          country: (serverMap['country'])?.toString() ?? cached?.country,
        );
        await _writeCache(merged);
        return merged;
      }
    } catch (_) {
      // ignore and fall back
    }
    if (cached != null) return cached;
    final email = _decodeJwtEmail(AuthService.token) ?? AuthService.lastEmail ?? '';
    return OwnerAccount(email: email);
  }

  /// UPDATE owner. Send both legacy and new field names so backend accepts them.
  static Future<OwnerAccount> update({
    String? ownerName,
    String? state,
    String? country,
  }) async {
    final Map<String, dynamic> body = {};
    if (ownerName != null) {
      body['ownerName'] = ownerName;
      body['name'] = ownerName; // legacy/alternate
      body['owner_name'] = ownerName; // alternate
    }
    if (state != null) {
      body['state'] = state;
      body['region'] = state; // alternate
      body['stateProvince'] = state; // alternate
      body['state_province'] = state; // alternate
    }
    if (country != null) {
      body['country'] = country;
    }
    final payload = jsonEncode(body);

    Future<http.Response> _put(String path) => http.put(
          Uri.parse("${AuthService.baseUrl}$path"),
          headers: AuthService.authHeaders(),
          body: payload,
        );

    http.Response r = await _put("/auth/me");
    if (r.statusCode == 404 || r.statusCode == 405) {
      r = await _put("/account/me");
    }

    if (r.statusCode == 204) {
      // Merge with cache + submitted values
      final cached = await _readCache();
      final email = cached?.email ?? _decodeJwtEmail(AuthService.token) ?? AuthService.lastEmail ?? "";
      final merged = OwnerAccount(
        email: email,
        ownerName: ownerName ?? cached?.ownerName,
        state: state ?? cached?.state,
        country: country ?? cached?.country,
      );
      await _writeCache(merged);
      return merged;
    }

    if (r.statusCode ~/ 100 != 2) {
      if (r.statusCode == 404 || r.statusCode == 405) {
        // Persist locally so UI stays correct even if server doesn't handle fields.
        final email = _decodeJwtEmail(AuthService.token) ?? AuthService.lastEmail ?? "";
        final local = OwnerAccount(email: email, ownerName: ownerName, state: state, country: country);
        await _writeCache(local);
        return local;
      }
      throw Exception("Failed to update account: ${r.statusCode} ${r.body}");
    }

    // 200 with JSON body; merge with submitted fields in case server omits some keys
    final m = r.body.isNotEmpty ? jsonDecode(r.body) as Map<String, dynamic> : <String, dynamic>{};
    final email = (m['email'] ?? _decodeJwtEmail(AuthService.token) ?? AuthService.lastEmail ?? '').toString();
    final merged = OwnerAccount(
      email: email,
      ownerName: (m['ownerName'] ?? m['name'] ?? m['owner_name'])?.toString() ?? ownerName,
      state: (m['state'] ?? m['region'] ?? m['stateProvince'] ?? m['state_province'])?.toString() ?? state,
      country: (m['country'])?.toString() ?? country,
    );
    await _writeCache(merged);
    return merged;
  }
}
