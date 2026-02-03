class Profile {
  final String id;
  final String role;
  final String? fullName;

  Profile({required this.id, required this.role, this.fullName});

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      role: map['role'],
      fullName: map['full_name'],
    );
  }
}
