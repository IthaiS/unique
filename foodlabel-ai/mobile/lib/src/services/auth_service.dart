import "dart:convert";
import "package:http/http.dart" as http;

class AuthService {
  static String baseUrl = const String.fromEnvironment("BACKEND_BASE_URL", defaultValue: "");
  static String? _token;

  static String? get token => _token;

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
    _token = m["access_token"] as String?;
  }

  static Future<void> login(String email, String password) async {
    final resp = await http.post(Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (resp.statusCode ~/ 100 != 2) {
      throw Exception("Login failed: ${resp.statusCode} ${resp.body}");
    }
    final m = jsonDecode(resp.body);
    _token = m["access_token"] as String?;
  }
}
