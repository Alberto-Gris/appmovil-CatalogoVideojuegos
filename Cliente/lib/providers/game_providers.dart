import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:videogame_catalog/models/game_model.dart';

class GameProviders extends ChangeNotifier {
  bool isLoading = false;

  List<GameModel> games = [];
  List<GameModel> cartGames = []; // Carrito en lugar de favoritos
  double totalCartPrice = 0.0;   // Total del carrito

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:12345';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:12345';
    } else if (Platform.isIOS) {
      return 'http://localhost:12345';
    } else {
      return 'http://localhost:12345';
    }
  }

  Future<void> fetchGames() async {
    isLoading = true;
    notifyListeners();

    final url = Uri.parse('${getBaseUrl()}/games');

    print("Fetch Games");
    try {
      print("Trying");

      final response = await http.get(url);

      print("response status ${response.statusCode}");
      print("respuesta ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        games = List<GameModel>.from(
          data['games'].map((game) => GameModel.fromJSON(game)),
        );
      } else {
        games = [];
      }
    } catch (e) {
      print("Error in request $e");
      games = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Añadir un juego al carrito
  void addToCart(GameModel game) {
    // Verificar si el juego ya está en el carrito
    final existingIndex = cartGames.indexWhere((g) => g.id == game.id);

    if (existingIndex >= 0) {
      // Si ya está en el carrito, incrementamos la cantidad
      cartGames[existingIndex].quantity += 1;
    } else {
      // Si no está en el carrito, lo añadimos con cantidad 1
      final gameToAdd = GameModel(
        id: game.id,
        name: game.name,
        developer: game.developer,
        imageLink: game.imageLink,
        description: game.description,
        platforms: game.platforms,
        releaseDate: game.releaseDate,
        price: game.price,
        quantity: 1,
      );
      cartGames.add(gameToAdd);
    }
    
    // Actualizar el precio total del carrito
    _updateTotalPrice();
    notifyListeners();
  }

  // Remover un juego del carrito
  void removeFromCart(GameModel game) {
    final existingIndex = cartGames.indexWhere((g) => g.id == game.id);

    if (existingIndex >= 0) {
      if (cartGames[existingIndex].quantity > 1) {
        // Si hay más de 1, reducimos la cantidad
        cartGames[existingIndex].quantity -= 1;
      } else {
        // Si solo hay 1, lo removemos del carrito
        cartGames.removeAt(existingIndex);
      }
      
      // Actualizar el precio total del carrito
      _updateTotalPrice();
      notifyListeners();
    }
  }

  // Eliminar completamente un juego del carrito
  void removeGameCompletely(GameModel game) {
    cartGames.removeWhere((g) => g.id == game.id);
    _updateTotalPrice();
    notifyListeners();
  }

  // Vaciar completamente el carrito
  void clearCart() {
    cartGames.clear();
    totalCartPrice = 0.0;
    notifyListeners();
  }

  // Actualizar el precio total del carrito
  void _updateTotalPrice() {
    totalCartPrice = 0.0;
    for (var game in cartGames) {
      totalCartPrice += (game.price * game.quantity);
    }
  }

  // Verificar si un juego está en el carrito
  bool isInCart(GameModel game) {
    return cartGames.any((g) => g.id == game.id);
  }

  // Obtener la cantidad de un juego en el carrito
  int getQuantityInCart(GameModel game) {
    final index = cartGames.indexWhere((g) => g.id == game.id);
    if (index >= 0) {
      return cartGames[index].quantity;
    }
    return 0;
  }

  // Añadir un nuevo juego al catálogo (para administradores)
  Future<bool> saveGame(GameModel game) async {
    try {
      print('Save: games length: ${games.length}');
      games.add(game);
      print('games length: ${games.length}');

      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }
}