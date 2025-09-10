import "dart:convert";
import "package:http/http.dart" as http;
import "auth_service.dart";
import "../models/profile.dart";

class ProfileService {
  static String baseUrl =
      const String.fromEnvironment("BACKEND_BASE_URL", defaultValue: "");

  static Future<List<String>> allowedAllergens() async {
    final r = await http.get(Uri.parse("$baseUrl/meta/allowed-allergens"));
    if (r.statusCode ~/ 100 != 2) {
      throw Exception("Failed to fetch allowlist: ${r.statusCode}");
    }
    final m = jsonDecode(r.body);
    return (m["allergens"] as List<dynamic>).cast<String>();
  }

  static Future<List<Profile>> list() async {
    final r = await http.get(Uri.parse("$baseUrl/profiles"),
        headers: AuthService.authHeaders());
    if (r.statusCode ~/ 100 != 2) throw Exception("List profiles failed");
    final arr = jsonDecode(r.body) as List<dynamic>;
    return arr.map((e) => Profile.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Profile> create({
    required String name,
    String? dob,
    String? gender,
    String? state,
    String? country,
    required List<String> allergens,
  }) async {
    final r = await http.post(
      Uri.parse("$baseUrl/profiles"),
      headers: AuthService.authHeaders(),
      body: jsonEncode({
        "name": name,
        "date_of_birth": dob,
        "gender": gender,
        "state_province": state,
        "country": country,
        "allergens": allergens
      }),
    );
    if (r.statusCode ~/ 100 != 2)
      throw Exception("Create profile failed: ${r.statusCode} ${r.body}");
    return Profile.fromJson(jsonDecode(r.body));
  }

  static Future<Profile> update({
    required int id,
    required String name,
    String? dob,
    String? gender,
    String? state,
    String? country,
    required List<String> allergens,
  }) async {
    final r = await http.put(
      Uri.parse("$baseUrl/profiles/$id"),
      headers: AuthService.authHeaders(),
      body: jsonEncode({
        "name": name,
        "date_of_birth": dob,
        "gender": gender,
        "state_province": state,
        "country": country,
        "allergens": allergens
      }),
    );
    if (r.statusCode ~/ 100 != 2) throw Exception("Update profile failed");
    return Profile.fromJson(jsonDecode(r.body));
  }

  static Future<void> delete(int id) async {
    final r = await http.delete(Uri.parse("$baseUrl/profiles/$id"),
        headers: AuthService.authHeaders());
    if (r.statusCode ~/ 100 != 2) throw Exception("Delete failed");
  }
}
