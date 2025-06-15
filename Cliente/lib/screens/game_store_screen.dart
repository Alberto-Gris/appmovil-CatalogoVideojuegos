import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  // Variables de estado para la identificación
  File? _selectedImage;
  bool _isIdentifying = false;
  Map<String, dynamic>? _gameInfo;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
                Tab(
                  icon: const Icon(Icons.camera_alt),
                  text: 'Identificación',
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
                    // Pestaña de Identificación de juegos
                    _buildIdentificarTab(gameProvider, authProvider),
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

  Widget _buildIdentificarTab(
    GameProviders gameProvider,
    AuthProvider authProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child:
                _selectedImage != null
                    ? GestureDetector(
                      onTap: () => _showImageDialog(_selectedImage!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selecciona una imagen del juego',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
          ),
          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isIdentifying
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isIdentifying
                          ? null
                          : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botones de identificar y limpiar
          if (_selectedImage != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isIdentifying ? null : _identifyGame,
                icon:
                    _isIdentifying
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.search),
                label: Text(
                  _isIdentifying ? 'Identificando...' : 'Identificar Juego',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Botón de limpiar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isIdentifying ? null : _clearAll,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar y Elegir Nueva Foto'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Resultado detallado
          if (_gameInfo != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: _buildGameInfoCard(_gameInfo!),
              ),
            ),
          ],

          // Error message
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageDialog(File imageFile) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Imagen en pantalla completa
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile, fit: BoxFit.contain),
                  ),
                ),
              ),
              // Botón de cerrar
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              // Indicador de zoom (opcional)
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Pellizca para hacer zoom',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameInfoCard(Map<String, dynamic> gameInfo) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del juego
            Row(
              children: [
                Icon(
                  Icons.videogame_asset,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gameInfo['game_title'] ?? 'No identificado',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información básica
            _buildInfoRow('Confianza', gameInfo['confidence'] ?? 'N/A'),
            _buildInfoRow('Género', gameInfo['genre'] ?? 'N/A'),
            _buildInfoRow('Plataforma', gameInfo['platform'] ?? 'N/A'),
            _buildInfoRow('Año', gameInfo['year']?.toString() ?? 'N/A'),

            const SizedBox(height: 16),

            // Descripción
            if (gameInfo['description'] != null) ...[
              const Text(
                'Descripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(gameInfo['description']),
              const SizedBox(height: 16),
            ],

            // Personajes
            if (gameInfo['characters'] != null &&
                gameInfo['characters'].isNotEmpty) ...[
              const Text(
                'Personajes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                children:
                    (gameInfo['characters'] as List)
                        .map((char) => Chip(label: Text(char.toString())))
                        .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Elementos de UI
            if (gameInfo['ui_elements'] != null &&
                gameInfo['ui_elements'].isNotEmpty) ...[
              const Text(
                'Elementos de UI:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                children:
                    (gameInfo['ui_elements'] as List)
                        .map(
                          (ui) => Chip(
                            label: Text(ui.toString()),
                            backgroundColor: Colors.blue[100],
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Nuevos métodos
  void _clearAll() {
    setState(() {
      _selectedImage = null;
      _gameInfo = null;
      _errorMessage = null;
      _isIdentifying = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker
          .pickImage(
            source: source,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          )
          .timeout(const Duration(seconds: 30));

      if (image != null) {
        // Verificar el archivo antes de usarlo
        final file = File(image.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            setState(() {
              _errorMessage = 'La imagen es demasiado grande (máximo 10MB)';
            });
            return;
          }

          setState(() {
            _selectedImage = file;
            _gameInfo = null;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = 'Error: el archivo de imagen no es válido';
          });
        }
      }
    } on TimeoutException catch (e) {
      setState(() {
        _errorMessage = 'Tiempo de espera agotado al seleccionar imagen';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al seleccionar imagen: ${e.toString()}';
      });
    }
  }

  Future<void> _identifyGame() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Por favor selecciona una imagen primero';
      });
      return;
    }

    setState(() {
      _isIdentifying = true;
      _gameInfo = null;
      _errorMessage = null;
    });

    try {
      // Verificar si el archivo existe
      if (!await _selectedImage!.exists()) {
        throw Exception('El archivo de imagen no existe');
      }

      // Verificar el tamaño del archivo (máximo 10MB)
      final fileSize = await _selectedImage!.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('La imagen es demasiado grande (máximo 10MB)');
      }

      final result = await GameIdentificationService.identifyGame(
        _selectedImage!,
      );

      if (mounted) {
        setState(() {
          _gameInfo = result;
          _isIdentifying = false;
        });
      }
    } on SocketException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Sin conexión a internet. Verifica tu conexión y vuelve a intentar.';
          _isIdentifying = false;
        });
      }
    } on HttpException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error del servidor. Inténtalo de nuevo más tarde.';
          _isIdentifying = false;
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error procesando la respuesta del servidor.';
          _isIdentifying = false;
        });
      }
    } on FileSystemException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error leyendo el archivo de imagen. Selecciona otra imagen.';
          _isIdentifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo identificar el juego. ${e.toString()}';
          _isIdentifying = false;
        });
      }
    }
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

class GameIdentificationService {
  static const String _geminiApiKey = 'AIzaSyDOoqvSd-CgUJ3M9skba6gPcV3Qbks1p5o';
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // Método principal para identificar juegos con reintentos
  static Future<Map<String, dynamic>> identifyGame(File imageFile) async {
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        // Validar el archivo
        await _validateImageFile(imageFile);

        // Convertir imagen a base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Identificar con Gemini
        return await _identifyWithGemini(base64Image);
      } on SocketException catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          throw Exception(
            'Sin conexión a internet después de $_maxRetries intentos',
          );
        }
        // Esperar antes del siguiente intento
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on HttpException catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          throw Exception(
            'Error del servidor después de $_maxRetries intentos',
          );
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on FileSystemException catch (e) {
        throw Exception('Error leyendo el archivo: ${e.message}');
      } on FormatException catch (e) {
        throw Exception('Formato de imagen no válido');
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          throw Exception('Error procesando imagen: $e');
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }

    throw Exception('Máximo número de reintentos alcanzado');
  }

  // Validar archivo de imagen
  static Future<void> _validateImageFile(File imageFile) async {
    try {
      // Verificar si existe
      if (!await imageFile.exists()) {
        throw FileSystemException('El archivo no existe', imageFile.path);
      }

      // Verificar tamaño
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw FileSystemException('El archivo está vacío', imageFile.path);
      }

      if (fileSize > 10 * 1024 * 1024) {
        // 10MB
        throw FileSystemException(
          'Archivo demasiado grande (máximo 10MB)',
          imageFile.path,
        );
      }

      // Verificar extensión
      final extension = imageFile.path.toLowerCase().split('.').last;
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
      if (!validExtensions.contains(extension)) {
        throw FormatException('Formato de imagen no soportado: $extension');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Implementación mejorada con Google Gemini Vision
  static Future<Map<String, dynamic>> _identifyWithGemini(
    String base64Image,
  ) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
      );

      final prompt = '''
Analiza esta imagen de videojuego y proporciona la siguiente información en formato JSON válido:

{
  "game_title": "Nombre exacto del juego",
  "confidence": "Nivel de confianza (alto/medio/bajo)",
  "genre": "Género del juego",
  "platform": "Plataforma probable",
  "year": "Año aproximado de lanzamiento",
  "description": "Breve descripción de lo que ves en la imagen",
  "characters": ["Lista de personajes visibles"],
  "ui_elements": ["Elementos de interfaz visibles"],
  "scene_description": "Descripción de la escena"
}

IMPORTANTE: Responde SOLO con el JSON válido, sin texto adicional.
Si no puedes identificar el juego, usa "game_title": "No identificado".
''';

      final body = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
        "generationConfig": {"temperature": 0.1, "maxOutputTokens": 1000},
      };

      // Hacer petición con timeout
      final client = http.Client();
      try {
        final response = await client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
            .timeout(_timeoutDuration);

        return await _processGeminiResponse(response);
      } on TimeoutException catch (e) {
        throw Exception('Tiempo de espera agotado. Inténtalo de nuevo.');
      } finally {
        client.close();
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado en Gemini: $e');
      }
    }
  }

  // Procesar respuesta de Gemini
  static Future<Map<String, dynamic>> _processGeminiResponse(
    http.Response response,
  ) async {
    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verificar estructura de respuesta
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }

        final candidate = data['candidates'][0];
        if (candidate['content'] == null ||
            candidate['content']['parts'] == null) {
          throw Exception('Formato de respuesta inválido');
        }

        final text = candidate['content']['parts'][0]['text'];
        if (text == null || text.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }

        // Extraer y validar JSON
        return _extractAndValidateJson(text);
      } else if (response.statusCode == 400) {
        throw HttpException('Solicitud inválida - Verifica la imagen');
      } else if (response.statusCode == 401) {
        throw HttpException('Error de autenticación - API Key inválida');
      } else if (response.statusCode == 403) {
        throw HttpException('Acceso denegado - Cuota excedida');
      } else if (response.statusCode == 429) {
        throw HttpException('Demasiadas solicitudes - Inténtalo más tarde');
      } else if (response.statusCode >= 500) {
        throw HttpException('Error del servidor - Inténtalo más tarde');
      } else {
        throw HttpException('Error HTTP: ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw FormatException('Error decodificando respuesta JSON');
    } catch (e) {
      rethrow;
    }
  }

  // Extraer y validar JSON de la respuesta
  static Map<String, dynamic> _extractAndValidateJson(String text) {
    try {
      // Intentar extraer JSON del texto
      String jsonText = text.trim();

      // Buscar JSON entre llaves
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(jsonText);
      if (jsonMatch != null) {
        jsonText = jsonMatch.group(0)!;
      }

      // Parsear JSON
      final result = json.decode(jsonText) as Map<String, dynamic>;

      // Validar campos requeridos
      return _validateGameInfo(result);
    } on FormatException catch (e) {
      // Si falla el parsing, crear respuesta por defecto
      return {
        'game_title': 'Error parseando respuesta',
        'confidence': 'bajo',
        'genre': 'Desconocido',
        'platform': 'Desconocida',
        'description': 'No se pudo procesar la respuesta del servidor: $text',
        'characters': <String>[],
        'ui_elements': <String>[],
      };
    }
  }

  // Validar información del juego
  static Map<String, dynamic> _validateGameInfo(Map<String, dynamic> info) {
    return {
      'game_title': info['game_title']?.toString() ?? 'No identificado',
      'confidence': info['confidence']?.toString() ?? 'bajo',
      'genre': info['genre']?.toString() ?? 'Desconocido',
      'platform': info['platform']?.toString() ?? 'Desconocida',
      'year': _parseYear(info['year']),
      'description': info['description']?.toString() ?? 'Sin descripción',
      'characters': _parseList(info['characters']),
      'ui_elements': _parseList(info['ui_elements']),
      'scene_description': info['scene_description']?.toString() ?? '',
    };
  }

  // Parsear año de forma segura
  static int? _parseYear(dynamic year) {
    if (year == null) return null;
    if (year is int) return year;
    if (year is String) {
      return int.tryParse(year.replaceAll(RegExp(r'[^\d]'), ''));
    }
    return null;
  }

  // Parsear listas de forma segura
  static List<String> _parseList(dynamic list) {
    if (list == null) return <String>[];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return <String>[];
  }
}
