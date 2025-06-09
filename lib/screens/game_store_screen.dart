import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/providers/auth_provider.dart';
import 'package:videogame_catalog/widgets/game_item.dart';
import 'package:videogame_catalog/screens/cart_screen.dart';
import 'package:videogame_catalog/screens/add_game_screen.dart';
import 'package:videogame_catalog/screens/login_screen.dart';

class GameStoreScreen extends StatefulWidget {
  const GameStoreScreen({super.key});

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

  void _showProfileMenu() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('Usuario: ${authProvider.currentUserName}'),
                subtitle: Text('ID: ${authProvider.currentUserId}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  authProvider.logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesión cerrada exitosamente'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProviders>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartGames = gameProvider.cartGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de videojuegos'),
        actions: [
          // Botón de login/perfil
          authProvider.isAuthenticated
              ? IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Perfil de ${authProvider.currentUserName}',
                onPressed: _showProfileMenu,
              )
              : IconButton(
                icon: const Icon(Icons.login),
                tooltip: 'Iniciar Sesión',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
          // Botón del carrito
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                MaterialPageRoute(builder: (context) => const AddGameScreen()),
              );
            },
            backgroundColor: Theme.of(context).primaryColor,
            tooltip: 'Agregar nuevo juego',
            child: const Icon(Icons.add),
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .startFloat, // Establecemos la posición a la izquierda
      body: Column(
        children: [
          // Banner de estado de usuario
          if (authProvider.isAuthenticated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green[50],
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '¡Bienvenido, ${authProvider.currentUserName}!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // Contenido principal
          Expanded(
            child:
                gameProvider.isLoading
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
          ),
        ],
      ),
    );
  }
}
