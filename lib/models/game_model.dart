class MediaCarouselItem {
  final String type; // "image" o "video"
  final String url;
  final String? thumbnail; // Para videos
  final String alt;

  MediaCarouselItem({
    required this.type,
    required this.url,
    this.thumbnail,
    required this.alt,
  });

  factory MediaCarouselItem.fromJSON(Map<String, dynamic> json) {
    return MediaCarouselItem(
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      alt: json['alt'] ?? '',
    );
  }

  Map<String, dynamic> toJSON() {
    final json = {'type': type, 'url': url, 'alt': alt};
    if (thumbnail != null) {
      json['thumbnail'] = thumbnail!;
    }
    return json;
  }
}

class GameModel {
  dynamic id;
  String name;
  String developer;
  String imageLink;
  String description;
  List<String> platforms;
  String releaseDate;
  double price;
  int quantity; // Para el carrito
  int? unitsInStock; // Stock disponible
  List<MediaCarouselItem> mediaCarousel;
  bool isFavorite; // Nuevo campo para indicar si es favorito

  GameModel({
    required this.id,
    required this.name,
    required this.developer,
    required this.imageLink,
    required this.description,
    required this.platforms,
    required this.releaseDate,
    this.price = 0.0,
    this.quantity = 0,
    this.unitsInStock,
    this.mediaCarousel = const [],
    this.isFavorite = false, // Por defecto no es favorito
  });

  factory GameModel.fromJSON(Map<String, dynamic> json) {
    // Manejo seguro de mediaCarousel
    List<MediaCarouselItem> carousel = [];
    if (json['mediaCarousel'] != null) {
      if (json['mediaCarousel'] is List) {
        carousel =
            (json['mediaCarousel'] as List)
                .map(
                  (item) => MediaCarouselItem.fromJSON(
                    item is Map<String, dynamic> ? item : {},
                  ),
                )
                .toList();
      }
    }

    return GameModel(
      id: json['id'],
      name: json['name'] ?? '',
      developer: json['developer'] ?? '',
      imageLink: json['imageLink'] ?? '',
      description: json['description'] ?? '',
      platforms:
          json['platforms'] != null ? List<String>.from(json['platforms']) : [],
      releaseDate: json['releaseDate'] ?? '',
      price: _parsePrice(json['price']),
      quantity: json['quantity'] ?? 0,
      unitsInStock: json['unitsInStock'],
      mediaCarousel: carousel,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Factory constructor para crear un juego marcado como favorito
  factory GameModel.fromJSONWithFavoriteStatus(
    Map<String, dynamic> json,
    bool isFavorite,
  ) {
    final game = GameModel.fromJSON(json);
    return game.copyWith(isFavorite: isFavorite);
  }

  // Helper method para parsear el precio de forma segura
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'developer': developer,
      'imageLink': imageLink,
      'description': description,
      'platforms': platforms,
      'releaseDate': releaseDate,
      'price': price,
      if (unitsInStock != null) 'unitsInStock': unitsInStock,
      'mediaCarousel': mediaCarousel.map((item) => item.toJSON()).toList(),
      'isFavorite': isFavorite,
    };
  }

  // Crear una copia del objeto con algunos campos modificados
  GameModel copyWith({
    dynamic id,
    String? name,
    String? developer,
    String? imageLink,
    String? description,
    List<String>? platforms,
    String? releaseDate,
    double? price,
    int? quantity,
    int? unitsInStock,
    List<MediaCarouselItem>? mediaCarousel,
    bool? isFavorite,
  }) {
    return GameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      developer: developer ?? this.developer,
      imageLink: imageLink ?? this.imageLink,
      description: description ?? this.description,
      platforms: platforms ?? this.platforms,
      releaseDate: releaseDate ?? this.releaseDate,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unitsInStock: unitsInStock ?? this.unitsInStock,
      mediaCarousel: mediaCarousel ?? this.mediaCarousel,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Método para cambiar el estado de favorito
  GameModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  // Método para marcar como favorito
  GameModel markAsFavorite() {
    return copyWith(isFavorite: true);
  }

  // Método para desmarcar como favorito
  GameModel unmarkAsFavorite() {
    return copyWith(isFavorite: false);
  }

  @override
  String toString() {
    return 'GameModel(id: $id, name: $name, developer: $developer, price: $price, stock: $unitsInStock, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
