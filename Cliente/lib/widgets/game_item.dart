import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/models/game_model.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/screens/game_detail_screen.dart';

class GameItem extends StatelessWidget {
  final GameModel game;

  const GameItem({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProviders>(context);
    final inCart = gameProvider.isInCart(game);
    final quantity = gameProvider.getQuantityInCart(game);

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
            // Imagen del juego
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
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del juego
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Plataformas
                  Row(
                    children: [
                      const Text(
                        'Plataformas: ',
                        style: TextStyle(
                          fontSize: 14,
                        ),
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
                  
                  // Precio y botón de carrito
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
                      
                      // Botones de carrito
                      Row(
                        children: [
                          if (inCart)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    gameProvider.removeFromCart(game);
                                  },
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          IconButton(
                            icon: Icon(
                              inCart ? Icons.add : Icons.shopping_cart,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              gameProvider.addToCart(game);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}