class Profile {
  final String id;
  final String role;
  final bool isDriver;
  final String? fullName;

  Profile({
    required this.id,
    required this.role,
    this.isDriver = false,
    this.fullName,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      role: map['role'],
      isDriver: map['is_driver'] ?? false,
      fullName: map['full_name'],
    );
  }
}
