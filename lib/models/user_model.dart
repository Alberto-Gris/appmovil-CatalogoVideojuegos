class UserModel {
  final String id;
  final String name;
  final String password;
  final List<String> favorites; // Nuevo campo para IDs de juegos favoritos

  UserModel({
    required this.id,
    required this.name,
    required this.password,
    this.favorites = const [], // Lista vacía por defecto
  });

  factory UserModel.fromJSON(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      favorites:
          json['favorites'] != null ? List<String>.from(json['favorites']) : [],
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'favorites': favorites,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? password,
    List<String>? favorites,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      favorites: favorites ?? this.favorites,
    );
  }

  // Métodos útiles para manejar favoritos
  bool isFavorite(String gameId) {
    return favorites.contains(gameId.toString());
  }

  UserModel addFavorite(String gameId) {
    if (!isFavorite(gameId)) {
      final newFavorites = List<String>.from(favorites)..add(gameId.toString());
      return copyWith(favorites: newFavorites);
    }
    return this;
  }

  UserModel removeFavorite(String gameId) {
    if (isFavorite(gameId)) {
      final newFavorites = List<String>.from(favorites)
        ..remove(gameId.toString());
      return copyWith(favorites: newFavorites);
    }
    return this;
  }

  UserModel toggleFavorite(String gameId) {
    return isFavorite(gameId) ? removeFavorite(gameId) : addFavorite(gameId);
  }

  int get favoritesCount => favorites.length;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, favoritesCount: ${favorites.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
