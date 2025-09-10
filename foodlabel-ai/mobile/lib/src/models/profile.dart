class Profile {
  final int id;
  final String name;
  final String? gender;
  final String? state;
  final String? country;
  final String? dob; // YYYY-MM-DD
  final List<String> allergens;

  Profile({
    required this.id,
    required this.name,
    this.gender,
    this.state,
    this.country,
    this.dob,
    required this.allergens,
  });

  factory Profile.fromJson(Map<String, dynamic> m) => Profile(
        id: m["id"] as int,
        name: m["name"] as String,
        gender: m["gender"] as String?,
        state: m["state_province"] as String?,
        country: m["country"] as String?,
        dob: m["date_of_birth"] as String?,
        allergens: (m["allergens"] as List<dynamic>).cast<String>(),
      );
}