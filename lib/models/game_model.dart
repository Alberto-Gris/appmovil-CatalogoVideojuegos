
class GameModel {
  int id;
  String name;
  String developer;
  String imageLink;
  String description;
  List<String> platforms;
  String releaseDate;
  double price = 0.0;  // Añadido para la funcionalidad de carrito
  int quantity = 0;    // Añadido para la funcionalidad de carrito

  //constructor
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
  });

  factory GameModel.fromJSON(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'],
      name: json['name'],
      developer: json['developer'],
      imageLink: json['imageLink'],
      description: json['description'],
      platforms: List<String>.from(json['platforms']),
      releaseDate: json['releaseDate'],
      // Si la API proporciona precio, lo usamos, de lo contrario asignamos un precio predeterminado
      price: json['price'] != null ? json['price'].toDouble() : 59.99,
    );
  }

  // conversor a JSON
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
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return 'Game(id: $id, name: $name, developer: $developer, imageLink: $imageLink, description: $description, platforms: $platforms, releaseDate: $releaseDate, price: $price, quantity: $quantity)';
  }
}