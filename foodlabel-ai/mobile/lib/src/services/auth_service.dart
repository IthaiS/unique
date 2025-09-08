import "dart:io";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:path_provider/path_provider.dart";

class AuthService {
  static String baseUrl = const String.fromEnvironment("BACKEND_BASE_URL", defaultValue: "");
  static String? _token;
  static String? lastEmail;


  static String? get token => _token;
  static Future<File> _tokenFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/auth_token.json');
  }

  static Future<void> init() async {
    try {
      final f = await _tokenFile();
      if (await f.exists()) {
        final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _token = m["token"] as String?;
        lastEmail = m["email"] as String?;
      }
    } catch (_) {
      // ignore
    }
  }

  static Future<void> persistRememberChoice(bool remember) async {
    if (!remember || _token == null) return;
    try {
      final f = await _tokenFile();
      await f.writeAsString(jsonEncode({"token": _token, "email": lastEmail}));
    } catch (_) {}
  }

  static Future<void> logout() async {
    _token = null;
    try {
      final f = await _tokenFile();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }


  /// Public auth headers for cross-file usage
  static Map<String, String> authHeaders() => _token == null
      ? {"Content-Type": "application/json"}
      : {"Content-Type": "application/json", "Authorization": "Bearer $_token"};


  static Map<String, String> _authHeaders() =>
      _token == null ? {"Content-Type": "application/json"} :
      {"Content-Type": "application/json", "Authorization": "Bearer $_token"};

  static Future<void> register(String email, String password,
      {String? ownerName, String? state, String? country}) async {
    final resp = await http.post(Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "owner_name": ownerName,
        "state_province": state,
        "country": country
      }),
    );
    if (resp.statusCode ~/ 100 != 2) {
      throw Exception("Register failed: ${resp.statusCode} ${resp.body}");
    }
    final m = jsonDecode(resp.body);
    lastEmail = email;
    _token = m["access_token"] as String?;
}

  static Future<void> login(String email, String password, {bool rememberDevice = false}) async {
    final resp = await http.post(Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (resp.statusCode ~/ 100 != 2) {
      throw Exception("Login failed: ${resp.statusCode} ${resp.body}");
    }
    final m = jsonDecode(resp.body);
    lastEmail = email;
    _token = m["access_token"] as String?;
    if (rememberDevice) {
      await persistRememberChoice(true);
    }
  }
}
