class UserModel {
  final String id;
  final String name;
  final String password;

  UserModel({required this.id, required this.name, required this.password});

  factory UserModel.fromJSON(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJSON() {
    return {'id': id, 'name': name, 'password': password};
  }

  UserModel copyWith({String? id, String? name, String? password}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
