import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:videogame_catalog/models/game_model.dart';
import 'auth_provider.dart';

class GameProviders extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<GameModel> games = [];
  List<GameModel> cartGames = [];
  double totalCartPrice = 0.0;

  // Filtros y búsqueda
  String _searchQuery = '';
  List<String> _selectedPlatforms = [];
  double _minPrice = 0.0;
  double _maxPrice = double.infinity;
  bool _onlyInStock = false;

  static const String _baseUrl = 'https://684495cb71eb5d1be033aad0.mockapi.io';

  // Getters para filtros
  String get searchQuery => _searchQuery;
  List<String> get selectedPlatforms => List.unmodifiable(_selectedPlatforms);
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  bool get onlyInStock => _onlyInStock;

  // Getter para juegos filtrados
  List<GameModel> get filteredGames {
    return games.where((game) {
      // Filtro por búsqueda de texto
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!game.name.toLowerCase().contains(query) &&
            !game.developer.toLowerCase().contains(query) &&
            !game.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtro por plataformas
      if (_selectedPlatforms.isNotEmpty) {
        bool hasMatchingPlatform = false;
        for (final platform in _selectedPlatforms) {
          if (game.platforms.any(
            (gamePlatform) =>
                gamePlatform.toLowerCase().contains(platform.toLowerCase()),
          )) {
            hasMatchingPlatform = true;
            break;
          }
        }
        if (!hasMatchingPlatform) return false;
      }

      // Filtro por precio
      if (game.price < _minPrice || game.price > _maxPrice) {
        return false;
      }

      // Filtro por stock
      if (_onlyInStock &&
          (game.unitsInStock == null || game.unitsInStock! <= 0)) {
        return false;
      }

      return true;
    }).toList();
  }

  // Obtener todas las plataformas disponibles
  List<String> get availablePlatforms {
    final platforms = <String>{};
    for (final game in games) {
      platforms.addAll(game.platforms);
    }
    return platforms.toList()..sort();
  }

  // Obtener rango de precios
  Map<String, double> get priceRange {
    if (games.isEmpty) return {'min': 0.0, 'max': 100.0};

    double min = games.first.price;
    double max = games.first.price;

    for (final game in games) {
      if (game.price < min) min = game.price;
      if (game.price > max) max = game.price;
    }

    return {'min': min, 'max': max};
  }

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

        if (data is Map<String, dynamic> && data.containsKey('games')) {
          games = List<GameModel>.from(
            data['games'].map((game) => GameModel.fromJSON(game)),
          );
        } else if (data is List) {
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

  // Métodos de filtrado
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void togglePlatformFilter(String platform) {
    if (_selectedPlatforms.contains(platform)) {
      _selectedPlatforms.remove(platform);
    } else {
      _selectedPlatforms.add(platform);
    }
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void setOnlyInStock(bool value) {
    _onlyInStock = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedPlatforms.clear();
    _minPrice = 0.0;
    _maxPrice = double.infinity;
    _onlyInStock = false;
    notifyListeners();
  }

  // Añadir un juego al carrito
  void addToCart(GameModel game) {
    final existingIndex = cartGames.indexWhere((g) => g.id == game.id);

    if (existingIndex >= 0) {
      final currentQuantity = cartGames[existingIndex].quantity;
      if (currentQuantity < (game.unitsInStock ?? 0)) {
        cartGames[existingIndex].quantity += 1;
      } else {
        errorMessage = 'No hay suficiente stock disponible';
        notifyListeners();
        return;
      }
    } else {
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
    errorMessage = null;
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
    totalCartPrice = cartGames.fold(
      0.0,
      (sum, game) => sum + (game.price * game.quantity),
    );
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
        // Añadir el juego a la lista local
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

          // También actualizar en el carrito si existe
          final cartIndex = cartGames.indexWhere((g) => g.id == game.id);
          if (cartIndex >= 0) {
            final currentQuantity = cartGames[cartIndex].quantity;
            cartGames[cartIndex] = game.copyWith(quantity: currentQuantity);
            _updateTotalPrice();
          }

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

  // Obtener un juego por ID
  GameModel? getGameById(String id) {
    try {
      return games.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener juegos relacionados (misma plataforma o desarrollador)
  List<GameModel> getRelatedGames(GameModel game, {int limit = 4}) {
    return games
        .where(
          (g) =>
              g.id != game.id &&
              (g.developer == game.developer ||
                  g.platforms.any(
                    (platform) => game.platforms.contains(platform),
                  )),
        )
        .take(limit)
        .toList();
  }

  // Obtener estadísticas del catálogo
  Map<String, dynamic> get catalogStats {
    if (games.isEmpty) {
      return {
        'totalGames': 0,
        'averagePrice': 0.0,
        'totalStock': 0,
        'outOfStockGames': 0,
        'topPlatforms': <String>[],
        'topDevelopers': <String>[],
      };
    }

    final totalStock = games.fold(
      0,
      (sum, game) => sum + (game.unitsInStock ?? 0),
    );
    final outOfStockGames =
        games.where((game) => (game.unitsInStock ?? 0) <= 0).length;
    final averagePrice =
        games.fold(0.0, (sum, game) => sum + game.price) / games.length;

    // Contar plataformas
    final platformCount = <String, int>{};
    for (final game in games) {
      for (final platform in game.platforms) {
        platformCount[platform] = (platformCount[platform] ?? 0) + 1;
      }
    }

    // Contar desarrolladores
    final developerCount = <String, int>{};
    for (final game in games) {
      developerCount[game.developer] =
          (developerCount[game.developer] ?? 0) + 1;
    }

    // Obtener top 5
    final topPlatforms =
        platformCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(5);

    final topDevelopers =
        developerCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(5);

    return {
      'totalGames': games.length,
      'averagePrice': averagePrice,
      'totalStock': totalStock,
      'outOfStockGames': outOfStockGames,
      'topPlatforms': topPlatforms.map((e) => e.key).toList(),
      'topDevelopers': topDevelopers.map((e) => e.key).toList(),
    };
  }

  // Limpiar mensaje de error
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // Simular compra (procesar carrito)
  Future<bool> processCheckout(AuthProvider authProvider) async {
    if (cartGames.isEmpty) {
      errorMessage = 'El carrito está vacío';
      return false;
    }

    // Verificar autenticación antes de procesar
    final authError = authProvider.validatePurchase();
    if (authError != null) {
      errorMessage = authError;
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      // Verificar stock disponible antes de procesar
      for (final cartGame in cartGames) {
        final currentGame = getGameById(cartGame.id);
        if (currentGame == null ||
            (currentGame.unitsInStock ?? 0) < cartGame.quantity) {
          errorMessage = 'Stock insuficiente para ${cartGame.name}';
          return false;
        }
      }

      // Simular procesamiento de pago
      await Future.delayed(const Duration(seconds: 2));

      // Actualizar stock de los juegos
      for (final cartGame in cartGames) {
        final gameIndex = games.indexWhere((g) => g.id == cartGame.id);
        if (gameIndex >= 0) {
          final currentStock = games[gameIndex].unitsInStock ?? 0;
          final newStock = currentStock - cartGame.quantity;

          // Crear nueva instancia con stock actualizado
          games[gameIndex] = games[gameIndex].copyWith(
            unitsInStock: newStock >= 0 ? newStock : 0,
          );

          // Actualizar en el servidor
          await updateGame(games[gameIndex]);
        }
      }

      // Opcional: Registrar la compra con el usuario
      if (kDebugMode) {
        print('Compra procesada para usuario: ${authProvider.currentUserName}');
        print('Total de la compra: \$${totalCartPrice.toStringAsFixed(2)}');
        print(
          'Juegos comprados: ${cartGames.map((g) => '${g.name} (x${g.quantity})').join(', ')}',
        );
      }

      clearCart();
      return true;
    } catch (e) {
      errorMessage = 'Error al procesar la compra: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool canAddToCart(AuthProvider authProvider) {
    return authProvider.isAuthenticated;
  }

  String getAddToCartMessage(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return 'Inicia sesión para agregar al carrito';
    }
    return 'Agregar al carrito';
  }

  // Actualizar stock de un juego específico
  Future<bool> updateGameStock(String gameId, int newStock) async {
    try {
      final gameIndex = games.indexWhere((g) => g.id == gameId);
      if (gameIndex >= 0) {
        games[gameIndex] = games[gameIndex].copyWith(unitsInStock: newStock);
        return await updateGame(games[gameIndex]);
      }
      return false;
    } catch (e) {
      errorMessage = 'Error al actualizar stock: $e';
      return false;
    }
  }
}
