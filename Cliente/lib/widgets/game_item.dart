import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/models/game_model.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/providers/auth_provider.dart';
import 'package:videogame_catalog/screens/game_detail_screen.dart';
import 'package:videogame_catalog/screens/login_screen.dart';

class GameItem extends StatelessWidget {
  final GameModel game;

  const GameItem({super.key, required this.game});

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Iniciar Sesión Requerido'),
          content: const Text(
            'Necesitas iniciar sesión para agregar juegos al carrito y realizar compras.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Iniciar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _handleAddToCart(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProviders>(context, listen: false);

    // Verificar si el usuario puede comprar
    final validationError = authProvider.validatePurchase();
    if (validationError != null) {
      _showLoginDialog(context);
      return;
    }

    // Intentar agregar al carrito
    gameProvider.addToCart(game);

    // Verificar si hubo algún error después de intentar agregar
    if (gameProvider.errorMessage != null) {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.errorMessage!),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Solo mostrar mensaje de éxito si no hubo errores
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${game.name} agregado al carrito'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleRemoveFromCart(BuildContext context) {
    final gameProvider = Provider.of<GameProviders>(context, listen: false);
    gameProvider.removeFromCart(game);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${game.name} removido del carrito'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleToggleFavorite(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProviders>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      _showLoginDialog(context);
      return;
    }

    final gameId = game.id.toString();

    // Alternar favorito
    final success = await authProvider.toggleFavorite(gameId);

    if (success) {
      // Actualizar el estado local del juego
      final isFavorite = authProvider.isGameFavorite(gameId);
      gameProvider.updateGameFavoriteStatus(gameId, isFavorite);

      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? '${game.name} agregado a favoritos'
                : '${game.name} removido de favoritos',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: isFavorite ? Colors.red : Colors.grey,
        ),
      );
    } else {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Error al actualizar favoritos',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProviders, AuthProvider>(
      builder: (context, gameProvider, authProvider, child) {
        final inCart = gameProvider.isInCart(game);
        final quantity = gameProvider.getQuantityInCart(game);
        final canPurchase = authProvider.canPurchase;
        final isFavorite = authProvider.isGameFavorite(game.id.toString());
        final isLoadingFavorite = authProvider.isLoading;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameDetailScreen(game: game),
              ),
            );
          },
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del juego con botón de favorito
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Hero(
                        tag: 'game-image-${game.id}',
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(game.imageLink),
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Overlay si no puede comprar
                          child:
                              !canPurchase
                                  ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                    ),

                    // Botón de favorito en la esquina superior derecha
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon:
                              isLoadingFavorite
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        isFavorite ? Colors.red : Colors.white,
                                    size: 24,
                                  ),
                          onPressed:
                              isLoadingFavorite
                                  ? null
                                  : () => _handleToggleFavorite(context),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título del juego con indicador de favorito
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              game.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isFavorite && authProvider.isAuthenticated)
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 16,
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Desarrollador
                      Text(
                        'Desarrollado por: ${game.developer}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Fecha de lanzamiento
                      Text(
                        'Lanzamiento: ${game.releaseDate}',
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 6),

                      // Plataformas
                      Row(
                        children: [
                          const Text(
                            'Plataformas: ',
                            style: TextStyle(fontSize: 14),
                          ),
                          Expanded(
                            child: Text(
                              game.platforms.join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Precio y botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${game.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                          // Botones de carrito y favorito
                          Row(
                            children: [
                              // Botón de favorito (solo si está autenticado)
                              if (authProvider.isAuthenticated)
                                IconButton(
                                  icon:
                                      isLoadingFavorite
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Icon(
                                            isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                isFavorite
                                                    ? Colors.red
                                                    : Colors.grey,
                                          ),
                                  onPressed:
                                      isLoadingFavorite
                                          ? null
                                          : () =>
                                              _handleToggleFavorite(context),
                                ),

                              const SizedBox(width: 8),

                              // Botones de carrito
                              canPurchase
                                  ? Row(
                                    children: [
                                      if (inCart)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed:
                                                  () => _handleRemoveFromCart(
                                                    context,
                                                  ),
                                            ),
                                            Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      IconButton(
                                        icon: Icon(
                                          inCart
                                              ? Icons.add
                                              : Icons.shopping_cart,
                                          color: Colors.blue,
                                        ),
                                        onPressed:
                                            () => _handleAddToCart(context),
                                      ),
                                    ],
                                  )
                                  : ElevatedButton.icon(
                                    onPressed: () => _showLoginDialog(context),
                                    icon: const Icon(Icons.login, size: 16),
                                    label: const Text('Iniciar Sesión'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontSize: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),

                      // Mensaje informativo si no puede comprar
                      if (!canPurchase)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Inicia sesión para comprar y agregar favoritos',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
