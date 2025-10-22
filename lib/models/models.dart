class UserModel {
  final String id;
  final String name;
  final String? photoUrl;

  UserModel({required this.id, required this.name, this.photoUrl});

  factory UserModel.fromMap(Map<String, dynamic> m) {
    return UserModel(
      id: m['id'].toString(),
      name: (m['name'] as String?) ?? '',
      photoUrl: m['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'photo_url': photoUrl,
  };
}
