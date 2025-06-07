import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:videogame_catalog/models/game_model.dart';

class GameProviders extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<GameModel> games = [];
  List<GameModel> cartGames = [];
  double totalCartPrice = 0.0;

  // Simplificado ya que todas las plataformas usan la misma URL
  static const String _baseUrl = 'https://684495cb71eb5d1be033aad0.mockapi.io';

  Future<void> fetchGames() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/games');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Corrección: La API devuelve directamente un array de games
        // no un objeto con propiedad 'games'
        if (data is Map<String, dynamic> && data.containsKey('games')) {
          games = List<GameModel>.from(
            data['games'].map((game) => GameModel.fromJSON(game)),
          );
        } else if (data is List) {
          // Si la API devuelve directamente un array
          games = List<GameModel>.from(
            data.map((game) => GameModel.fromJSON(game)),
          );
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Error al cargar los juegos: $e';
      games = [];
      if (kDebugMode) {
        print("Error in fetchGames: $e");
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Añadir un juego al carrito
  void addToCart(GameModel game) {
    final existingIndex = cartGames.indexWhere((g) => g.id == game.id);

    if (existingIndex >= 0) {
      // Verificar stock disponible antes de incrementar
      final currentQuantity = cartGames[existingIndex].quantity;
      if (currentQuantity < (game.unitsInStock ?? 0)) {
        cartGames[existingIndex].quantity += 1;
      } else {
        errorMessage = 'No hay suficiente stock disponible';
        notifyListeners();
        return;
      }
    } else {
      // Verificar stock antes de añadir
      if ((game.unitsInStock ?? 0) > 0) {
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
          mediaCarousel: game.mediaCarousel,
          unitsInStock: game.unitsInStock,
        );
        cartGames.add(gameToAdd);
      } else {
        errorMessage = 'Producto sin stock disponible';
        notifyListeners();
        return;
      }
    }
    
    _updateTotalPrice();
    errorMessage = null; // Limpiar mensaje de error si todo va bien
    notifyListeners();
  }

  // Remover un juego del carrito
  void removeFromCart(GameModel game) {
    final existingIndex = cartGames.indexWhere((g) => g.id == game.id);

    if (existingIndex >= 0) {
      if (cartGames[existingIndex].quantity > 1) {
        cartGames[existingIndex].quantity -= 1;
      } else {
        cartGames.removeAt(existingIndex);
      }
      
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
    totalCartPrice = cartGames.fold(0.0, (sum, game) => sum + (game.price * game.quantity));
  }

  // Verificar si un juego está en el carrito
  bool isInCart(GameModel game) {
    return cartGames.any((g) => g.id == game.id);
  }

  // Obtener la cantidad de un juego en el carrito
  int getQuantityInCart(GameModel game) {
    final index = cartGames.indexWhere((g) => g.id == game.id);
    return index >= 0 ? cartGames[index].quantity : 0;
  }

  // Obtener el número total de items en el carrito
  int get totalItemsInCart {
    return cartGames.fold(0, (sum, game) => sum + game.quantity);
  }

  // Verificar si hay stock suficiente para un juego
  bool hasStockAvailable(GameModel game) {
    final quantityInCart = getQuantityInCart(game);
    return (game.unitsInStock ?? 0) > quantityInCart;
  }

  // Añadir un nuevo juego al catálogo (para administradores)
  Future<bool> saveGame(GameModel game) async {
    try {
      final url = Uri.parse('$_baseUrl/games');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(game.toJSON()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si la API devuelve el juego creado, lo añadimos a la lista local
        games.add(game);
        notifyListeners();
        return true;
      } else {
        errorMessage = 'Error al guardar el juego: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error al conectar con el servidor: $e';
      if (kDebugMode) {
        print('Error saving game: $e');
      }
      return false;
    }
  }

  // Actualizar un juego existente
  Future<bool> updateGame(GameModel game) async {
    try {
      final url = Uri.parse('$_baseUrl/games/${game.id}');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(game.toJSON()),
      );

      if (response.statusCode == 200) {
        final index = games.indexWhere((g) => g.id == game.id);
        if (index >= 0) {
          games[index] = game;
          notifyListeners();
        }
        return true;
      } else {
        errorMessage = 'Error al actualizar el juego: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error al conectar con el servidor: $e';
      if (kDebugMode) {
        print('Error updating game: $e');
      }
      return false;
    }
  }

  // Eliminar un juego del catálogo
  Future<bool> deleteGame(String gameId) async {
    try {
      final url = Uri.parse('$_baseUrl/games/$gameId');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        games.removeWhere((g) => g.id == gameId);
        // También removerlo del carrito si está ahí
        cartGames.removeWhere((g) => g.id == gameId);
        _updateTotalPrice();
        notifyListeners();
        return true;
      } else {
        errorMessage = 'Error al eliminar el juego: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error al conectar con el servidor: $e';
      if (kDebugMode) {
        print('Error deleting game: $e');
      }
      return false;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // Simular compra (procesar carrito)
  Future<bool> processCheckout() async {
    if (cartGames.isEmpty) {
      errorMessage = 'El carrito está vacío';
      return false;
    }

    try {
      // Aquí implementarías la lógica de compra real
      // Por ahora solo simulamos el proceso
      await Future.delayed(const Duration(seconds: 2));
      
      // Limpiar el carrito después de una compra exitosa
      clearCart();
      return true;
    } catch (e) {
      errorMessage = 'Error al procesar la compra: $e';
      return false;
    }
  }
}