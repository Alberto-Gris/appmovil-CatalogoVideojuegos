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

class _GameStoreScreenState extends State<GameStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProviders>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      gameProvider.fetchGames(authProvider);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

                  // Actualizar el estado de favoritos después del logout
                  final gameProvider = Provider.of<GameProviders>(
                    context,
                    listen: false,
                  );
                  gameProvider.refreshFavoritesStatus(authProvider);

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
    return Consumer2<GameProviders, AuthProvider>(
      builder: (context, gameProvider, authProvider, child) {
        final cartGames = gameProvider.cartGames;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tienda de videojuegos'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.videogame_asset),
                  text: 'Todos los Juegos',
                ),
                Tab(
                  icon: const Icon(Icons.favorite),
                  text: 'Favoritos (${authProvider.favoritesCount})',
                ),
              ],
            ),
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
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
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
                tooltip: 'Agregar nuevo juego',
                child: const Icon(Icons.add),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 20,
                      ),
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
              // Contenido de las pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Pestaña de todos los juegos
                    _buildAllGamesTab(gameProvider, authProvider),
                    // Pestaña de favoritos
                    _buildFavoritesTab(gameProvider, authProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllGamesTab(
    GameProviders gameProvider,
    AuthProvider authProvider,
  ) {
    if (gameProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gameProvider.games.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videogame_asset_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay juegos disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final filteredGames = gameProvider.getFilteredGames(authProvider);

    return Column(
      children: [
        // Barra de búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar juegos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              gameProvider.setSearchQuery(value);
            },
          ),
        ),
        // Lista de juegos
        Expanded(
          child:
              filteredGames.isEmpty
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron juegos',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Intenta con otros términos de búsqueda',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: filteredGames.length,
                    itemBuilder: (context, index) {
                      final game = filteredGames[index];
                      return GameItem(game: game);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(
    GameProviders gameProvider,
    AuthProvider authProvider,
  ) {
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Inicia sesión para ver tus favoritos',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      );
    }

    final favoriteGames = gameProvider.getFavoriteGames(authProvider);

    if (favoriteGames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes juegos favoritos',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Agrega juegos a favoritos desde la pestaña principal',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header de favoritos con opciones
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(
                'Mis Favoritos (${favoriteGames.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (favoriteGames.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    _showClearFavoritesDialog(authProvider, gameProvider);
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
                ),
            ],
          ),
        ),
        // Lista de juegos favoritos
        Expanded(
          child: ListView.builder(
            itemCount: favoriteGames.length,
            itemBuilder: (context, index) {
              final game = favoriteGames[index];
              return GameItem(game: game);
            },
          ),
        ),
      ],
    );
  }

  void _showClearFavoritesDialog(
    AuthProvider authProvider,
    GameProviders gameProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Favoritos'),
          content: const Text(
            '¿Estás seguro de que quieres remover todos los juegos de tu lista de favoritos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final success = await authProvider.clearAllFavorites();

                if (success) {
                  // Actualizar el estado de favoritos en los juegos
                  gameProvider.refreshFavoritesStatus(authProvider);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Favoritos limpiados exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage ??
                              'Error al limpiar favoritos',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Limpiar'),
            ),
          ],
        );
      },
    );
  }
}
