import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/widgets/game_item.dart';
import 'package:videogame_catalog/screens/cart_screen.dart';
import 'package:videogame_catalog/screens/add_game_screen.dart';
import 'package:videogame_catalog/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
                Tab(icon: const Icon(Icons.camera_alt), text: 'Identificación'),
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

    return RefreshIndicator(
      onRefresh: () async {
        await gameProvider.fetchGames(authProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lista de juegos actualizada'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Column(
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
      ),
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

    return RefreshIndicator(
      onRefresh: () async {
        await gameProvider.fetchGames(authProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favoritos actualizados'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child:
          favoriteGames.isEmpty
              ? const Center(
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
              )
              : Column(
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
                              _showClearFavoritesDialog(
                                authProvider,
                                gameProvider,
                              );
                            },
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Limpiar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Lista de juegos favoritos
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: favoriteGames.length,
                      itemBuilder: (context, index) {
                        final game = favoriteGames[index];
                        return GameItem(game: game);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildIdentificarTab(
    GameProviders gameProvider,
    AuthProvider authProvider,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Limpiar todo al hacer pull-to-refresh
        _clearAll();

        // Simular un pequeño delay para dar feedback visual
        await Future.delayed(const Duration(milliseconds: 500));

        // Mostrar mensaje de confirmación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Identificador reiniciado'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Importante: physics para permitir el scroll incluso cuando el contenido no llena la pantalla
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Forzar altura mínima igual al viewport disponible
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instrucciones de uso con pull-to-refresh
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Desliza hacia abajo para reiniciar el identificador',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenedor de imagen
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
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
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
                                  const SizedBox(height: 8),
                                  Text(
                                    'O desliza hacia abajo para reiniciar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.search),
                          label: Text(
                            _isIdentifying
                                ? 'Identificando...'
                                : 'Identificar Juego',
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
                    if (_gameInfo != null) ...[_buildGameInfoCard(_gameInfo!)],

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Espacio adicional al final para mejor UX
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
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
        ],
      ),
    );
  }
}

class GameIdentificationService {
  // Configuración de producción eliminada

  static String get _geminiApiKey {
    // Siempre usar clave Gemini, no usar backend proxy
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  static const int _maxRetries = 2;
  static const Duration _timeoutDuration = Duration(seconds: 25);

  /// Método principal para identificar juegos
  static Future<Map<String, dynamic>> identifyGame(File imageFile) async {
    try {
      // Validar imagen
      await _validateImageFile(imageFile);

      // Procesar imagen
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (_geminiApiKey.isNotEmpty) {
        return await _identifyWithGemini(base64Image);
      } else {
        throw Exception(
          'Servicio no configurado correctamente: falta GEMINI_API_KEY',
        );
      }
    } catch (e) {
      _logError('identifyGame', e);
      rethrow;
    }
  }

  /// Validación exhaustiva de archivos de imagen
  static Future<void> _validateImageFile(File imageFile) async {
    try {
      // Verificar existencia
      if (!await imageFile.exists()) {
        throw FileSystemException('Archivo no encontrado', imageFile.path);
      }

      // Verificar tamaño
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw FileSystemException('Archivo vacío', imageFile.path);
      }

      // Límite más conservador para producción
      const maxSize = kReleaseMode ? 5 * 1024 * 1024 : 10 * 1024 * 1024;
      if (fileSize > maxSize) {
        final maxMB = (maxSize / (1024 * 1024)).round();
        throw FileSystemException('Imagen muy grande (máximo ${maxMB}MB)');
      }

      // Verificar formato por bytes
      final bytes = await imageFile.readAsBytes();
      if (!_isValidImageFormat(bytes)) {
        throw FormatException('Formato de imagen no válido o corrupto');
      }

      // Verificar dimensiones básicas
      if (!_hasValidDimensions(bytes)) {
        throw FormatException('Dimensiones de imagen no válidas');
      }
    } catch (e) {
      if (e is FileSystemException || e is FormatException) {
        rethrow;
      }
      throw FileSystemException('Error validando imagen: $e');
    }
  }

  /// Verificar formato de imagen por firma de bytes
  static bool _isValidImageFormat(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return true;
    }

    // GIF87a o GIF89a
    if (bytes.length >= 6) {
      final header = String.fromCharCodes(bytes.take(6));
      if (header == 'GIF87a' || header == 'GIF89a') {
        return true;
      }
    }

    // WebP: RIFF + WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    return false;
  }

  /// Verificar dimensiones básicas
  static bool _hasValidDimensions(Uint8List bytes) {
    try {
      // Para PNG, verificar dimensiones en el header
      if (bytes.length >= 24 && bytes[0] == 0x89 && bytes[1] == 0x50) {
        final width =
            (bytes[16] << 24) |
            (bytes[17] << 16) |
            (bytes[18] << 8) |
            bytes[19];
        final height =
            (bytes[20] << 24) |
            (bytes[21] << 16) |
            (bytes[22] << 8) |
            bytes[23];

        return width > 0 && height > 0 && width <= 4096 && height <= 4096;
      }

      // Para otros formatos, asumir válido (validación básica)
      return true;
    } catch (e) {
      return true; // En caso de error, permitir continuar
    }
  }

  /// Implementación con Gemini (DESARROLLO)
  static Future<Map<String, dynamic>> _identifyWithGemini(
    String base64Image,
  ) async {
    if (_geminiApiKey.isEmpty) {
      throw Exception('API Key de Gemini no configurada');
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
      );

      final prompt = '''
Analiza esta imagen de videojuego y proporciona información en formato JSON válido:

{
  "game_title": "Nombre exacto del juego",
  "confidence": "alto/medio/bajo",
  "genre": "Género principal",
  "platform": "Plataforma más probable",
  "year": 2024,
  "description": "Descripción de la escena",
  "characters": ["personaje1", "personaje2"],
  "ui_elements": ["elemento1", "elemento2"],
  "scene_description": "Descripción detallada",
  "developer": "Desarrollador si es reconocible",
  "series": "Serie o franquicia si aplica"
}

Instrucciones:
- Responde SOLO con JSON válido
- Si no identificas el juego: "game_title": "No identificado"
- Sé específico con nombres de juegos conocidos
- Confidence "alto" solo si estás muy seguro
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
        "generationConfig": {
          "temperature": 0.1,
          "maxOutputTokens": 1500,
          "topP": 0.8,
          "topK": 40,
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
        ],
      };

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
      } finally {
        client.close();
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error con Gemini API: $e');
    }
  }

  static Future<Map<String, dynamic>> _processGeminiResponse(
    http.Response response,
  ) async {
    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }

        final candidate = data['candidates'][0];
        if (candidate['content']?['parts'] == null) {
          throw Exception('Formato de respuesta inválido');
        }

        final text = candidate['content']['parts'][0]['text'];
        if (text == null || text.isEmpty) {
          throw Exception('Respuesta vacía');
        }

        return _extractAndValidateJson(text);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['error']?['message'] ?? 'Error desconocido';

        switch (response.statusCode) {
          case 400:
            throw Exception('Solicitud inválida: $errorMessage');
          case 401:
            throw Exception('API Key inválida');
          case 403:
            throw Exception('Cuota de API excedida');
          case 429:
            throw Exception('Demasiadas solicitudes. Intenta más tarde.');
          default:
            throw HttpException('Error Gemini: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw FormatException('Error procesando respuesta');
    }
  }

  /// Procesamiento y validación de respuestas
  static Map<String, dynamic> _extractAndValidateJson(String text) {
    try {
      String jsonText = text.trim();

      // Extraer JSON del texto
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonText);
      if (jsonMatch != null) {
        jsonText = jsonMatch.group(0)!;
      }

      // Limpiar texto problemático
      jsonText = jsonText.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

      final result = json.decode(jsonText) as Map<String, dynamic>;
      return _validateGameInfo(result);
    } on FormatException catch (e) {
      return {
        'game_title': 'Error procesando respuesta',
        'confidence': 'bajo',
        'genre': 'Desconocido',
        'platform': 'Desconocida',
        'description': 'No se pudo procesar la respuesta del servidor',
        'characters': <String>[],
        'ui_elements': <String>[],
        'error': 'JSON inválido',
      };
    }
  }

  static Map<String, dynamic> _validateGameInfo(Map<String, dynamic> info) {
    return {
      'game_title': _validateString(info['game_title']) ?? 'No identificado',
      'confidence': _validateConfidence(info['confidence']),
      'genre': _validateString(info['genre']) ?? 'Desconocido',
      'platform': _validateString(info['platform']) ?? 'Desconocida',
      'year': _parseYear(info['year']),
      'description': _validateString(info['description']) ?? 'Sin descripción',
      'characters': _parseStringList(info['characters']),
      'ui_elements': _parseStringList(info['ui_elements']),
      'scene_description': _validateString(info['scene_description']) ?? '',
      'developer': _validateString(info['developer']) ?? '',
      'series': _validateString(info['series']) ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static String? _validateString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static String _validateConfidence(dynamic confidence) {
    final conf = confidence?.toString().toLowerCase() ?? 'bajo';
    const validConfidences = ['alto', 'medio', 'bajo'];
    return validConfidences.contains(conf) ? conf : 'bajo';
  }

  static int? _parseYear(dynamic year) {
    if (year == null) return null;
    if (year is int) {
      return (year >= 1970 && year <= DateTime.now().year + 2) ? year : null;
    }
    if (year is String) {
      final parsed = int.tryParse(year.replaceAll(RegExp(r'[^\d]'), ''));
      return (parsed != null &&
              parsed >= 1970 &&
              parsed <= DateTime.now().year + 2)
          ? parsed
          : null;
    }
    return null;
  }

  static List<String> _parseStringList(dynamic list) {
    if (list == null) return <String>[];
    if (list is List) {
      return list
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .take(10) // Límite de elementos
          .toList();
    }
    return <String>[];
  }

  /// Logging y monitoreo
  static void _logError(String method, dynamic error) {
    final timestamp = DateTime.now().toIso8601String();

    if (kReleaseMode) {
      // En producción, enviar a servicio de monitoreo
      // Firebase Crashlytics, Sentry, etc.
      print(
        '[$timestamp] GameIdentificationService.$method: ${error.runtimeType}',
      );
    } else {
      // En desarrollo, log completo
      print('[$timestamp] GameIdentificationService.$method: $error');
    }
  }

  /// Verificar si el servicio está disponible
  static bool get isAvailable {
    return (!kReleaseMode && _geminiApiKey.isNotEmpty);
  }
}
