import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/widgets/game_item.dart';
import 'package:videogame_catalog/screens/cart_screen.dart';
import 'package:videogame_catalog/screens/add_game_screen.dart';

class GameStoreScreen extends StatefulWidget {
  const GameStoreScreen({Key? key}) : super(key: key);

  @override
  State<GameStoreScreen> createState() => _GameStoreScreenState();
}

class _GameStoreScreenState extends State<GameStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProviders>(context, listen: false).fetchGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProviders>(context);
    final cartGames = gameProvider.cartGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de videojuegos'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              if (cartGames.isNotEmpty)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      // Sumamos todas las cantidades
                      '${cartGames.fold(0, (sum, game) => sum + game.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      // Añadimos el botón flotante para agregar juegos
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 10), // Margen a la izquierda 
        child: Align(
          alignment: Alignment.bottomLeft, // Alineamos a la izquierda
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddGameScreen(),
                ),
              );
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add),
            tooltip: 'Agregar nuevo juego',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Establecemos la posición a la izquierda
      body: gameProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : gameProvider.games.isEmpty
              ? const Center(child: Text('No hay juegos disponibles'))
              : ListView.builder(
                  itemCount: gameProvider.games.length,
                  itemBuilder: (context, index) {
                    final game = gameProvider.games[index];
                    return GameItem(game: game);
                  },
                ),
    );
  }
}